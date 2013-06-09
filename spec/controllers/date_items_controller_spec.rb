require 'spec_helper'

describe DateItemsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:date_range) {FactoryGirl.create(:date_range, company: @company)}

  describe "GET 'edit'" do
    let(:date_item){ FactoryGirl.create(:date_item) }
    it "returns http success" do
      get 'edit', date_range_id: date_range.to_param, id: date_item.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index', date_range_id: date_range.to_param, format: :json
      response.should be_success
    end

    describe "json requests" do
      it "responds to .json format" do
        get 'index', date_range_id: date_range.to_param, format: :json
        response.should be_success
      end

      it "returns the correct structure" do
        FactoryGirl.create_list(:date_item, 3, date_range: date_range)

        # date_items on other companies should not be included on the results
        FactoryGirl.create_list(:date_item, 2, date_range_id: 2)

        get 'index', date_range_id: date_range.to_param, format: :json
        parsed_body = JSON.parse(response.body)
        parsed_body["total"].should == 3
        parsed_body["items"].count.should == 3
      end
    end
  end

  describe "GET 'show'" do
    let(:date_item){ FactoryGirl.create(:date_item) }
    it "assigns the loads the correct objects and templates" do
      get 'show', date_range_id: date_range.to_param, id: date_item.id
      assigns(:date_item).should == date_item
      response.should render_template(:show)
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', date_range_id: date_range.to_param, format: :js
      response.should be_success
      response.should render_template('create')
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', date_range_id: date_range.to_param, date_item: {start_date: '01/24/2013', end_date: '01/24/2013'}, format: :js
      }.should change(DateItem, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      date_item = DateItem.last
      date_item.start_date.should == Date.new(2013, 01, 24)
      date_item.end_date.should == Date.new(2013, 01, 24)
      date_item.recurrence.should be_false
      date_item.recurrence_type.should == 'daily'
      date_item.recurrence_days.should be_nil
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', date_range_id: date_range.to_param, format: :js
      }.should_not change(DateItem, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:date_item).errors.count > 0
    end
  end

  describe "PUT 'update'" do
    let(:date_item){ FactoryGirl.create(:date_item) }
    it "must update the date_item attributes" do
      t = FactoryGirl.create(:date_item)
      put 'update', date_range_id: date_range.to_param, id: date_item.to_param, date_item: {start_date: '01/23/2013', end_date: '01/24/2013'}, format: :js
      assigns(:date_item).should == date_item
      response.should be_success
      response.should render_template('update')
      date_item.reload
      date_item.start_date.should == Date.new(2013,01,23)
      date_item.end_date.should == Date.new(2013,01,24)
    end
  end
end
