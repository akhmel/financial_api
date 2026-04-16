FactoryBot.define do
  factory :transaction do
    user
    amount { 100 }
    kind { :deposit }
    idempotency_key { SecureRandom.uuid }

    trait :withdraw do
      kind { :withdraw }
    end

    trait :transfer do
      kind { :transfer }
      recipient { association :user }
    end
  end
end
