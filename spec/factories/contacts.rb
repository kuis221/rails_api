# == Schema Information
#
# Table name: contacts
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  first_name    :string(255)
#  last_name     :string(255)
#  title         :string(255)
#  email         :string(255)
#  phone_number  :string(255)
#  street1       :string(255)
#  street2       :string(255)
#  country       :string(255)
#  state         :string(255)
#  city          :string(255)
#  zip_code      :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :integer
#  updated_by_id :integer
#  company_name  :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    company_id 1
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    company_name { Faker::Company.name }
    title { Faker::Name.title }
    email { Faker::Internet.email }
    phone_number '344-23333'
    street1 { Faker::Address.street_address }
    street2 ''
    country 'US'
    state { Faker::Address.state_abbr }
    city { Faker::Address.city }
    zip_code { Faker::Address.zip_code }
  end
end
