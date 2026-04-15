FactoryBot.define do
  factory :transaction do
    user
    amount { 100 }
    kind { :deposit }
    idempotency_key { nil }

    trait :withdraw do
      kind { :withdraw }
    end

    trait :transfer do
      kind { :transfer }
      recipient { association :user }
    end

    trait :with_idempotency_key do
      idempotency_key { SecureRandom.uuid }
    end
  end
end
