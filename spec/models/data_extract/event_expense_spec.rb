# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default(TRUE)
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

RSpec.describe DataExtract::EventExpense, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(category Category), %w(amount Amount), ['expense_date', 'Date'],
        ['reimbursable', 'Reimbursable'], ['billable', 'Billable'], ['merchant', 'Merchant'],
        ['description', 'Description'], %w(campaign_name Campaign), %w(brand_name Brand),  ['end_date', 'End Date'],
        ['end_time', 'End Time'], ['start_date', 'Start Date'], ['start_time', 'Start Time'],
        ['event_status', 'Event Status'], ['place_street', 'Venue Street'], ['place_city', 'Venue City'],
        ['place_name', 'Venue Name'], ['place_state', 'Venue State'], ['place_zipcode', 'Venue ZIP Code'],
        ['created_by', 'Created By'], ['created_at', 'Created At']])
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
      before do
        expense2 = create(:event_expense, amount: 159.15, category: 'Entertainment', event: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      end

      it 'returns all the comments in the company with all the columns' do
        subject.columns = %w(category created_by created_at campaign_name end_date end_time start_date start_time event_status place_street place_city place_name place_state place_zipcode)
        expect(subject.rows).to eql [
          ['Entertainment', nil, '08/22/2013', 'Test Campaign FY01', '01/01/2014', '08:00 PM',
           '01/01/2014', '06:00 PM', 'Unsent', '11 Main St.', 'New York City', 'Place 2', 'NY', '12345']
        ]
      end

      it 'allows to sort the results' do
        other_campaign = create(:campaign, company: company, name: 'Campaign FY15')
        other_event = create(:approved_event, company: company, campaign: other_campaign, place: place)
        create(:event_expense, amount: 34, category: 'Uncategorized', event: other_event,
                               created_at: Time.zone.local(2014, 2, 17, 11, 59))
        create(:event_expense, amount: 21, category: 'Fuel/Mileage', event: other_event,
                               created_at: Time.zone.local(2015, 2, 17, 11, 59))

        subject.columns = %w(category created_at campaign_name)
        subject.default_sort_by = 'category'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Entertainment', '08/22/2013', 'Test Campaign FY01'],
          ['Fuel/Mileage', '02/17/2015', 'Campaign FY15'],
          ['Uncategorized', '02/17/2014', 'Campaign FY15']
        ]

        subject.default_sort_by = 'category'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Uncategorized', '02/17/2014', 'Campaign FY15'],
          ['Fuel/Mileage', '02/17/2015', 'Campaign FY15'],
          ['Entertainment', '08/22/2013', 'Test Campaign FY01']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Entertainment', '08/22/2013', 'Test Campaign FY01'],
          ['Uncategorized', '02/17/2014', 'Campaign FY15'],
          ['Fuel/Mileage', '02/17/2015', 'Campaign FY15']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Fuel/Mileage', '02/17/2015', 'Campaign FY15'],
          ['Uncategorized', '02/17/2014', 'Campaign FY15'],
          ['Entertainment', '08/22/2013', 'Test Campaign FY01']
        ]
      end
    end
  end
end
