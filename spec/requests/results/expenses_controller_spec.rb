require 'spec_helper'

describe Results::ExpensesController, js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "/results/expenses", js: true, search: true  do
    it "GET index should display a table with the expenses" do
      Kpi.create_global_kpis
      campaign.add_kpi(Kpi.expenses)
      event = FactoryGirl.build(:approved_event, campaign: campaign, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm')
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      event2 = FactoryGirl.build(:approved_event, campaign: campaign, company: @company, start_date: "08/25/2013", end_date: "08/25/2013", start_time: '9:00am', end_time: '10:00am')
      event2.event_expenses.build(name: 'Expense #1 Event #2', event_id: event.id, amount: 20)
      event2.save

      Sunspot.commit
      visit results_expenses_path

      within("ul#expenses-list") do
        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Expense #1 Event #1')
          page.should have_content('$10.00')
        end
        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('Expense #1 Event #2')
          page.should have_content('$20.00')
        end
      end
    end

    it "GET index should display a table with the expenses" do
      Kpi.create_global_kpis
      campaign.add_kpi(Kpi.expenses)
      event = FactoryGirl.build(:approved_event, campaign: campaign, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm')
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      Sunspot.commit
      visit results_expenses_path

      click_js_link("expense-link-#{event.event_expenses.first.id}")

      current_path.should == event_path(event.id)
    end
  end
end