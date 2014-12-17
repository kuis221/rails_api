require 'rails_helper'

describe AreasController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }

  before { user }

  let(:area) { create(:area, company: company) }

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order when the user is in the 'teams' scope" do
      get 'autocomplete', scope: :teams
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map { |b| b['label'] }).to eq([
        'Areas', 'Active State'])
    end

    it 'should return the areas in the Area Bucket' do
      t = create(:area, name: 'Test Area', description: 'Test Area description', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', q: 'te'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      area_bucket = buckets.select { |b| b['label'] == 'Areas' }.first
      expect(area_bucket['value']).to eq([{ 'label' => '<i>Te</i>st Area', 'value' => t.id.to_s, 'type' => 'area' }])
    end
  end

end
