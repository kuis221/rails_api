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

RSpec.describe DataExtract::Event, type: :model do

  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
       [:campaign_name, :end_date, :end_time, :start_date, :start_time,
        :place_street, :place_city, :place_name, :place_state,
        :place_zipcode, :event_team_members, :event_status, :status])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:user) { create(:company_user, company: company) }

    let(:campaign) { create(:campaign, name: 'Campaign Absolut FY12', company: company) }
    let(:subject) { described_class.new(company: company, current_user: user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        place = create(:place, name: 'My place', street_number: '21st', route: 'Jump Street',
                       city: 'Santa Rosa Beach', state: 'Florida')
        create(:event, campaign: campaign, start_date: '01/01/2014', start_time: '02:00 pm',
                       end_date: '01/01/2014', end_time: '03:00 pm', place: place,
                       users: [create(:company_user, company: company,
                                                     user: create(:user, first_name: 'Benito', last_name: 'Camelas'))]
              )
      end

      it 'returns all the events in the company with all the columns' do
        Event.last.users << create(:company_user,
                                   company: company,
                                   user: create(:user, first_name: 'Pedro', last_name: 'Almodovar'))
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '11:00 PM', '01/01/2014', '10:00 PM', '21st Jump Street',
           'Santa Rosa Beach', 'My place', 'Florida', '12345', 'Benito Camelas, Pedro Almodovar', 'Unsent', 'Active']
        ]
      end

      it 'returns only the requested columns' do
        subject.columns = ['campaign_name', 'start_date']
        expect(subject.rows).to eql [['Campaign Absolut FY12', '01/01/2014']]
      end

      it 'allows to filter the results' do
        subject.filters = { 'campaign' => [campaign.id + 1] }
        expect(subject.rows).to be_empty

        subject.filters = { 'campaign' => [campaign.id] }
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '11:00 PM', '01/01/2014', '10:00 PM', '21st Jump Street',
           'Santa Rosa Beach', 'My place', 'Florida', '12345', 'Benito Camelas', 'Unsent', 'Active']
        ]
      end

      it 'allows to sort the results' do
        create(:event, campaign: create(:campaign, name: 'Campaign Absolut FY13', company: company),
                       start_date: '02/02/2014', start_time: '03:00 am',
                       end_date: '02/02/2014', end_time: '03:00 pm')

        subject.columns = ['campaign_name', 'start_date', 'place_name']
        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', 'My place'],
          ['Campaign Absolut FY13', '02/02/2014', nil]
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY13', '02/02/2014', nil],
          ['Campaign Absolut FY12', '01/01/2014', 'My place']
        ]

        subject.default_sort_by = 'place_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', 'My place'],
          ['Campaign Absolut FY13', '02/02/2014', nil]
        ]

        subject.default_sort_by = 'place_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY13', '02/02/2014', nil],
          ['Campaign Absolut FY12', '01/01/2014', 'My place']
        ]
      end
    end
  end
end
