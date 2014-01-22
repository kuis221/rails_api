require 'spec_helper'

feature "Reports", js: true do
  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end


  feature "Create a report" do
    scenario 'user is redirected to the report build page after creation' do
      visit results_reports_path

      click_js_button 'New report'

      expect {
        within visible_modal do
          fill_in 'Name', with: 'new report name'
          fill_in 'Description', with: 'new report description'
          click_button 'Create'
        end
        ensure_modal_was_closed
      }.to change(Report, :count).by(1)
      report = Report.last

      expect(current_path).to eql(results_report_path(report))
    end
  end
end