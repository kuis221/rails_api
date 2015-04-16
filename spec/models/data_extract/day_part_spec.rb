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
#  params           :text
#

require 'rails_helper'

RSpec.describe DataExtract::DayPart, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(name Name), %w(description Description), ['created_by', 'Created By'],
        ['created_at', 'Created At']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        create(:day_part, name: 'Day Part 1', active: true, created_by_id: company_user.user.id,
                          company: company, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Day Part 1', 'Some Day Part description', 'Benito Camelas', '08/23/2013']
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'status' => ['inactive'] }
        expect(subject.rows).to be_empty

        subject.filters = { 'status' => ['active'] }
        expect(subject.rows).to eql [
          ['Day Part 1', 'Some Day Part description', 'Benito Camelas', '08/23/2013']
        ]
      end

      it 'allows to sort the results' do
        create(:day_part, name: 'Fecha 2', active: true, created_by_id: company_user.user.id,
                          company: company, created_at: Time.zone.local(2015, 2, 12, 9, 15))

        subject.columns = %w(name created_at)
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Day Part 1', '08/23/2013'],
          ['Fecha 2', '02/12/2015']
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Fecha 2', '02/12/2015'],
          ['Day Part 1', '08/23/2013']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Fecha 2', '02/12/2015'],
          ['Day Part 1', '08/23/2013']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Day Part 1', '08/23/2013'],
          ['Fecha 2', '02/12/2015']
        ]
      end
    end
  end
end
