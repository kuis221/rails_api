require 'spec_helper'

describe DayItemsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:day_part) {FactoryGirl.create(:day_part, company: @company)}


  describe "GET 'new'" do
    it "returns http success" do
      get 'new', day_part_id: day_part.to_param, format: :js
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', day_part_id: day_part.to_param, format: :js
      response.should be_success
      response.should render_template('create')
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', day_part_id: day_part.to_param, day_item: {start_time: '9:00 AM', end_time: '6:00 PM'}, format: :js
      }.should change(DayItem, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      day_item = DayItem.last
      day_item.start_time.to_s(:time_only).should == ' 9:00 AM'
      day_item.end_time.to_s(:time_only).should == ' 6:00 PM'
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', day_part_id: day_part.to_param, format: :js
      }.should_not change(DayItem, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:day_item).errors.count > 0
    end
  end

  describe "DELETE 'destroy'" do
    let(:day_item) { FactoryGirl.create(:day_item, day_part: day_part) }
    it "should delete the day item" do
      day_item.save   # Make sure record is created before the expect block
      expect {
        delete 'destroy', day_part_id: day_part.to_param, id: day_item.to_param, format: :js
        response.should be_success
        response.should render_template(:destroy)
      }.to change(DayItem, :count).by(-1)
    end
  end
end