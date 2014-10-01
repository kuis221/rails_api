require 'rails_helper'

describe DateItemsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:date_range) { create(:date_range, company: @company) }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', date_range_id: date_range.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', date_range_id: date_range.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('create')
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', date_range_id: date_range.to_param, date_item: { start_date: '01/24/2013', end_date: '01/24/2013' }, format: :js
      end.to change(DateItem, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      date_item = DateItem.last
      expect(date_item.start_date).to eq(Date.new(2013, 01, 24))
      expect(date_item.end_date).to eq(Date.new(2013, 01, 24))
      expect(date_item.recurrence).to be_falsey
      expect(date_item.recurrence_type).to eq('daily')
      expect(date_item.recurrence_days).to be_nil
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', date_range_id: date_range.to_param, format: :js
      end.not_to change(DateItem, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:date_item).errors.count > 0
    end
  end

  describe "DELETE 'destroy'" do
    let(:date_item) { create(:date_item, date_range: date_range) }
    it 'should delete the day item' do
      date_item.save   # Make sure record is created before the expect block
      expect do
        delete 'destroy', date_range_id: date_range.to_param, id: date_item.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template(:destroy)
      end.to change(DateItem, :count).by(-1)
    end
  end
end
