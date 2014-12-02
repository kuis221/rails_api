require 'rails_helper'

describe ActivityTypesController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "GET 'autocomplete'" do
    it 'returns the correct buckets in the right order' do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map { |b| b['label'] }).to eq(['Activity Types', 'Active State'])
    end

    it 'should return the brands in the Day parts Bucket' do
      activity_type = create(:activity_type, name: 'Activity Type 1', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', q: 'act'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      activity_type_bucket = buckets.select { |b| b['label'] == 'Activity Types' }.first
      expect(activity_type_bucket['value']).to eq([
        { 'label' => '<i>Act</i>ivity Type 1', 'value' => activity_type.id.to_s, 'type' => 'activity_type' }
      ])
    end
  end

  describe "GET 'filters'" do
    it 'should return the correct filters in the right order' do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map { |b| b['label'] }).to eq(['Active State'])
    end
  end
end
