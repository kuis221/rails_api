# == Schema Information
#
# Table name: event_expenses
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  name          :string(255)
#  amount        :decimal(15, 2)   default(0.0)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  brand_id      :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_expense do
    event nil
    sequence(:name) { |n| "Expense #{n}" }
    amount '9.99'
    brand_id nil
  end
end
