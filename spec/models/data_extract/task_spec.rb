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
       [:title, :task_statuses, :due_at, :created_by, :created_at, :assigned_to, :comment1, :comment2, :comment3, :comment4, :comment5])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company,
                         user: create(:user, first_name: 'Benito', last_name: 'Camelas')) }

    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        event = create(:event, company: company)
        task = create(:task, event_id: event.id, due_at: Time.zone.local(2013, 2, 10, 9, 15), 
              created_at: Time.zone.local(2013, 8, 23, 9, 15), company_user: company_user,
              created_by: company_user.user)
        comment1 = create(:comment, content: 'Comment #1', commentable: task, created_at: Time.zone.local(2013, 8, 22, 11, 59))
        comment2 = create(:comment, content: 'Comment #2', commentable: task, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        comment2 = create(:comment, content: 'Comment #3', commentable: task, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        comment2 = create(:comment, content: 'Comment #4', commentable: task, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        comment2 = create(:comment, content: 'Comment #5', commentable: task, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ["MyString", "Active, Assigned, Incomplete", "02/10/2013", "Benito Camelas", "08/23/2013", "Benito Camelas",
           "Comment #5", "Comment #4", "Comment #3", "Comment #2", "Comment #1"]
        ]
      end

      it 'allows to sort the results' do
        event = create(:event, company: company)
        create(:task, event_id: event.id, due_at: Time.zone.local(2013, 2, 10, 9, 15), 
              created_at: Time.zone.local(2015, 2, 12, 9, 15), company_user: company_user,
              created_by: company_user.user, title: "Other Task", active: false)
        
        subject.columns = ['title', 'task_statuses', 'created_by']
        subject.default_sort_by = 'title'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["MyString", "Active, Assigned, Incomplete", "Benito Camelas"], 
          ["Other Task", "Inactive, Assigned, Incomplete", "Benito Camelas"]
        ]

        subject.default_sort_by = 'title'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Other Task", "Inactive, Assigned, Incomplete", "Benito Camelas"], 
          ["MyString", "Active, Assigned, Incomplete", "Benito Camelas"]
        ]

        subject.default_sort_by = 'task_statuses'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["MyString", "Active, Assigned, Incomplete", "Benito Camelas"], 
          ["Other Task", "Inactive, Assigned, Incomplete", "Benito Camelas"]
        ]

        subject.default_sort_by = 'task_statuses'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Other Task", "Inactive, Assigned, Incomplete", "Benito Camelas"], 
          ["MyString", "Active, Assigned, Incomplete", "Benito Camelas"]
        ]
      end
    end
  end
end
