require 'rails_helper'

describe CustomFiltersController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.company_users.first
  end

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "should be able to create a custom filter" do
      expect {
        xhr :post, 'create', custom_filter: {name: 'My Custom Filter', apply_to: 'events', filters: 'Filters'}, format: :js
      }.to change(CustomFilter, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      expect(response).not_to render_template('_form_dialog')
      custom_filter = CustomFilter.last
      expect(custom_filter.owner).to eq(@company_user)
      expect(custom_filter.name).to eq('My Custom Filter')
      expect(custom_filter.apply_to).to eq('events')
      expect(custom_filter.filters).to eq('Filters')
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', custom_filter: {name: '', apply_to: '', filters: ''}, format: :js
      }.not_to change(CustomFilter, :count)
      expect(response).to render_template('create')
      expect(response).to render_template('_form_dialog')
      assigns(:custom_filter).errors.count > 0
    end
  end

  describe "DELETE 'destroy'" do
    let(:custom_filter) { FactoryGirl.create(:custom_filter, owner: @company_user, name: 'My Custom Filter', apply_to: 'events', filters: 'Filters') }
    it "should delete the custom filter" do
      custom_filter.save # Make sure record is created before the expect block
      expect {
        delete 'destroy', id: custom_filter.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template(:destroy)
      }.to change(CustomFilter, :count).by(-1)
    end
  end
end