require 'rails_helper'

feature "Brand Ambassadors Documents", js: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
    Company.current = company
  end

  after do
    Warden.test_reset!
  end

  feature "Global Brand Ambassador documents" do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }
    let(:permissions) { [[:create, 'BrandAmbassadors::Document'], [:index, 'BrandAmbassadors::Document']] }

    scenario "A user can upload a document to the Brand Ambassadors section" do
      with_resque do
        visit brand_ambassadors_root_path

        documents_section.click_js_link 'Add Documents'

        within visible_modal do
          attach_file "file", 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          find('#btn-upload-ok').click
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last
        # Check that the image appears on the page
        within documents_section do
          src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
        end
      end
    end
  end

  def documents_section
    find('#brand-ambassador-documents')
  end

  def upload_queue
    find('#uploads_container')
  end
end
