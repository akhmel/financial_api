FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "correct-horse-battery-staple" }
    balance { 0 }

    trait :with_balance do
      balance { 1000 }
    end
  end
end
