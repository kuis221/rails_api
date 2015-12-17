# == Schema Information
#
# Table name: invite_individuals
#
#  id                               :integer          not null, primary key
#  invite_id                        :integer
#  registrant_id                    :integer
#  date_added                       :date
#  email                            :string(255)
#  mobile_phone                     :string(255)
#  mobile_signup                    :boolean
#  first_name                       :string(255)
#  last_name                        :string(255)
#  attended_previous_bartender_ball :string(255)
#  opt_in_to_future_communication   :boolean
#  primary_registrant_id            :integer
#  bartender_how_long               :string(255)
#  bartender_role                   :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  date_of_birth                    :string(255)
#  zip_code                         :string(255)
#  created_by_id                    :integer
#  updated_by_id                    :integer
#  attended                         :boolean
#  rsvpd                            :boolean          default("false")
#  active                           :boolean          default("true")
#  age                              :integer
#  address_line_1                   :string
#  address_line_2                   :string
#  city                             :string
#  province_code                    :string
#  country_code                     :string
#  phone_number                     :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invite_individual do
    invite nil
    registrant_id 1
    date_added '2015-01-06'
    email 'rsvp@email.com'
    mobile_phone '123456789'
    mobile_signup false
    first_name 'Fulano'
    last_name 'de Tal'
    attended_previous_bartender_ball 'no'
    opt_in_to_future_communication false
    primary_registrant_id 1
    bartender_how_long '2 years'
    bartender_role 'Main'
    date_of_birth '3/2/1977'
    zip_code '90210'
  end
end
