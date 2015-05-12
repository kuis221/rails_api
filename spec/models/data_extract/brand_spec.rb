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

RSpec.describe DataExtract::Brand, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
        [%w(name Name), %w(marques_list Marques),
         ['created_by', 'Created By'], ['created_at', 'Created At'], ['active_state', 'Active State']])
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
        brand = create(:brand, name: 'Guaro Cacique', company: company,
                               created_by_id: company_user.user.id,
                               created_at: Time.zone.local(2013, 8, 23, 9, 15))
        brand.marques << [create(:marque,  name: 'Marque 1'),
                          create(:marque,  name: 'Marque 2'),
                          create(:marque,  name: 'Marque 3')]
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Guaro Cacique', 'Marque 1, Marque 2, Marque 3', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'status' => ['inactive'] }
        subject.filters = { 'status' => ['inactive'] }
        subject.columns = %w(name created_by created_at active_state)
        expect(subject.rows).to be_empty

        subject.filters = { 'status' => ['active'] }
        expect(subject.rows).to eql [
          ['Guaro Cacique', 'Benito Camelas', '08/23/2013', 'Active']
        ]
      end

      it 'allows to sort the results' do
        create(:brand, name: 'Cerveza Imperial', company: company,
                       created_by_id: company_user.user.id,
                       created_at: Time.zone.local(2014, 2, 12, 9, 15))
        create(:brand, name: 'Cerveza Pilsen', company: company,
                       created_by_id: company_user.user.id,
                       created_at: Time.zone.local(2015, 2, 12, 9, 15))

        subject.columns = %w(name created_at)
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Cerveza Imperial', '02/12/2014'],
          ['Cerveza Pilsen', '02/12/2015'],
          ['Guaro Cacique', '08/23/2013']
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Guaro Cacique', '08/23/2013'],
          ['Cerveza Pilsen', '02/12/2015'],
          ['Cerveza Imperial', '02/12/2014']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Guaro Cacique', '08/23/2013'],
          ['Cerveza Imperial', '02/12/2014'],
          ['Cerveza Pilsen', '02/12/2015']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Cerveza Pilsen', '02/12/2015'],
          ['Cerveza Imperial', '02/12/2014'],
          ['Guaro Cacique', '08/23/2013']
        ]
      end
    end
  end
end
