require 'rails_helper'

describe Api::V1::BrandsController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "#index" do
    it "returns a list of brands" do
      brand1 = FactoryGirl.create(:brand, name: 'Cacique', company_id: company.to_param)
      brand2 = FactoryGirl.create(:brand, name: 'Nikolai', company_id: company.to_param)

      get 'index', auth_token: user.authentication_token, company_id: company.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([{"id"=> brand1.id, "name"=>'Cacique', "active"=>true},
                                     {"id"=> brand2.id, "name"=>'Nikolai', "active"=>true}])
    end
  end

  describe "#marques" do
    it "returns a list of marques" do
      brand = FactoryGirl.create(:brand, name: 'Cacique', company_id: company.to_param)
      marque1 = FactoryGirl.create(:marque, name: 'Marque #1 for Cacique', brand: brand)
      marque2 = FactoryGirl.create(:marque, name: 'Marque #2 for Cacique', brand: brand)

      get 'marques', auth_token: user.authentication_token, company_id: company.to_param, id: brand.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([{"id"=> marque1.id, "name"=>'Marque #1 for Cacique'},
                                     {"id"=> marque2.id, "name"=>'Marque #2 for Cacique'}])
    end
  end
end