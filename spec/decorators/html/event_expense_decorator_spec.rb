require 'rails_helper'

describe Html::EventExpensePresenter, type: :presenter do

  describe '#amount' do
    it 'formats the amount' do
      presenter = present(build(:event_expense, amount: 20))
      expect(presenter.amount).to eql '$20.00'

      presenter = present(build(:event_expense, amount: 22.33111))
      expect(presenter.amount).to eql '$22.33'
    end
  end

  describe 'expense_date' do
    it 'formats the date' do
      presenter = present(build(:event_expense, expense_date: Date.new(2015, 01, 23)))
      expect(presenter.expense_date).to eql '01/23/2015'
    end
  end

  describe 'brand_name' do
    it 'returns the brand name' do
      presenter = present(build(:event_expense, brand: build(:brand, name: 'Cacique')))
      expect(presenter.brand_name).to eql 'Cacique'
    end

    it 'returns nil if no brand have been assigned' do
      presenter = present(build(:event_expense, brand_id: nil, brand: nil))
      expect(presenter.brand_name).to be_nil
    end
  end
end
