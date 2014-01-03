require 'spec_helper'

describe Api::V1::EventExpensesController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "GET 'index'" do
    let(:campaign) { FactoryGirl.create(:campaign, company: company, name: 'Test Campaign FY01') }
    it "should return failure for invalid authorization token" do
      get :index, company_id: company.to_param, auth_token: 'XXXXXXXXXXXXXXXX', event_id: 100, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "returns the list of expenses for the event" do
      place = FactoryGirl.create(:place, name: 'Test Bar', city: 'Los Angeles', state: 'California', country: 'US')
      event = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)
      expense1 = FactoryGirl.create(:event_expense, amount: 99.99, name: 'Expense #1', event: event)
      expense2 = FactoryGirl.create(:event_expense, amount: 159.15, name: 'Expense #2', event: event)
      Sunspot.commit

      get :index, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result.count.should == 2
      result.should == [{
                         'id' => expense1.id,
                         'name' => 'Expense #1',
                         'amount' => '99.99'
                        },
                        {
                         'id' => expense2.id,
                         'name' => 'Expense #2',
                         'amount' => '159.15'
                        }                      ]
    end
  end
end
