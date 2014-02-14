# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default("")
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country                :string(4)
#  state                  :string(255)
#  city                   :string(255)
#  created_by_id          :integer
#  updated_by_id          :integer
#  invitation_token       :string(255)
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  current_company_id     :integer
#  time_zone              :string(255)
#  detected_time_zone     :string(255)
#  phone_number           :string(255)
#  street_address         :string(255)
#  unit_number            :string(255)
#  zip_code               :string(255)
#  authentication_token   :string(255)
#  invitation_created_at  :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name 'Test'
    last_name 'User'
    sequence(:email) {|n| "testuser#{n}@brandscopic.com" }
    phone_number '(506) 22124578'
    password 'Changeme123'
    password_confirmation 'Changeme123'
    city 'Curridabat'
    state 'SJ'
    country 'CR'
    street_address 'Street Address 123'
    unit_number 'Unit Number 456'
    zip_code '90210'
    time_zone Brandscopic::Application.config.time_zone
    detected_time_zone Brandscopic::Application.config.time_zone
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
      first_name 'Test Invited'
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
