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

        documents_section.click_button 'Upload'

        within visible_modal do
          attach_file "file", 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last
        # Check that the image appears on the page
        within documents_section do
          src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
        end

        expect(document.attachable).to eql(company)

        # Make sure the document is still there after reloading page
        visit current_path
        # Check that the image appears on the page
        within documents_section do
          src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
        end
      end
    end

    scenario "A user can create and deactivate folders" do
      visit brand_ambassadors_root_path

      documents_section.click_js_link 'New Folder'

      within documents_section do
        fill_in 'Please name your folder', with: 'New Folder Name'
        page.execute_script("$('form#new_document_folder').submit()")
        expect(page).to have_link('New Folder Name')
      end

      # Make sure the folder is still there after reloading
      visit current_path
      within documents_section do
        expect(page).to have_link('New Folder Name')
      end

      folder = DocumentFolder.last

      # Deactivate the folder
      within documents_section do
        hover_and_click '.document', 'Deactivate'
      end
      confirm_prompt "Are you sure you want to deactivate this folder?"

      # Check that the folder was removed
      within documents_section do
        expect(page).not_to have_content folder.name
      end
    end
  end

  feature "Brand Ambassador Visit documents" do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }
    let(:permissions) { [[:create, 'BrandAmbassadors::Document'], [:index, 'BrandAmbassadors::Document'], [:show, 'BrandAmbassadors::Visit']] }
    let(:ba_visit) { FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: company_user) }

    scenario "A user can upload a document to a brand ambassador visit" do
      with_resque do
        visit brand_ambassadors_visit_path(ba_visit)

        documents_section.click_button 'Upload'

        within visible_modal do
          expect(page).to have_content 'New Document'
          attach_file "file", 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last
        # Check that the image appears on the page
        within documents_section do
          src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
        end

        expect(document.attachable).to eql(ba_visit)

        # Make sure the document is still there after reloading page
        visit current_path
        # Check that the image appears on the page
        within documents_section do
          src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
        end
      end
    end

    scenario "A user can create and deactivate folders" do
      visit brand_ambassadors_visit_path(ba_visit)

      documents_section.click_js_link 'New Folder'

      within documents_section do
        fill_in 'Please name your folder', with: 'New Folder Name'
        page.execute_script("$('form#new_document_folder').submit()")
        expect(page).to have_link('New Folder Name')
      end

      # Make sure the folder is still there after reloading
      visit current_path
      within documents_section do
        expect(page).to have_link('New Folder Name')
      end

      folder = DocumentFolder.last

      # Deactivate the folder
      within documents_section do
        hover_and_click '.document', 'Deactivate'
      end
      confirm_prompt "Are you sure you want to deactivate this folder?"

      # Check that the folder was removed
      within documents_section do
        expect(page).not_to have_content folder.name
      end
    end
  end

  def documents_section
    find('#documents-container')
  end

  def upload_queue
    find('#uploads_container')
  end
end
