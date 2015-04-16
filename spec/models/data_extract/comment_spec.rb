# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#

require 'rails_helper'

RSpec.describe DataExtract::Comment, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
        [%w(comment Comment), ['created_by', 'Created By'], ['created_at', 'Created At'],
         %w(campaign_name Campaign), ['end_date', 'End Date'], ['end_time', 'End Time'],
         ['start_date', 'Start Date'], ['start_time', 'Start Time'], ['event_status', 'Event Status'],
         ['status', 'Active State'], ['address1', 'Address 1'], ['address2', 'Address 2'],
         ['place_city', 'Venue City'], ['place_name', 'Venue Name'], ['place_state', 'Venue State'],
         ['place_zipcode', 'Venue ZIP code']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:place) { create(:place, name: 'Place 1') }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:event) do
      create(:event, company: company, campaign: campaign, place: place,
                     start_date: '01/01/2014', end_date: '01/01/2014')
    end
    let(:subject) do
      described_class.new(company: company, current_user: company_user)
    end

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        create(:comment, content: 'Comment #1', commentable: event,
                         user: company_user.user,
                         created_at: Time.zone.local(2013, 8, 22, 11, 59))
      end

      it 'returns all the comments in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Comment #1', 'Benito Camelas', '08/22/2013', 'Test Campaign FY01', '01/01/2014',
           '08:00 PM', '01/01/2014', '06:00 PM', 'Unsent', 'Active', '11', 'Main St.', 'New York City', 'Place 1', 'NY', '12345']
        ]
      end

      it 'allows to filter the results' do
        subject.columns = %w(comment campaign_name)
        subject.filters = { 'campaign' => [campaign.id + 1] }
        expect(subject.rows).to be_empty

        subject.filters = { 'campaign' => [campaign.id] }
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '11:00 PM', '01/01/2014', '10:00 PM', '21st Jump Street',
           'Santa Rosa Beach', 'My place', 'Florida', '12345', 'Benito Camelas', 'Unsent', 'Active']
        ]

        subject.filters = { 'user' => [company_user.id + 1] }
        expect(subject.rows).to be_empty

        subject.filters = { 'user' => [company_user.id, company_user.id + 1] }
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '11:00 PM', '01/01/2014', '10:00 PM', '21st Jump Street',
           'Santa Rosa Beach', 'My place', 'Florida', '12345', 'Benito Camelas', 'Unsent', 'Active']
        ]
      end

      it 'allows to sort the results' do
        other_campaign = create(:campaign, company: company, name: 'Campaign FY15')
        other_event = create(:approved_event, company: company, campaign: other_campaign, place: place)
        create(:comment, content: 'Comment #2', commentable: other_event,
                         created_at: Time.zone.local(2014, 2, 15, 11, 59))

        subject.columns = %w(comment created_at campaign_name)
        subject.default_sort_by = 'comment'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Comment #1', '08/22/2013', 'Test Campaign FY01'],
          ['Comment #2', '02/15/2014', 'Campaign FY15']
        ]

        subject.default_sort_by = 'comment'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Comment #2', '02/15/2014', 'Campaign FY15'],
          ['Comment #1', '08/22/2013', 'Test Campaign FY01']
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Comment #2', '02/15/2014', 'Campaign FY15'],
          ['Comment #1', '08/22/2013', 'Test Campaign FY01']
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Comment #1', '08/22/2013', 'Test Campaign FY01'],
          ['Comment #2', '02/15/2014', 'Campaign FY15']
        ]
      end
    end
  end
end
