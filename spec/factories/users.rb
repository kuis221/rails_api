# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name 'Test'
    last_name 'User'
    sequence(:email) {|n| "testuser#{n}@brandscopic.com" }
    phone_number '(506)22124578'
    password 'Changeme123'
    password_confirmation 'Changeme123'
    city 'Curridabat'
    state 'SJ'
    country 'CR'
    street_address 'Street Address 123'
    unit_number 'Unit Number 456'
    zip_code '90210'
    time_zone Brandscopic::Application.config.time_zone
    detected_time_zone 'Central America'
    confirmed_at DateTime.now
    invitation_accepted_at DateTime.now
    invitation_token nil

    ignore do
      role_id nil
      active true
      company_id nil
      company nil
    end

    before(:create) do |user, evaluator|
      company_id = evaluator.company_id
      company_id = evaluator.company.id unless evaluator.company.nil?
      role_id = evaluator.role_id
      role_id ||= FactoryGirl.create(:role, company_id: company_id).id unless company_id.nil? || role_id.present?
      if company_id and role_id
        user.company_users.build({role_id: role_id, company_id: company_id, active: evaluator.active}, without_protection: true)
      end
    end

    factory :invited_user do
      sequence(:invitation_token) {|n| "#{n}EmMBowassEf#{n}GSHyBhEnX#{n}" }
      association :invited_by, factory: :user
      password nil
      password_confirmation nil
      invitation_sent_at DateTime.now
      invitation_accepted_at nil
      phone_number nil
      city nil
      state nil
      country nil
      street_address nil
      unit_number nil
      zip_code nil
      inviting_user true
    end

  end
end
