require 'rails_helper'

describe Results::CommentsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'queue the job for export the list' do
      expect { xhr :get, :index, format: :csv }.to change(ListExport, :count).by 1
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
    end
  end

  describe "GET 'items'" do
    it 'should return http success' do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('items')
    end
  end

  describe "GET 'list_export'", search: true do
    let(:campaign) { create(:campaign, company: @company, name: 'Test Campaign FY01') }

    let(:headers) do
      ["CAMPAIGN NAME", "VENUE NAME", "ADDRESS", "COUNTRY", "EVENT START DATE", "EVENT END DATE",
       'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY', 'COMMENT']
    end

    let(:export) { ListExport.last }

    context 'no comments in the database' do
      before { xhr(:get, 'index', format: :csv) }

      it 'should return an empty CSV with the correct headers' do
        ResqueSpec.perform_all(:export)
        expect(export.reload).to have_rows([headers])
      end
    end

    context 'one comment in the database' do
      let(:rows) {
         ["Test Campaign FY01", nil, "", nil, "2019-01-23 10:00", "2019-01-23 12:00",
          "2015-07-13 01:03", "Test User", "2015-07-13 01:03", "Test User", "MyText"]
      }

      let!(:event) {
        create(:approved_event, company: @company, campaign: campaign,
               start_date: '01/23/2019', end_date: '01/23/2019', start_time: '10:00 am', end_time: '12:00 pm',
               event_expenses: [
                   build(:event_expense, category: 'Entertainment', amount: 99.99,
                         created_at: DateTime.parse('2015-07-13 01:03 -07:00'), updated_at: DateTime.parse('2015-07-13 01:03 -07:00'))
               ])
      }
      let!(:comment) { create :comment, commentable: event }

      before { event.users << @company_user }
      before { Sunspot.commit }

      before { xhr(:get, 'index', format: :csv) }

      it 'should include the comment data results' do
        ResqueSpec.perform_all(:export)
        expect(export.reload).to have_rows([headers, rows])
      end
    end
  end
end
