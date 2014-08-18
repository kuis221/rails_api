require 'spec_helper'

describe Results::SurveysController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it "should return http success" do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('results/surveys/items')
    end
  end

  describe "GET 'index'" do
    it "queue the job for export the list" do
      expect{
        xhr :get, :index, format: :xls
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
    end
  end

end