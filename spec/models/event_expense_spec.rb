# == Schema Information
#
# Table name: event_expenses
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  name          :string(255)
#  amount        :decimal(9, 2)    default(0.0)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe EventExpense, :type => :model do
  it { is_expected.to belong_to(:event) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:amount) }
end
