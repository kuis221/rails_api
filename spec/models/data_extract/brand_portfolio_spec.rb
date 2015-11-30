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

RSpec.describe DataExtract::BrandPortfolio, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(name Name), %w(description Description), ['created_at', 'Created At'],
        ['created_by', 'Created By'], ['modified_at', 'Modified At'],
        ['modified_by', 'Modified By'], ['active_state', 'Active State']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:subject) do
      described_class.new(company: company, current_user: company_user,
                    columns: %w(name description created_by created_at active_state))
    end

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        create(:brand_portfolio, name: 'A Vinos ticos',
                                 description: 'Algunos vinos de Costa Rica',
                                 active: true, company: company,
                                 created_by_id: company_user.user.id,
                                 created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['A Vinos ticos', 'Algunos vinos de Costa Rica', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'status' => ['inactive'] }
        expect(subject.rows).to be_empty

        subject.filters = { 'status' => ['active'] }
        expect(subject.rows).to eql [
          ['A Vinos ticos', 'Algunos vinos de Costa Rica', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to sort the results' do
        create(:brand_portfolio, name: 'Cervezas Ticas',
                                 description: 'Cervezas de Costa Rica',
                                 active: true, company: company,
                                 created_by_id: company_user.user.id,
                                 created_at: Time.zone.local(2014, 3, 26, 9, 15))
        create(:brand_portfolio, name: 'Ron Barcardi',
                                 description: 'Cervezas de Costa Rica',
                                 active: true, company: company,
                                 created_by_id: company_user.user.id,
                                 created_at: Time.zone.local(2015, 3, 26, 9, 15))
        subject.columns = %w(name description created_at)
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['A Vinos ticos', 'Algunos vinos de Costa Rica', '08/23/2013'],
          ['Cervezas Ticas', 'Cervezas de Costa Rica', '03/26/2014'],
          ['Ron Barcardi', 'Cervezas de Costa Rica', '03/26/2015']
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Ron Barcardi', 'Cervezas de Costa Rica', '03/26/2015'],
          ['Cervezas Ticas', 'Cervezas de Costa Rica', '03/26/2014'],
          ['A Vinos ticos', 'Algunos vinos de Costa Rica', '08/23/2013']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['A Vinos ticos', 'Algunos vinos de Costa Rica', '08/23/2013'],
          ['Cervezas Ticas', 'Cervezas de Costa Rica', '03/26/2014'],
          ['Ron Barcardi', 'Cervezas de Costa Rica', '03/26/2015']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Ron Barcardi', 'Cervezas de Costa Rica', '03/26/2015'],
          ['Cervezas Ticas', 'Cervezas de Costa Rica', '03/26/2014'],
          ['A Vinos ticos', 'Algunos vinos de Costa Rica', '08/23/2013']
        ]
      end
    end
  end
end
