require 'spec_helper'

describe EventExpensesController do
  let(:event){ FactoryGirl.create(:event, company: @company) }
  let(:event_expense){ FactoryGirl.create(:event_expense, event: event) }

  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', event_id: event.to_param, id: event_expense.id, format: :js
      response.should be_success
    end

    it 'cannot edit an event expense on other company' do
      other_event = without_current_user{ FactoryGirl.create(:event, company: FactoryGirl.create(:company)) }
      other_expense = FactoryGirl.create(:event_expense, event: other_event)
      get 'edit', event_id: other_event.to_param, id: other_expense.id, format: :js
      response.should be_success
      response.should render_template('access_denied')
    end
  end

  describe "POST 'create'" do
    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', event_id: event.to_param, amount: '100', name: 'Test expense', format: :js
      }.should change(EventExpense, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should render_template('events/_expenses')
      response.should_not render_template(:form_dialog)

      event_expense = EventExpense.last
      event_expense.amount.should == 100
      event_expense.name.should == 'Test expense'
    end

    it "should not render the template events/expenses if errors" do
      lambda {
        post 'create', event_id: event.to_param, format: :js
      }.should_not change(EventExpense, :count)
      response.should be_success
      response.should_not render_template('events/expenses')
      assigns(:event_expense).errors.count > 0
    end
  end

  describe "DELETE 'destroy'" do
    let(:event_expense) { FactoryGirl.create(:event_expense, event: event) }
    it "should delete the expense" do
      event_expense.save   # Make sure record is created before the expect block
      expect {
        delete 'destroy', event_id: event.to_param, id: event_expense.to_param, format: :js
        response.should be_success
        response.should render_template(:destroy)
      }.to change(EventExpense, :count).by(-1)
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', event_id: event.to_param, format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('form')
    end
  end
end
