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

  describe 'max_event_event_expenses validation' do
    let(:campaign) { create(:campaign) }
    let(:event) { create(:event, campaign: campaign) }

    describe "when a max is set for the campaign" do
      before do
        event.campaign.update_attribute(
          :modules, {'expenses' => {'settings' => { 'range_min' => '1',
                                                  'range_max' => '2' }}})
      end

      it 'should not allow create more than two event_expenses for the event' do
        create_list(:event_expense, 2, event: event)
        event_expense = build(:event_expense, event: event)
        expect(event_expense.save).to be_falsey
        expect(event_expense.errors.full_messages).to include(
          'Sorry. No more than 2 expenses can be logged for this event. Your expense was not saved.')
      end

      it 'correctly displays a message when max is set to 1' do
        event.campaign.update_attribute(
          :modules, {'expenses' => {'settings' => { 'range_max' => '1' }}})
        create(:event_expense, event: event)
        event_expense = build(:event_expense, event: event)
        expect(event_expense.save).to be_falsey
        expect(event_expense.errors.full_messages).to include(
          'Sorry. No more than 1 expenses can be logged for this event. Your expense was not saved.')
      end
    end

    describe "when a max is not set for the campaing" do
      before do
        event.campaign.update_attribute(
          :modules, {'expenses' => {'settings' => { 'range_min' => '1',
                                                    'range_max' => '' }}})
      end

      it 'allows create any number of comments for the event' do
        event_expense = build(:event_expense, event: event)
        expect(event_expense.save).to be_truthy
      end
    end
  end
end
