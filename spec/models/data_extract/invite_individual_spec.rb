# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

require 'rails_helper'

RSpec.describe DataExtract::InviteIndividual, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        ['campaign_name', 'Event Campaign Name'], ['end_date', 'Event End Date'],
        ['end_time', 'Event End Time'], ['start_date', 'Event Start Date'],
        ['start_time', 'Event Start Time'], ['event_status', 'Event Status'],
        ['place_name', 'Event Venue Name'], ['place_street', 'Event Venue Street'],
        ['place_city', 'Event Venue City'], ['place_state', 'Event Venue State'],
        ['place_zipcode', 'Event Venue Zip Code'], ['rsvpd', "RSVP'd?"],
        ['attended', 'Attended?'], ['first_name', 'First Name'],
        ['last_name', 'Last Name'], ['email', 'Email'], ["mobile_phone", "Mobile phone"],
        ["mobile_signup", "Mobile signup"],
        ["attended_previous_bartender_ball", "Attended previous bartender ball?"],
        ["opt_in_to_future_communication", "Opt in to future communication?"],
        ["primary_registrant_id", "Primary registrant ID"],
        ["bartender_how_long", "Bartender how long?"], ["date_of_birth", "Date of Birth"],
        ["zip_code", "ZIP code"], ['created_at', 'Created At'],
        ['created_by', 'Created By'], ['modified_at', 'Modified At'],
        ['modified_by', 'Modified By'], ["active_state", "Active State"]])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:place) { create(:place, name: 'Place 2') }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:event) do
      create(:event, company: company, campaign: campaign, place: place,
                     start_date: '01/01/2014', end_date: '01/01/2014')
    end
    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      let!(:invite) { create :invite, event: event }

      let!(:invite_individual) do
        create :invite_individual, invite: invite, first_name: 'Louis',
                                   last_name: 'Phillis', email: 'l@p.com',
                                   attended: false, rsvpd: true,
                                   created_at: Time.zone.local(2013, 8, 22, 11, 59),
                                   updated_at: Time.zone.local(2013, 8, 22, 11, 59)

      end

      it 'returns all the invites in the company with all the columns' do
        subject.columns = %w(first_name last_name email rsvpd attended
          attended_previous_bartender_ball created_by created_at
          campaign_name end_date end_time start_date start_time event_status
          place_street place_city place_name place_state place_zipcode
          active_state)
        expect(subject.rows).to eql [
          ['Louis', 'Phillis', 'l@p.com', 'Yes', 'No', 'No',  nil,
           '08/22/2013', 'Test Campaign FY01', '01/01/2014',
           '08:00 PM', '01/01/2014', '06:00 PM', 'Unsent', '11 Main St.',
           'New York City', 'Place 2', 'NY', '12345', 'Active']
        ]
      end

      it 'allows to sort the results' do
        other_campaign = create(:campaign, company: company, name: 'Campaign FY15')
        other_event = create(:approved_event, company: company, campaign: other_campaign, place: place)
        other_invite = create(:invite, event: other_event)
        create :invite_individual, invite: other_invite, first_name: 'Keylor',
                                   last_name: 'Navas', email: 'k@n.com',
                                   attended: false, rsvpd: true,
                                   created_at: Time.zone.local(2013, 8, 21, 11, 59)
        create :invite_individual, invite: invite, first_name: 'Patrick',
                                   last_name: 'Pemberton', email: 'p@p.com',
                                   attended: true, rsvpd: true,
                                   created_at: Time.zone.local(2013, 8, 23, 11, 59)

        subject.columns = %w(attended created_at campaign_name first_name)
        subject.default_sort_by = 'attended'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows.last).to eql [
          'Yes', '08/23/2013', 'Test Campaign FY01', 'Patrick'
        ]

        subject.default_sort_by = 'attended'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows.first).to eql [
          'Yes', '08/23/2013', 'Test Campaign FY01', 'Patrick'
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['No',  '08/21/2013', 'Campaign FY15', 'Keylor'],
          ['No',  '08/22/2013', 'Test Campaign FY01', 'Louis'],
          ['Yes', '08/23/2013', 'Test Campaign FY01', 'Patrick']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Yes', '08/23/2013', 'Test Campaign FY01', 'Patrick'],
          ['No',  '08/22/2013', 'Test Campaign FY01', 'Louis'],
          ['No',  '08/21/2013', 'Campaign FY15', 'Keylor']
        ]
      end
    end
  end
end
