# == Schema Information
#
# Table name: event_expenses
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  amount        :decimal(15, 2)   default(0.0)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  brand_id      :integer
#  category      :string(255)
#  expense_date  :date
#  reimbursable  :boolean
#  billable      :boolean
#  merchant      :string(255)
#  description   :text
#

require 'rails_helper'

describe EventExpense, type: :model do
  it { is_expected.to belong_to(:event) }

  it { is_expected.to validate_presence_of(:category) }
  it { is_expected.to validate_presence_of(:expense_date) }
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_numericality_of(:amount) }
  it { is_expected.to allow_value('0.50').for(:amount) }
  it { is_expected.to allow_value('50').for(:amount) }
  it { is_expected.to_not allow_value('0.00').for(:amount) }
end
