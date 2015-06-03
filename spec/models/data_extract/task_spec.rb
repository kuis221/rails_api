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

RSpec.describe DataExtract::Task, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(title Title), %w(task_statuses Statuses), ['due_at', 'Due At'],
        ['created_by', 'Created By'], ['created_at', 'Created At'], ['assigned_to', 'Assigned To'],
        ['comment1', 'Comment 1'], ['comment2', 'Comment 2'], ['comment3', 'Comment 3'],
        ['comment4', 'Comment 4'], ['comment5', 'Comment 5'], ['active_state', 'Active State']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end

    let(:subject) { described_class.new(company: company, current_user: company_user,
                    columns: ['title', 'task_statuses', 'due_at', 'created_by', 'created_at',
                    'assigned_to', 'comment1', 'comment2', 'comment3', 'comment4', 'comment5', 'active_state']) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        event = create(:event, company: company)
        task = create(:task, event_id: event.id, due_at: Time.zone.local(2013, 2, 10, 9, 15),
                             created_at: Time.zone.local(2013, 8, 23, 9, 15), company_user: company_user,
                             created_by: company_user.user)
        comment1 = create(:comment, content: 'Comment #1', commentable: task, created_at: Time.zone.local(2013, 8, 15, 11, 59))
        comment2 = create(:comment, content: 'Comment #2', commentable: task, created_at: Time.zone.local(2013, 8, 16, 9, 15))
        comment2 = create(:comment, content: 'Comment #3', commentable: task, created_at: Time.zone.local(2013, 8, 17, 9, 15))
        comment2 = create(:comment, content: 'Comment #4', commentable: task, created_at: Time.zone.local(2013, 8, 18, 9, 15))
        comment2 = create(:comment, content: 'Comment #5', commentable: task, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['MyString', 'Active, Assigned, Incomplete, Late', '02/10/2013', 'Benito Camelas', '08/23/2013', 'Benito Camelas',
           'Comment #1', 'Comment #2', 'Comment #3', 'Comment #4', 'Comment #5', 'Active']
        ]
      end

      it 'allows to sort the results' do
        event = create(:event, company: company)
        create(:task, event_id: event.id, due_at: Time.zone.local(2014, 2, 10, 9, 15),
                      created_at: Time.zone.local(2015, 2, 12, 9, 15), company_user: company_user,
                      created_by: company_user.user, title: 'Other Task', active: false)
        create(:task, event_id: event.id, due_at: Time.zone.local(2015, 2, 10, 9, 15),
                      created_at: Time.zone.local(2014, 2, 12, 9, 15), company_user: company_user,
                      created_by: company_user.user, title: 'Super Task', active: false)

        subject.columns = %w(title task_statuses due_at)
        subject.default_sort_by = 'title'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['MyString', 'Active, Assigned, Incomplete, Late', '02/10/2013'],
          ['Other Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2014'],
          ['Super Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2015']
        ]

        subject.default_sort_by = 'title'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Super Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2015'],
          ['Other Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2014'],
          ['MyString', 'Active, Assigned, Incomplete, Late', '02/10/2013']
        ]

        subject.default_sort_by = 'due_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['MyString', 'Active, Assigned, Incomplete, Late', '02/10/2013'],
          ['Other Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2014'],
          ['Super Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2015']
        ]

        subject.default_sort_by = 'due_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Super Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2015'],
          ['Other Task', 'Inactive, Assigned, Incomplete, Late', '02/10/2014'],
          ['MyString', 'Active, Assigned, Incomplete, Late', '02/10/2013']
        ]
      end
    end
  end
end
