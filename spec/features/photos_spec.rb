require 'rails_helper'

feature 'Photos', js: true do
  let(:company) { create(:company) }
  let(:role) { create(:role, company: company) }
  let(:user) { create(:user, company_id: company.id, role_id: role.id) }
  let(:campaign) { create(:campaign, company: company, modules: { 'photos' => {} }) }
  let(:event) { create(:late_event, company: company, campaign: campaign) }

  before do
    Warden.test_mode!
    sign_in user
    Kpi.create_global_kpis
  end

  after do
    AttachedAsset.destroy_all
    Warden.test_reset!
  end

  feature 'Event Photo management' do
    scenario 'A user can select a photo and attach it to the event' do
      with_resque do
        visit event_path(event)

        gallery_box.click_js_button 'Add Photos'

        within visible_modal do
          attach_file 'file', 'spec/fixtures/photo.jpg'
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

    scenario 'A user can deactivate a photo' do
      photo = create(:photo, attachable: event)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        expect(page).to have_selector('li')
        hover_and_click 'li', 'Deactivate'
      end

      confirm_prompt 'Are you sure you want to deactivate this photo?'
      expect(gallery_box).to have_no_selector('li')
    end
  end

  feature 'Photo Gallery' do
    scenario 'can rate a photo' do
      photo = create(:photo, attachable: event, rating: 2)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        expect(page).to have_selector('li')
        click_js_link 'View Photo'
      end

      within gallery_modal do
        find('.rating span.full', match: :first)
        expect(page.all('.rating span.full').count).to eql(2)
        expect(page.all('.rating span.empty').count).to eql(3)
        find('.rating span:nth-child(3)').trigger('click')
        wait_for_ajax
        expect(photo.reload.rating).to eql 3
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      # Close the modal and reopened and make sure the stars are correctly
      # highlithed
      within gallery_box do
        click_js_link 'View Photo'
      end
      within gallery_modal do
        find('.rating span.full', match: :first)
        expect(page.all('.rating span.full').count).to eql(3)
        expect(page.all('.rating span.empty').count).to eql(2)
      end
    end

    scenario 'a user can deactivate a photo' do
      create(:photo, attachable: event)
      visit event_path(event)

      # Check that the image appears on the page
      within gallery_box do
        expect(page).to have_selector('li')
        click_js_link 'View Photo'
      end

      # Deactivate the image from the link inside the gallery modal
      within gallery_modal do
        hover_and_click('.slider', 'Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this photo?'

      within gallery_modal do
        expect(page).to have_no_selector('a.photo-deactivate-link')
      end

      expect(gallery_box).to have_no_selector('a.photo-deactivate-link')
    end

    scenario 'a user can activate a photo', search: true do
      # This should be done from Photo Results section
      create(:photo, attachable: event, active: false)
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
        find('.slider').hover
        within '.slider' do
          click_js_link 'Activate'
          expect(page).not_to have_link('Activate')
          expect(page).to have_link('Deactivate')
        end
      end
    end

    scenario 'a user can tag photos' do
      create(:photo, attachable: event)
      visit event_path(event)

      within gallery_box do
        click_js_link 'View Photo'
      end

      within gallery_modal do
        select2_add_tag 'Add tags', 'tag1'
        expect(find('.tags .list')).to have_content 'tag1'

        click_js_link 'Close'
      end

      within gallery_box do
        click_js_link 'View Photo'
      end

      within gallery_modal do
        within find('.tags .list .tag') do
          expect(page).to have_content 'tag1'
          click_js_link 'Remove Tag'
          wait_for_ajax
        end
      end

      within gallery_modal do
        expect(page).to have_no_content 'tag1'
        click_js_link 'Close'
      end

      within gallery_box do
        click_js_link 'View Photo'
      end

      within gallery_modal do
        expect(find('.tags .list')).to have_no_content 'tag1'
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
