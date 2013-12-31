require 'spec_helper'

feature "Photos", search: true, js: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Kpi.create_global_kpis
  end

  after do
    AttachedAsset.destroy_all
    Warden.test_reset!
  end

  feature "Event Photo management" do
    let(:event) { FactoryGirl.create(:late_event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company, form_fields_attributes: {"0" => {"ordering"=>"5", "name"=>"Photos", "field_type"=>"photos", "kpi_id"=> Kpi.photos.id}})) }
    scenario "A user can select a photo and attach it to the event" do
      with_resque do
        visit event_path(event)

        gallery_box.click_js_link 'Add Photos'

        within visible_modal do
          attach_file "file", 'spec/fixtures/photo.jpg'
          expect(upload_queue).to have_file_in_queue('photo.jpg')
          wait_for_ajax(15) # For the image to upload to S3
          find('#btn-upload-ok').click
        end
        ensure_modal_was_closed

        photo = AttachedAsset.last
        # Check that the image appears on the page
        within gallery_box do
          src = photo.file.url(:small, timestamp: false)
          expect(page).to have_xpath("//img[starts-with(@src, \"#{src}\")]", wait: 10)
        end
      end
    end

    scenario "A user can deactivate a photo" do
      photo = FactoryGirl.create(:photo, attachable: event)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        src = photo.file.url(:small, timestamp: false)
        expect(page).to have_selector('li')
        hover_and_click 'li', 'Deactivate'
      end

      confirm_prompt "Are you sure you want to deactivate this photo?"
      expect(gallery_box).to have_no_selector('li')
    end
  end

  def gallery_box
    find('.details_box.box_photos')
  end

  def upload_queue
    find('#uploads_container')
  end

end