class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :recipient, class_name: "User", optional: true

  enum :kind, { deposit: 0, withdraw: 1, transfer: 2 }

  monetize :amount_cents, numericality: { greater_than: 0 }
  validates :kind, presence: true
  validates :idempotency_key, presence: true, uniqueness: true
end
