require 'rails_helper'

RSpec.describe FiltersController, type: :controller do

  let(:company) { create(:company) }
  let(:user) { company_user.user }
  let(:role) { create(:role, is_admin: false, company: company) }
  let(:company_user) do
    create(:company_user,
           company: company,
           role: role)
  end

  before { sign_in user }

  describe 'GET show' do
    describe 'as admin user' do
      let(:role) { create(:role, company: company) }

      it 'not return objects for other companies' do
        create(:campaign, name: 'CFY12', company: company)
        create(:campaign, name: 'IN OTHER COMPANY', company: create(:company))
        get 'show', id: :events, format: :json

        filters = json['filters'].find { |f| f['label'] == 'Campaigns' }

        expect(filters['items'].map { |i| i['label'] }).to eql ['CFY12']
      end
    end

    it 'returns all the keys for the events scope' do
      get :show, id: 'events'
      expect(response).to be_success
      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Campaigns', 'Brands', 'Areas', 'People', 'Event Status',
        'Active State', 'Saved Filters'])
    end

    it 'should return the correct items for the Campaign bucket' do
      # Assigned area with a common place, it should be in the filters
      campaign = create(:campaign, name: 'CFY12', company: company)

      # Not assigned campaign
      create(:campaign, company: company)

      # Inactive campaign
      inactive_campaign = create(:campaign, company: company, aasm_state: 'inactive')

      # Campaign in another company
      create(:campaign, company: create(:company))

      company_user.campaigns << [campaign, inactive_campaign]

      get 'show', id: :events, format: :json
      expect(response).to be_success
      filters = json['filters'].find { |f| f['label'] == 'Campaigns' }
      expect(filters['items'].count).to eql 1

      expect(filters['items'].first).to eql(
        'id' => campaign.id, 'label' => 'CFY12', 'value' => campaign.id,
        'name' => 'campaign', 'selected' => false
      )
    end

    it 'should return active state bucket' do
      # Assigned area with a common place, it should be in the filters
      campaign = create(:campaign, name: 'CFY12', company: company)

      # Not assigned campaign
      create(:campaign, company: company)

      # Inactive campaign
      inactive_campaign = create(:campaign, company: company, aasm_state: 'inactive')

      # Campaign in another company
      create(:campaign, company: create(:company))

      company_user.campaigns << [campaign, inactive_campaign]

      get 'show', id: :events, format: :json
      expect(response).to be_success
      areas_filters = json['filters'].find { |f| f['label'] == 'Active State' }
      expect(areas_filters['items'].count).to eql 2

      expect(areas_filters['items'].first).to eql(
        'id' => 'Active', 'label' => 'Active', 'value' => 'Active',
        'name' => 'status', 'selected' => false
      )
    end

    it 'should return the correct items for the Area bucket' do
      # Assigned area with a common place, it should be in the filters
      area = create(:area, name: 'Austin', company: company)
      area.places << create(:city, name: 'Bee Cave', state: 'Texas', country: 'US')
      company_user.areas << area

      # Unassigned area with a common place, it should be in the filters
      area_unassigned = create(:area, name: 'San Antonio', company: company)
      area_unassigned.places << create(:city, name: 'Schertz',
                                              state: 'Texas', country: 'US')

      # Unassigned area with not common place, it should not be in the filters
      area_not_in_filter = create(:area, name: 'Miami', company: company)
      area_not_in_filter.places << create(:city, name: 'Doral',
                                                 state: 'Florida', country: 'US')

      # Assigned area with not common place, it should be in the filters
      company_user.areas << create(:area, name: 'San Francisco', company: company)

      # Assigned place, itis the responsible for the common areas in the filters
      company_user.places << create(:state, name: 'Texas', country: 'US')

      get 'show', id: :events, format: :json
      expect(response).to be_success
      areas_filters = json['filters'].find { |f| f['label'] == 'Areas' }
      expect(areas_filters['items'].count).to eql 3

      expect(areas_filters['items'].first).to eql(
        'id' => area.id, 'label' => 'Austin', 'value' => area.id,
        'name' => 'area', 'selected' => false
      )

      expect(areas_filters['items'].map { |i| i['label'] }).to eql [
        'Austin', 'San Antonio', 'San Francisco']
    end
  end

end
