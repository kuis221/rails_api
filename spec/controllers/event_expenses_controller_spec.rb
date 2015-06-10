require 'rails_helper'

describe EventExpensesController, type: :controller do
  let(:event) { create(:event, company: @company) }
  let(:event_expense) { create(:event_expense, event: event) }

  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'edit'" do
    it 'returns http success' do
      xhr :get, 'edit', event_id: event.to_param, id: event_expense.id, format: :js
      expect(response).to be_success
    end

    it 'cannot edit an event expense on other company' do
      other_event = without_current_user { create(:event, company: create(:company)) }
      other_expense = create(:event_expense, event: other_event)
      xhr :get, 'edit', event_id: other_event.to_param, id: other_expense.id, format: :js
      expect(response).to be_success
      expect(response).to render_template('access_denied')
    end
  end

  describe "POST 'create'" do
    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', event_id: event.to_param, event_expense: {
          amount: '100', category: 'Entertainment', brand_id: 12, expense_date: '01/03/2015'
        }, format: :js
      end.to change(EventExpense, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).to render_template('events/_expenses')
      expect(response).not_to render_template('_form_dialog')

      expense = EventExpense.last
      expect(expense.amount).to eq(100)
      expect(expense.category).to eq('Entertainment')
      expect(expense.expense_date.to_s(:slashes)).to eql '01/03/2015'
      expect(expense.brand_id).to eq(12)
    end

    it 'should not render the template events/expenses if errors' do
      expect do
        xhr :post, 'create', event_id: event.to_param, format: :js
      end.not_to change(EventExpense, :count)
      expect(response).to be_success
      expect(response).not_to render_template('events/expenses')
      assigns(:event_expense).errors.count > 0
    end

    it 'renders the split template if the split button was clicked' do
      expect do
        xhr :post, 'create', event_id: event.to_param, event_expense: {
          amount: '100', category: 'Entertainment', brand_id: 12, expense_date: '01/03/2015'
        }, commit: 'Split Expense', format: :js
      end.to_not change(EventExpense, :count)
      expect(response).to render_template 'split_expense'
    end
  end

  describe "DELETE 'destroy'" do
    it 'should delete the expense' do
      event_expense   # Make sure record is created before the expect block
      expect do
        delete 'destroy', event_id: event.to_param, id: event_expense.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template(:destroy)
      end.to change(EventExpense, :count).by(-1)
    end
  end

  describe 'POST split' do
    it 'updates the existing expense' do
      xhr :post, 'split', event_id: event.id, id: event_expense.id, event: { event_expenses_attributes: [
        { id: event_expense.id, amount: '100' }
      ] }, format: :js
      expect(response).to be_success
      expect(assigns(:event_expense)).to eql event_expense
    end

    it 'creates new expenses' do
      expect do
        xhr :post, 'split', event_id: event.id, id: nil, event: { event_expenses_attributes: [
          { id: nil, amount: '100', category: 'Entertainment', expense_date: '01/02/2014' },
          { id: nil, amount: '100', category: 'Entertainment', expense_date: '01/03/2014' }
        ] }, format: :js
      end.to change(EventExpense, :count).by(2)
      expect(response).to be_success
      expect(assigns(:event_expense).new_record?).to be_truthy
      expect(event.event_expenses.count).to eql 2
    end

    it 'deletes expenses marked for destroy' do
      event_expense
      expect do
        xhr :post, 'split', event_id: event.id, id: event_expense.id, event: { event_expenses_attributes: [
          { id: event_expense.id, _destroy: true },
          { id: nil, amount: '100', category: 'Entertainment', expense_date: '01/02/2014' },
          { id: nil, amount: '100', category: 'Entertainment', expense_date: '01/03/2014' }
        ] }, format: :js
      end.to change(EventExpense, :count).by(1) # Two created minus one removed
      expect(response).to be_success
      expect(assigns(:event_expense)).to eql event_expense
      expect(event.event_expenses.count).to eql 2
      expect { event_expense.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', event_id: event.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end
end
