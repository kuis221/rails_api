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
       [:comment, :created_by, :created_at, :campaign_name, :end_date, :end_time, :start_date, :start_time, :event_status, 
        :status, :address1, :address2, :place_city, :place_name, :place_state, :place_zipcode])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:place) { create(:place, name: 'Place 1') }
    let(:company_user) { create(:company_user, company: company,
                         user: create(:user, first_name: 'Benito', last_name: 'Camelas')) }
    let(:event) {create(:event, company: company, campaign: campaign, place: place, 
                        start_date: '01/01/2014', end_date: '01/01/2014') }
    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        comment1 = create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      end

      it 'returns all the comments in the company with all the columns' do
        expect(subject.rows).to eql [
          ["Comment #1", nil, "08/22/2013", "Test Campaign FY01", "01/01/2014", 
            "08:00 PM", "01/01/2014", "06:00 PM", "Unsent", "Active", "11", "Main St.", "New York City", "Place 1", "NY", "12345"]
        ]
      end

      it 'allows to sort the results' do
        other_campaign = create(:campaign, company: company, name: 'Campaign FY15')
        other_event = create(:approved_event, company: company, campaign: other_campaign, place: place)
        comment1 = create(:comment, content: 'Comment #2', commentable: other_event, created_at: Time.zone.local(2014, 2, 15, 11, 59))
        
        subject.columns = ['comment', 'campaign_name', 'created_at']
        subject.default_sort_by = 'comment'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Comment #1", "08/22/2013", "Test Campaign FY01"], 
          ["Comment #2", "02/15/2014", "Campaign FY15"]
        ]

        subject.default_sort_by = 'comment'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Comment #2", "02/15/2014", "Campaign FY15"], 
          ["Comment #1", "08/22/2013", "Test Campaign FY01"]
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Comment #2", "02/15/2014", "Campaign FY15"], 
          ["Comment #1", "08/22/2013", "Test Campaign FY01"]
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Comment #1", "08/22/2013", "Test Campaign FY01"], 
          ["Comment #2", "02/15/2014", "Campaign FY15"]
        ]
      end
    end
  end
end