require 'spec_helper'

describe Api::V1::EventExpensesController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { FactoryGirl.create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:place) { FactoryGirl.create(:place) }

  describe "GET 'index'" do
    it "should return failure for invalid authorization token" do
      get :index, company_id: company.to_param, auth_token: 'XXXXXXXXXXXXXXXX', event_id: 100, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid auth token')
      expect(result['data']).to be_empty
    end

    it "returns the list of expenses for the event" do
      event = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)
      receipt1 = FactoryGirl.create(:attached_asset, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      expense1 = FactoryGirl.create(:event_expense, amount: 99.99, name: 'Expense #1', receipt: receipt1, event: event)
      expense2 = FactoryGirl.create(:event_expense, amount: 159.15, name: 'Expense #2', event: event)
      Sunspot.commit

      get :index, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result).to eq([{
                         'id' => expense1.id,
                         'name' => 'Expense #1',
                         'amount' => '99.99',
                         'receipt' => {
                                       'id' => receipt1.id,
                                       'file_file_name' => receipt1.file_file_name,
                                       'file_content_type' => receipt1.file_content_type,
                                       'file_file_size' => receipt1.file_file_size,
                                       'created_at' => '2013-08-22T11:59:00.000-07:00',
                                       'active' => receipt1.active,
                                       'file_small' => receipt1.file.url(:small),
                                       'file_medium' => receipt1.file.url(:medium),
                                       'file_original' => receipt1.file.url
                                      }
                        },
                        {
                         'id' => expense2.id,
                         'name' => 'Expense #2',
                         'amount' => '159.15',
                         'receipt' => nil
                        }                      ])
    end
  end

  describe "POST 'create'", strategy: :deletion do
    let(:event) {FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)}
    it "create an expense and queue a job for processing the attached expense file" do
      ResqueSpec.reset!
      s3object = double()
      allow(s3object).to receive(:copy_from).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        "brandscopic-test" => double(objects: {
          'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
          'attached_assets/original/test.jpg' => s3object
        } ))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).at_least(:once).and_return('/attached_assets/original/test.jpg')
      expect {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event_id: event.to_param, event_expense: {name: 'Expense #1', amount: '350', receipt_attributes: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'}}, format: :json
      }.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      expense = EventExpense.last
      expect(expense.name).to eq('Expense #1')
      expect(expense.amount).to eq(350)
      expect(expense.receipt.attachable).to eq(expense)
      expect(expense.receipt.asset_type).to eq(nil)
      expect(expense.receipt.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(expense.receipt.id)
    end
  end
end
