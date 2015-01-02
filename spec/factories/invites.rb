# == Schema Information
#
# Table name: invites
#
#  id                               :integer          not null, primary key
#  invitable_id                     :integer
#  invitable_type                   :string(255)
#  venue_id                         :integer
#  invitees                         :integer
#  rsvps                            :integer
#  attendees                        :integer
#  final_date                       :date
#  event_date                       :date
#  registrant_id                    :integer
#  date_added                       :date
#  email                            :string(255)
#  mobile_phone                     :string(255)
#  mobile_signup                    :boolean
#  first_name                       :string(255)
#  last_name                        :string(255)
#  attended_previous_bartender_ball :boolean
#  opt_in_to_future_communication   :boolean
#  primary_registrant_id            :integer
#  bartender_how_long               :string(255)
#  bartender_role                   :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invite do
    invitable nil
    venue nil
    invitees 1
    rsvps 1
    attendees 1
    final_date "2014-12-30"
    event_date "2014-12-30"
    registrant_id 1
    date_added "2014-12-30"
    email "MyString"
    mobile_phone "MyString"
    mobile_signup false
    first_name "MyString"
    last_name "MyString"
    attended_previous_bartender_ball false
    opt_in_to_future_communication false
    primary_registrant_id 1
    bartender_how_long "MyString"
    bartender_role "MyString"
  end
end
