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

RSpec.describe DataExtract::Campaign, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(name Name), %w(description Description), %w(brands_list Brands),
        ['campaign_brand_portfolios', 'Brand Portfolios'], ['start_date', 'Start Date'],
        ['end_date', 'End Date'], %w(color Color), ['created_at', 'Created At'],
        ['created_by', 'Created By'], ['modified_at', 'Modified At'], ['modified_by', 'Modified By'],
        ['active_state', 'Active State']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:subject) { described_class.new(company: company, current_user: company_user,
                    columns: ['name', 'description', 'brands_list', 'campaign_brand_portfolios',
                    'start_date', 'end_date', 'color', 'created_by', 'created_at', 'active_state']) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        create(:campaign, name: 'Campaign Absolut FY12', description: 'Description campaign', company: company,
                          created_by_id: company_user.user.id, color: '#de4d43', created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', 'Description campaign', '', '', nil, nil, '#de4d43', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'status' => ['inactive'] }
        expect(subject.rows).to be_empty

        subject.filters = { 'status' => ['active'] }
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', 'Description campaign', '', '', nil, nil, '#de4d43', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end
    end
  end
end
