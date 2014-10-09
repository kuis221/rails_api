# == Schema Information
#
# Table name: tasks
#
#  id              :integer          not null, primary key
#  event_id        :integer
#  title           :string(255)
#  due_at          :datetime
#  completed       :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :integer
#  updated_by_id   :integer
#  active          :boolean          default(TRUE)
#  company_user_id :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task do
    event_id 1
    title 'MyString'
    due_at '2013-05-02 15:56:44'
    company_user_id nil
    completed false

    factory :late_task do
      completed false
      due_at 3.days.ago
    end

    factory :future_task do
      due_at 3.days.from_now
    end

    factory :assigned_task do
      company_user_id 1
    end

    factory :unassigned_task do
      company_user_id nil
    end

    factory :completed_task do
      completed true
    end

    factory :uncompleted_task do
      completed false
    end
  end
end
