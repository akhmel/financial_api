class User < ApplicationRecord
  include Monetizable

  has_secure_password

  has_many :transactions, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, length: { minimum: 12 }, if: :password_digest_changed?

  monetize :balance_cents, numericality: { greater_than_or_equal_to: 0 }
  money_as_decimal :balance

  before_save :downcase_email

  def sufficient_funds?(amount)
    balance >= amount
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
