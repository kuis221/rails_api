require 'rails_helper'

describe Api::V1::AreasController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  before { set_api_authentication_headers user, company }

  describe '#index' do
    it 'returns a list of areas' do
      area1 = create(:area, name: 'Central America', company_id: company.to_param)
      area2 = create(:area, name: 'North America', company_id: company.to_param)

      get 'index', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([{ 'id' => area1.id, 'name' => 'Central America' },
                                     { 'id' => area2.id, 'name' => 'North America' }])
    end
  end

  describe '#cities' do
    it 'returns a list of cities' do
      area = create(:area, name: 'Central America', company_id: company.to_param)
      city1 = create(:city, name: 'City #1 for Central America')
      city2 = create(:city, name: 'City #2 for Central America')

      area.places << [city1, city2]

      get 'cities', id: area.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([
        { 'id' => city1.id, 'name' => 'City #1 for Central America',
          'state' => 'NY', 'country' => 'US' },
        { 'id' => city2.id, 'name' => 'City #2 for Central America',
          'state' => 'NY', 'country' => 'US' }])
    end
  end
end
