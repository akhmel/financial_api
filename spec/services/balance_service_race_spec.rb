require "rails_helper"

RSpec.describe "BalanceService.transfer race conditions" do
  self.use_transactional_tests = false

  after do
    Transaction.delete_all
    User.delete_all
  end

  def transfer_async(barrier, sender_id:, recipient_email:, amount:)
    Thread.new do
      barrier.wait
      BalanceService.transfer(
        sender_id: sender_id,
        recipient_email: recipient_email,
        amount: amount,
        idempotency_key: SecureRandom.uuid
      )
      :success
    rescue InsufficientFundsError, ActiveRecord::SerializationFailure
      :rejected
    ensure
      ActiveRecord::Base.connection_pool.release_connection
    end
  end

  def join_or_fail!(threads, timeout: 15)
    threads.each { |t| t.join(timeout) }

    hung = threads.select(&:alive?)
    if hung.any?
      hung.each(&:kill)
      raise "Thread(s) timed out — possible deadlock"
    end
  end

  describe "double-spend prevention" do
    it "allows only one transfer when balance covers a single full transfer" do
      sender = create(:user, balance: 500)
      recipient_a = create(:user, balance: 0)
      recipient_b = create(:user, balance: 0)

      barrier = Concurrent::CyclicBarrier.new(2)
      threads = [
        transfer_async(barrier, sender_id: sender.id, recipient_email: recipient_a.email, amount: "50000"),
        transfer_async(barrier, sender_id: sender.id, recipient_email: recipient_b.email, amount: "50000")
      ]
      join_or_fail!(threads)

      results = threads.map(&:value)
      expect(results.count(:success)).to eq(1)
      expect(results.count(:rejected)).to eq(1)
      expect(User.sum(:balance_cents)).to eq(50_000)
    end
  end

  describe "deadlock prevention via sorted locking" do
    it "completes opposite transfers (A→B and B→A) without deadlock" do
      alice = create(:user, balance: 1000)
      bob = create(:user, balance: 1000)

      barrier = Concurrent::CyclicBarrier.new(2)
      threads = [
        transfer_async(barrier, sender_id: alice.id, recipient_email: bob.email, amount: "10000"),
        transfer_async(barrier, sender_id: bob.id, recipient_email: alice.email, amount: "15000")
      ]
      join_or_fail!(threads)

      results = threads.map(&:value)
      expect(results).to include(:success)
      expect(User.sum(:balance_cents)).to eq(200_000)
    end
  end

  describe "balance conservation under concurrency" do
    it "preserves total balance across concurrent transfers" do
      users = Array.new(4) { |i| create(:user, email: "race#{i}@test.com", balance: 1000) }
      initial_total = User.sum(:balance_cents)

      barrier = Concurrent::CyclicBarrier.new(4)
      pairs = [[0, 1], [1, 2], [2, 3], [3, 0]]
      threads = pairs.map do |(s, r)|
        transfer_async(
          barrier,
          sender_id: users[s].id,
          recipient_email: users[r].email,
          amount: "5000"
        )
      end
      join_or_fail!(threads)

      results = threads.map(&:value)
      expect(results.count(:success)).to be >= 1
      expect(User.sum(:balance_cents)).to eq(initial_total)
    end
  end

  describe "idempotency under concurrency" do
    it "processes only one transfer when the same idempotency key is submitted concurrently" do
      sender = create(:user, balance: 1000)
      recipient = create(:user, balance: 0)
      shared_key = SecureRandom.uuid

      barrier = Concurrent::CyclicBarrier.new(2)
      threads = 2.times.map do
        Thread.new do
          barrier.wait
          BalanceService.transfer(
            sender_id: sender.id,
            recipient_email: recipient.email,
            amount: "10000",
            idempotency_key: shared_key
          )
          :success
        rescue DuplicateRequestError, ActiveRecord::RecordNotUnique, ActiveRecord::SerializationFailure
          :rejected
        ensure
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
      join_or_fail!(threads)

      results = threads.map(&:value)
      expect(results.count(:success)).to eq(1)
      expect(results.count(:rejected)).to eq(1)
      expect(Transaction.where(idempotency_key: shared_key).count).to eq(1)
      expect(sender.reload.balance_cents).to eq(90_000)
      expect(recipient.reload.balance_cents).to eq(10_000)
    end
  end
end
