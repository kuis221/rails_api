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

RSpec.describe DataExtract::Team, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(name Name), %w(description Description), ['created_by', 'Created By'],
        ['created_at', 'Created At'], ['active_state', 'Active State']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:campaign) { create(:campaign, name: 'Campaign Absolut FY12', company: company) }
    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true,
                      company_id: company.id, created_by_id: company_user.user.id, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Costa Rica Team', 'el grupo de ticos', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'campaign' => [campaign.id + 1] }
        expect(subject.rows).to be_empty

        subject.filters = { 'active_state' => ['active'] }
        expect(subject.rows).to eql [
          ['Costa Rica Team', 'el grupo de ticos', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to sort the results' do
        create(:team, name: 'Otro Team', description: 'Somos otro team', active: true,
                      company_id: company.id, created_by_id: company_user.user.id, created_at: Time.zone.local(2014, 8, 23, 9, 15))
        create(:team, name: 'Pilsen Team', description: 'Somos pilsen team', active: true,
                      company_id: company.id, created_by_id: company_user.user.id, created_at: Time.zone.local(2015, 8, 23, 9, 15))

        subject.columns = %w(name description created_at)
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Costa Rica Team', 'el grupo de ticos', '08/23/2013'],
          ['Otro Team', 'Somos otro team', '08/23/2014'],
          ['Pilsen Team', 'Somos pilsen team', '08/23/2015']
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Pilsen Team', 'Somos pilsen team', '08/23/2015'],
          ['Otro Team', 'Somos otro team', '08/23/2014'],
          ['Costa Rica Team', 'el grupo de ticos', '08/23/2013']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Costa Rica Team', 'el grupo de ticos', '08/23/2013'],
          ['Otro Team', 'Somos otro team', '08/23/2014'],
          ['Pilsen Team', 'Somos pilsen team', '08/23/2015']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Pilsen Team', 'Somos pilsen team', '08/23/2015'],
          ['Otro Team', 'Somos otro team', '08/23/2014'],
          ['Costa Rica Team', 'el grupo de ticos', '08/23/2013']
        ]
      end
    end
  end
end
