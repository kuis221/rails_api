require 'spec_helper'

describe DateItemsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:date_range) {FactoryGirl.create(:date_range, company: @company)}

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
    let(:date_item){ FactoryGirl.create(:date_item, date_range_id: date_range.id) }
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
