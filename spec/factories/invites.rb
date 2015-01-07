# == Schema Information
#
# Table name: invites
#
#  id          :integer          not null, primary key
#  event_id    :integer
#  venue_id    :integer
#  market      :string(255)
#  invitees    :integer          default(0)
#  rsvps_count :integer          default(0)
#  attendees   :integer          default(0)
#  final_date  :date
#  event_date  :date
#  created_at  :datetime
#  updated_at  :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invite do
    event nil
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
