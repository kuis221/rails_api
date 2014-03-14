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
          wait_for_ajax(30) # For the image to upload to S3
          find('#btn-upload-ok').click
        end
        ensure_modal_was_closed

        photo = AttachedAsset.last
        # Check that the image appears on the page
        within gallery_box do
          src = photo.file.url(:thumbnail, timestamp: false)
          expect(page).to have_xpath("//img[starts-with(@src, \"#{src}\")]", wait: 10)
        end
      end
    end

    scenario "A user can deactivate a photo" do
      photo = FactoryGirl.create(:photo, attachable: event)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        expect(page).to have_selector('li')
        hover_and_click 'li', 'Deactivate'
      end

      confirm_prompt "Are you sure you want to deactivate this photo?"
      expect(gallery_box).to have_no_selector('li')
    end
  end

  feature "Photo Gallery" do
    let(:event) { FactoryGirl.create(:late_event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company, form_fields_attributes: {"0" => {"ordering"=>"5", "name"=>"Photos", "field_type"=>"photos", "kpi_id"=> Kpi.photos.id}})) }

    scenario "can rate a photo" do
      photo = FactoryGirl.create(:photo, attachable: event, rating: 2)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        expect(page).to have_selector('li')
        click_js_link 'View Photo'
      end

      within gallery_modal do
        find('.rating span.full', match: :first)
        expect(page.all(".rating span.full").count).to eql(2)
        expect(page.all(".rating span.empty").count).to eql(3)
        find('.rating span:nth-child(3)').trigger('click')
        wait_for_ajax
        expect(photo.reload.rating).to eql 3
        click_button 'Close'
      end
      ensure_modal_was_closed

      # Close the modal and reopened and make sure the stars are correctly
      # highlithed
      within gallery_box do
        click_js_link 'View Photo'
      end
      within gallery_modal do
        find('.rating span.full', match: :first)
        expect(page.all(".rating span.full").count).to eql(3)
        expect(page.all(".rating span.empty").count).to eql(2)
      end
    end

    scenario "a user can deactivate a photo" do
      FactoryGirl.create(:photo, attachable: event)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        expect(page).to have_selector('li')
        click_js_link 'View Photo'
      end

      # Deactivate the image from the link inside the gallery modal
      within gallery_modal do
        expect(page).to have_selector('a.photo-deactivate-link')
        click_js_link 'Deactivate'
      end

      confirm_prompt "Are you sure you want to deactivate this photo?"

      within gallery_modal do
        expect(page).to have_no_selector('a.photo-deactivate-link')
      end

      expect(gallery_box).to have_no_selector('a.photo-deactivate-link')
    end

    scenario "a user can activate a photo" do
      #This should be done from Photo Results section
      event = FactoryGirl.create(:approved_event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company, form_fields_attributes: {"0" => {"ordering"=>"5", "name"=>"Photos", "field_type"=>"photos", "kpi_id"=> Kpi.photos.id}}))
      FactoryGirl.create(:photo, attachable: event, active: false)
      event.save

      Sunspot.commit

      visit results_photos_path

      filter_section('STATUS').unicheck('Inactive')

      # Check that the image appears on the page
      within find('.gallery.photoGallery') do
        expect(page).to have_selector('li')
        click_js_link 'View Photo'
      end

      # Activate the image from the link inside the gallery modal
      within gallery_modal do
        expect(page).to have_selector('a.icon-ok-circle')
        click_js_link 'Activate'
        expect(page).to have_no_selector('a.icon-remove-circle')
      end
    end
  end

  def gallery_box
    find('.details_box.box_photos')
  end

  def upload_queue
    find('#uploads_container')
  end

  def gallery_modal
    find('.gallery-modal')
  end

end