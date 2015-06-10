require 'rails_helper'

describe Api::V1::EventExpensesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01', modules: { 'expenses' => {} }) }
  let(:place) { create(:place) }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'" do
    it 'returns the list of expenses for the event', :show_in_doc do
      event = create(:approved_event, company: company, campaign: campaign, place: place)
      receipt1 = build(:attached_asset, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      expense1 = create(:event_expense, amount: 99.99, category: 'Entertainment', reimbursable: true,
                                        receipt: receipt1, event: event)
      expense2 = create(:event_expense, amount: 159.15, category: 'Fuel', event: event)
      Sunspot.commit

      get :index, event_id: event.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result).to eq([{
                             'id' => expense1.id,
                             'category' => 'Entertainment',
                             'amount' => '99.99',
                             'expense_date' => '01/01/2015',
                             'brand_id' => nil,
                             'reimbursable' => true,
                             'billable' => false,
                             'merchant' => nil,
                             'description' => nil,
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
                              'category' => 'Fuel',
                              'amount' => '159.15',
                              'expense_date' => '01/01/2015',
                              'brand_id' => nil,
                              'reimbursable' => false,
                              'billable' => false,
                              'merchant' => nil,
                              'description' => nil,
                              'receipt' => nil
                            }])
    end
  end

  describe "POST 'create'", strategy: :deletion do
    let(:event) { create(:approved_event, company: company, campaign: campaign, place: place) }
    it 'create an expense and queue a job for processing the attached expense file', :show_in_doc do
      s3object = double
      allow(s3object).to receive(:copy_from).and_return(true)
      allow(s3object).to receive(:exists?).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        'brandscopic-dev' => double(objects: {
                                      'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
                                      'attached_assets/original/test.jpg' => s3object
                                    }))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).at_least(:once).and_return('/attached_assets/original/test.jpg')
      expect do
        post 'create', event_id: event.to_param, event_expense: {
          category: 'Entertainment', amount: '350', expense_date: '01/01/2015',
          reimbursable: 'true', billable: 'true', description: 'expense description',
          merchant: 'merchant name',
          receipt_attributes: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }
        }, format: :json
      end.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      expense = EventExpense.last
      expect(expense.category).to eq('Entertainment')
      expect(expense.expense_date.to_s(:slashes)).to eq('01/01/2015')
      expect(expense.amount).to eq(350)
      expect(expense.description).to eq('expense description')
      expect(expense.reimbursable).to be_truthy
      expect(expense.billable).to be_truthy
      expect(expense.merchant).to eq('merchant name')
      expect(expense.receipt.attachable).to eq(expense)
      expect(expense.receipt.asset_type).to eq(nil)
      expect(expense.receipt.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(expense.receipt.id, 'AttachedAsset')
    end
  end

  describe "GET 'form'" do
    it 'returns the required information', :show_in_doc do
      event = create(:approved_event, company: company, campaign: campaign, place: place)
      Sunspot.commit

      get :form, event_id: event.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.keys).to match_array(%w(fields url))
      expect(result['fields'].keys).to match_array(%w(AWSAccessKeyId Secure key policy signature acl success_action_status))
    end
  end

  describe "DELETE 'destroy'", :show_in_doc do
    let(:event) { create(:event, company: company, campaign: campaign) }
    let(:expense) { create(:event_expense, event: event) }

    it 'destroys the expense' do
      expense
      expect do
        delete 'destroy', id: expense.to_param, event_id: event.to_param, format: :json
      end.to change(EventExpense, :count).by(-1)
      expect(response).to be_success
    end
  end
end
