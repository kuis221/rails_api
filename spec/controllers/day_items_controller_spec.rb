require 'spec_helper'

describe DayItemsController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:day_part) {FactoryGirl.create(:day_part, company: @company)}


  describe "GET 'new'" do
    it "returns http success" do
      get 'new', day_part_id: day_part.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', day_part_id: day_part.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('create')
    end

    it "should not render form_dialog if no errors" do
      expect {
        post 'create', day_part_id: day_part.to_param, day_item: {start_time: '9:00 AM', end_time: '6:00 PM'}, format: :js
      }.to change(DayItem, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template(:form_dialog)

      day_item = DayItem.last
      expect(day_item.start_time.to_s(:time_only)).to eq(' 9:00 AM')
      expect(day_item.end_time.to_s(:time_only)).to eq(' 6:00 PM')
    end

    it "should render the form_dialog template if errors" do
      expect {
        post 'create', day_part_id: day_part.to_param, format: :js
      }.not_to change(DayItem, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template(:form_dialog)
      assigns(:day_item).errors.count > 0
    end
  end

  describe "DELETE 'destroy'" do
    let(:day_item) { FactoryGirl.create(:day_item, day_part: day_part) }
    it "should delete the day item" do
      day_item.save   # Make sure record is created before the expect block
      expect {
        delete 'destroy', day_part_id: day_part.to_param, id: day_item.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template(:destroy)
      }.to change(DayItem, :count).by(-1)
    end
  end
end