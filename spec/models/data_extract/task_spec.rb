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

RSpec.describe DataExtract::Task, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
       [:title, :task_statuses, :due_at, :created_by_full_name, :created_at])
    end
  end

  describe '#rows', search: true do
    let(:company) { create(:company) }
    let(:subject) { described_class.new(company: company) }
    let(:user) { create(:user, company: company) }
    let(:company_user) { user.company_users.first }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        event = create(:event, company: company)
        create(:task, event_id: event.id, due_at: Time.zone.local(2013, 2, 10, 9, 15), created_at: Time.zone.local(2013, 8, 23, 9, 15))
        Sunspot.commit
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ["MyString", "Active, Unassigned, Incomplete, Late", Time.zone.local(2013, 2, 10, 9, 15), 
            nil, Time.zone.local(2013, 8, 23, 9, 15)]
        ]
      end

      it 'allows to filter the results' do

        subject.filters = { name: ['MyString'] }
        expect(subject.rows).to eql [
          ["MyString", "Active, Unassigned, Incomplete, Late", Time.zone.local(2013, 2, 10, 9, 15), 
            nil, Time.zone.local(2013, 8, 23, 9, 15)]
        ]
      end
    end
  end
end
