# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name 'Test'
    last_name 'User'
    sequence(:email) {|n| "testuser#{n}@brandscopic.com" }
    password 'Changeme123'
    password_confirmation 'Changeme123'
    city 'Curridabat'
    state 'SJ'
    country 'CR'
    confirmed_at DateTime.now

    ignore do
      role_id 1
      active true
      company_id nil
    end

    before(:create) do |user, evaluator|
      if evaluator.company_id and evaluator.role_id
        user.company_users.build({role_id: evaluator.role_id, company_id: evaluator.company_id, active: evaluator.active}, without_protection: true)
      end
    end

    factory :unconfirmed_user do
      confirmed_at nil
    end

  end
end
