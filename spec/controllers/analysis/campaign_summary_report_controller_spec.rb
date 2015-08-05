require 'rails_helper'

describe Analysis::CampaignSummaryReportController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.current_company_user }
  let(:company) { user.companies.first }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }

  before { user }

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

end