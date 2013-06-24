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
    invitation_accepted_at DateTime.now

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
      city nil
      state nil
      country nil
      inviting_user true
    end

  end
end
