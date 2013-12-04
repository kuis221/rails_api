require 'spec_helper'

describe Results::CommentsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      response.should be_success
    end
  end
  
  describe "GET 'index'", js: true, search: true do
    it "queue the job for export the list" do
      expect{
        get :index, format: :xlsx
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      ListExportWorker.should have_queued(export.id)
    end
  end
  
  describe "GET 'items'", search: true do
    it "should return http success" do
      Sunspot.commit
      get 'items'
      response.should be_success
      response.should render_template('items')
    end
  end

end