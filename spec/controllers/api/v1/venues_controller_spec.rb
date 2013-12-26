require 'spec_helper'

describe Api::V1::VenuesController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "GET 'search'", search: true do
    it "return a list of events" do
      campaign = FactoryGirl.create(:campaign, company: company)
      venue = FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, name: 'Casa de Doña Lela', formatted_address: '1234 Tres Rios'))
      Sunspot.commit

      get :search, auth_token: user.authentication_token, company_id: company.to_param, term: 'lela', format: :json
      response.should be_success
      result = JSON.parse(response.body)

      expect(result.first).to include("value"=>"Casa de Doña Lela, 1234 Tres Rios", "label"=> "Casa de Doña Lela, 1234 Tres Rios", "id"=>venue.place_id)
    end
  end
end