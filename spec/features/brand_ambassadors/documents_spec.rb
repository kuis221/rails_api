require 'rails_helper'

feature 'Brand Ambassadors Documents', js: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
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

  feature 'Global Brand Ambassador documents' do
    let(:role) { create(:non_admin_role, company: company) }
    let(:permissions) { [[:create, 'BrandAmbassadors::Document'], [:index, 'BrandAmbassadors::Document']] }

    scenario 'A user can upload a document to the Brand Ambassadors section' do
      with_resque do
        visit brand_ambassadors_root_path

        documents_section.click_button 'Upload'

        within visible_modal do
          attach_file 'file', 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last

        # Check that the document appears is in the document list
        expect_to_have_document_in_list document

        expect(document.attachable).to eql(company)

        # Make sure the document is still there after reloading page
        visit current_path
        # Check that the image appears on the page
        within documents_section do
          src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
        end

        # Delete the document
        within documents_section do
          hover_and_click 'li.document', 'Delete'
        end
        confirm_prompt 'Are you sure you want to delete this document?'

        # Check that the document was removed
        within documents_section do
          expect(page).not_to have_selector 'li.document'
        end
      end
    end

    scenario 'A user can modify the name of a document placed in the Brand Ambassadors section' do
      with_resque do
        visit brand_ambassadors_root_path

        documents_section.click_button 'Upload'

        within visible_modal do
          attach_file 'file', 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last

        expect(document.file_file_name).to eql('file.pdf')

        # Modify the name of the document
        within documents_section do
          hover_and_click 'li.document', 'Edit'
        end

        within visible_modal do
          fill_in 'Document name', with: 'renamed.pdf'
          click_js_button 'Save'
          wait_for_ajax(30) # For the file to be modified at S3
        end
        ensure_modal_was_closed

        document.reload
        expect(document.file_file_name).to eql('renamed.pdf')

        within documents_section do
          expect(page).to have_content('renamed')
        end

        dirname = File.dirname(document.file.path(:original).sub(%r{\A/}, ''))
        expect(document.file.s3_bucket.objects["#{dirname}/file.pdf"].exists?).to be_falsey
        expect(document.file.s3_bucket.objects["#{dirname}/renamed.pdf"].exists?).to be_truthy
      end
    end

    scenario 'A user can create folders with duplicate names' do
      visit brand_ambassadors_root_path

      documents_section.click_js_link 'New Folder'

      within documents_section do
        fill_in 'Please name your folder', with: 'Duplicate Folder Name'
        page.execute_script("$('form#new_document_folder').submit()")
        wait_for_ajax
        expect(page).to have_selector('ul#documents-list li.document', count: 1)
      end

      documents_section.click_js_link 'New Folder'

      within documents_section do
        fill_in 'Please name your folder', with: 'Duplicate Folder Name'
        page.execute_script("$('form#new_document_folder').submit()")
        wait_for_ajax
        expect(page).to have_selector('ul#documents-list li.document', count: 2)
      end
    end

    scenario 'A user can create and deactivate folders' do
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

      # Upload a document to the folder
      open_folder 'New Folder Name'
      documents_section.click_button 'Upload'

      within visible_modal do
        attach_file 'file', 'spec/fixtures/file.pdf'
        expect(upload_queue).to have_file_in_queue('file.pdf')
        wait_for_ajax(30) # For the file to upload to S3
        click_js_link 'OK'
      end
      ensure_modal_was_closed

      # Check that the document appears is in the document list
      document = BrandAmbassadors::Document.last
      expect_to_have_document_in_list document

      # Go to the root documents folder
      open_root_folder
      expect(page).not_to have_content(document.name)

      # Open the folder again and check the document is there
      open_folder 'New Folder Name'
      expect_to_have_document_in_list document
      open_root_folder

      # Deactivate the folder
      within documents_section do
        hover_and_click '.document', 'Deactivate'
      end
      confirm_prompt 'Are you sure you want to deactivate this folder?'

      # Check that the folder was removed
      within documents_section do
        expect(page).not_to have_content folder.name
      end
    end

    scenario 'A user can move documents to another folder' do
      with_resque do
        visit brand_ambassadors_root_path

        documents_section.click_js_link 'New Folder'

        within documents_section do
          fill_in 'Please name your folder', with: 'My Folder'
          page.execute_script("$('form#new_document_folder').submit()")
          expect(page).to have_link('My Folder')
        end

        documents_section.click_button 'Upload'
        within visible_modal do
          expect(page).to have_content 'New Document'
          attach_file 'file', 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last
        folder = DocumentFolder.last
        hover_and_click "#brand_ambassadors_document_#{document.id}", 'Move'

        within visible_modal do
          find('label.radio', text: 'My Folder').click
          click_js_button 'Move'
        end
        ensure_modal_was_closed
        expect(document.reload.folder_id).to eql folder.id
        expect(page).not_to have_content 'file'

        # open the folder
        within documents_section do
          click_js_link 'Open Folder'
        end

        expect(page).to have_content 'file'
      end
    end
  end

  feature 'Brand Ambassador Visit documents' do
    let(:role) { create(:non_admin_role, company: company) }
    let(:permissions) { [[:create, 'BrandAmbassadors::Document'], [:index, 'BrandAmbassadors::Document'], [:show, 'BrandAmbassadors::Visit']] }
    let(:ba_visit) do
      create(:brand_ambassadors_visit, campaign: campaign,
        company: company, company_user: company_user)
    end

    scenario 'A user can upload a document to a brand ambassador visit' do
      with_resque do
        visit brand_ambassadors_visit_path(ba_visit)

        documents_section.click_button 'Upload'

        within visible_modal do
          expect(page).to have_content 'New Document'
          attach_file 'file', 'spec/fixtures/file.pdf'
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

    scenario 'A user can modify the name of a document placed in brand ambassadors visit' do
      with_resque do
        visit brand_ambassadors_visit_path(ba_visit)

        documents_section.click_button 'Upload'

        within visible_modal do
          attach_file 'file', 'spec/fixtures/file.pdf'
          expect(upload_queue).to have_file_in_queue('file.pdf')
          wait_for_ajax(30) # For the file to upload to S3
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        document = BrandAmbassadors::Document.last

        expect(document.file_file_name).to eql('file.pdf')

        # Modify the name of the document
        within documents_section do
          hover_and_click 'li.document', 'Edit'
        end

        within visible_modal do
          fill_in 'Document name', with: 'renamed.pdf'
          click_js_button 'Save'
          wait_for_ajax(30) # For the file to be modified at S3
        end
        ensure_modal_was_closed

        document.reload
        expect(document.file_file_name).to eql('renamed.pdf')

        within documents_section do
          expect(page).to have_content('renamed')
        end

        dirname = File.dirname(document.file.path(:original).sub(%r{\A/}, ''))
        expect(document.file.s3_bucket.objects["#{dirname}/file.pdf"].exists?).to be_falsey
        expect(document.file.s3_bucket.objects["#{dirname}/renamed.pdf"].exists?).to be_truthy
      end
    end

    scenario 'A user can create and deactivate folders' do
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
      confirm_prompt 'Are you sure you want to deactivate this folder?'

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

  def open_folder(name)
    within documents_section do
      click_js_link name
    end
    expect(documents_section.find('h3')).to have_content(name)
  end

  def expect_to_have_document_in_list(document)
    within documents_section do
      src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
      expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
    end
  end

  def open_root_folder
    documents_section.click_js_link('DOCUMENTS')
  end
end
