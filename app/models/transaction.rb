class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :recipient, class_name: "User", optional: true

  enum :kind, { deposit: 0, withdraw: 1, transfer: 2 }

  validates :amount, numericality: { greater_than: 0 }
  validates :kind, presence: true
  validates :idempotency_key, uniqueness: true, allow_nil: true
end
