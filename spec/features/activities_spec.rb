require 'spec_helper'

feature 'Activities management' do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:permissions) { [] }
  let(:event) { FactoryGirl.create(:late_event, campaign: campaign, company: company, place: place) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after do
    AttachedAsset.destroy_all
    Warden.test_reset!
  end


  shared_examples_for 'a user that view the activiy details' do
    let(:activity) { FactoryGirl.create(:activity,
        company_user: company_user, activitable: event,
        activity_type: FactoryGirl.create(:activity_type, name: 'Test ActivityType', company: company, campaign_ids: [campaign.id])) }

    scenario "can see all the activity info", js: true do
      visit activity_path(activity)
      expect(page).to have_selector('h2.special', text: 'Test ActivityType')
      expect(current_path).to eql activity_path(activity)
    end

    scenario "clicking on the close details bar should send the user to the event details view", js: true do
      visit activity_path(activity)
      click_link 'You are viewing activity details. Click to close.'
      expect(current_path).to eql event_path(event)
    end

    scenario "can see all the info of a venue's activity", js: true do
      venue = FactoryGirl.create(:venue, place: place)
      venue_activity = FactoryGirl.create(:activity,
        company_user: company_user, activitable: venue,
        campaign: campaign,
        activity_type: FactoryGirl.create(:activity_type, name: 'Test ActivityType', company: company, campaign_ids: [campaign.id]))
      visit activity_path(activity)
      expect(page).to have_selector('h2.special', text: 'Test ActivityType')
      expect(current_path).to eql activity_path(activity)
    end
  end

  feature "admin user", js: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like 'a user that view the activiy details'

    scenario 'should not display the activities section if the campaigns have no activity types assigned' do
      visit event_path(event)
      expect(page).to_not have_css('#event-activities')

      campaign.activity_types << FactoryGirl.create(:activity_type, company: company)

      visit event_path(event)
      expect(page).to have_css('#event-activities')
    end

    scenario 'allows the user to add an activity to an Event, see it displayed in the Activities list and then deactivate it' do
      FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      brand1 = FactoryGirl.create(:brand, name: 'Brand #1')
      brand2 = FactoryGirl.create(:brand, name: 'Brand #2')
      FactoryGirl.create(:marque, name: 'Marque #1 for Brand #2', brand: brand2)
      FactoryGirl.create(:marque, name: 'Marque #2 for Brand #2', brand: brand2)
      FactoryGirl.create(:marque, name: 'Marque alone', brand: brand1)
      campaign.brands << brand1
      campaign.brands << brand2

      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      FactoryGirl.create(:form_field, name: 'Brand', type: 'FormField::Brand', fieldable: activity_type, ordering: 1)
      FactoryGirl.create(:form_field, name: 'Marque', type: 'FormField::Marque', fieldable: activity_type, ordering: 2, settings: {'multiple' => true})
      FactoryGirl.create(:form_field, name: 'Form Field #1', type: 'FormField::Number', fieldable: activity_type, ordering: 3)
      dropdown_field = FactoryGirl.create(:form_field, name: 'Form Field #2', type: 'FormField::Dropdown', fieldable: activity_type, ordering: 4)
      FactoryGirl.create(:form_field_option, name: 'Dropdown option #1', form_field: dropdown_field, ordering: 1)
      FactoryGirl.create(:form_field_option, name: 'Dropdown option #2', form_field: dropdown_field, ordering: 2)

      campaign.activity_types << activity_type

      visit event_path(event)

      expect(page).to_not have_content('Activity Type #1')

      click_js_link('New Activity')

      within visible_modal do
        select_from_chosen('Activity Type #1', from: 'Activity type')
        select_from_chosen('Brand #2', from: 'Brand')
        wait_for_ajax
        select2("Marque #1 for Brand #2", from: "Marque")
        fill_in 'Form Field #1', with: '122'
        select_from_chosen('Dropdown option #2', from: 'Form Field #2')
        select_from_chosen('Juanito Bazooka', from: 'User')
        fill_in 'Date', with: '05/16/2013'
        click_js_button 'Create'
      end

      ensure_modal_was_closed

      within('#activities-list li') do
        expect(page).to have_content('Juanito Bazooka')
        expect(page).to have_content('THU May 16')
        expect(page).to have_content('Activity Type #1')
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this activity?'

      within("#activities-list") do
        expect(page).to have_no_selector('li')
      end
    end

    scenario 'allows the user to edit an activity from an Event' do
      FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      brand = FactoryGirl.create(:brand, name: 'Unique Brand')
      FactoryGirl.create(:marque, name: 'Marque #1 for Brand', brand: brand)
      FactoryGirl.create(:marque, name: 'Marque #2 for Brand', brand: brand)
      campaign.brands << brand

      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      campaign.activity_types << activity_type

      activity = FactoryGirl.create(:activity,
        activity_type: activity_type,
        activitable: event,
        campaign: campaign,
        company_user: company_user,
        activity_date: "08/21/2014"
      )

      visit event_path(event)

      hover_and_click("#activities-list #activity_#{activity.id}", 'Edit')

      within visible_modal do
        select_from_chosen('Juanito Bazooka', from: 'User')
        fill_in 'Date', with: '05/16/2013'
        click_js_button 'Save'
      end

      ensure_modal_was_closed

      within('#activities-list li') do
        expect(page).to have_content('Juanito Bazooka')
        expect(page).to have_content('THU May 16')
        expect(page).to have_content('Activity Type #1')
      end
    end

    scenario 'allows the user to add an activity to a Venue, see it displayed in the Activities list and then deactivate it' do
      venue = FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil))
      FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      campaign = FactoryGirl.create(:campaign, name: 'Campaign #1', company: company)
      brand1 = FactoryGirl.create(:brand, name: 'Brand #1', company: company)
      brand2 = FactoryGirl.create(:brand, name: 'Brand #2', company: company)
      FactoryGirl.create(:marque, name: 'Marque #1 for Brand #2', brand: brand2)
      FactoryGirl.create(:marque, name: 'Marque #2 for Brand #2', brand: brand2)
      FactoryGirl.create(:marque, name: 'Marque alone', brand: brand1)
      campaign.brands << brand1
      campaign.brands << brand2

      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      FactoryGirl.create(:form_field, name: 'Brand', type: 'FormField::Brand', fieldable: activity_type, ordering: 1)
      FactoryGirl.create(:form_field, name: 'Marque', type: 'FormField::Marque', fieldable: activity_type, ordering: 2, settings: {'multiple' => true})
      FactoryGirl.create(:form_field, name: 'Form Field #1', type: 'FormField::Number', fieldable: activity_type, ordering: 3)
      dropdown_field = FactoryGirl.create(:form_field, name: 'Form Field #2', type: 'FormField::Dropdown', fieldable: activity_type, ordering: 4)
      FactoryGirl.create(:form_field_option, name: 'Dropdown option #1', form_field: dropdown_field, ordering: 1)
      FactoryGirl.create(:form_field_option, name: 'Dropdown option #2', form_field: dropdown_field, ordering: 2)

      campaign.activity_types << activity_type

      visit venue_path(venue)

      expect(page).to_not have_content('Activity Type #1')

      click_js_link('New Activity')

      within visible_modal do
        select_from_chosen('Activity Type #1', from: 'Activity type')
        select_from_chosen('Campaign #1', from: 'Campaign')
        select_from_chosen('Brand #2', from: 'Brand')
        select2("Marque #1 for Brand #2", from: "Marque")
        fill_in 'Form Field #1', with: '122'
        select_from_chosen('Dropdown option #2', from: 'Form Field #2')
        select_from_chosen('Juanito Bazooka', from: 'User')
        fill_in 'Date', with: '05/16/2013'
        click_js_button 'Create'
      end

      ensure_modal_was_closed

      within('#activities-list li') do
        expect(page).to have_content('Juanito Bazooka')
        expect(page).to have_content('THU May 16')
        expect(page).to have_content('Activity Type #1')
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this activity?'

      within("#activities-list") do
        expect(page).to have_no_selector('li')
      end
    end

    scenario "user can insert data for percentage fields" do
      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      form_field = FactoryGirl.create(:form_field,
        fieldable: activity_type, type: 'FormField::Percentage',
        options: [FactoryGirl.create(:form_field_option, name: 'Option 1', ordering: 0), FactoryGirl.create(:form_field_option, name: 'Option 2', ordering: 1)])


      campaign.activity_types << activity_type

      visit event_path(event)

      click_js_link('New Activity')

      within visible_modal do
        select_from_chosen('Activity Type #1', from: 'Activity type')
        fill_in 'Option 1', with: '10'
        fill_in 'Option 2', with: '90'
        select_from_chosen(user.name, from: 'User')
        fill_in 'Date', with: '05/16/2013'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      within('#activities-list li') do
        expect(page).to have_content(user.name)
        expect(page).to have_content('THU May 16')
        expect(page).to have_content('Activity Type #1')
        click_js_link('Edit')
      end

      within visible_modal do
        expect(find_field('Option 1').value).to eql '10'
        expect(find_field('Option 2').value).to eql '90'
      end
    end

    scenario "user can attach a photo to an activity" do
      allow_any_instance_of(AttachedAsset).to receive(:save_attached_files).and_return(true)
      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      form_field = FactoryGirl.create(:form_field,
        fieldable: activity_type, type: 'FormField::Photo')

      campaign.activity_types << activity_type

      with_resque do # So the image is processed
        visit event_path(event)

        click_js_link('New Activity')

        within visible_modal do
          select_from_chosen('Activity Type #1', from: 'Activity type')

          # Should validate the type of the image
          attach_file "file", 'spec/fixtures/file.pdf'
          expect(page).to have_content('is not a valid file')

          attach_file "file", 'spec/fixtures/photo.jpg'
          expect(page).to have_content('Uploading photo.jpg....')
          expect(page).to have_no_content('is not a valid file')
          wait_for_ajax(30) # For the image to upload to S3
          expect(page).to have_content('File attached: photo.jpg')

          select_from_chosen(user.name, from: 'User')
          fill_in 'Date', with: '05/16/2013'
          wait_for_photo_to_process 30 do
            click_js_button 'Create'
          end
        end
        ensure_modal_was_closed

        within('#activities-list li') do
          expect(page).to have_content(user.name)
          expect(page).to have_content('THU May 16')
          expect(page).to have_content('Activity Type #1')
        end

        activity = Activity.last
        photo = AttachedAsset.last
        expect(photo.attachable).to be_a FormFieldResult
        expect(photo.file_file_name).to eql 'photo.jpg'

        # Change the photo
        within('#activities-list li') do
          click_js_link('Edit')
        end
        within visible_modal do
          expect(page).to have_content('File attached: photo.jpg')
          click_js_link('Change')
          attach_file "file", 'spec/fixtures/photo2.jpg'
          expect(page).to have_content('Uploading photo2.jpg....')
          wait_for_ajax(30) # For the image to upload to S3
          expect(page).to have_content('File attached: photo2.jpg')
          wait_for_photo_to_process 30 do
            click_js_button 'Save'
          end
        end
        ensure_modal_was_closed

        within("#activities-list li") do
          click_js_link('Activity Details')
        end
        expect(page).to have_selector('h2', text: 'Activity Type #1')
        expect(current_path).to eql activity_path(activity)
        photo = AttachedAsset.last
        src = photo.reload.file.url(:thumbnail, timestamp: false)
        expect(page).to have_xpath("//img[starts-with(@src, \"#{src}\")]")
      end
    end

    scenario "user can attach a document to an activity" do
      allow_any_instance_of(AttachedAsset).to receive(:save_attached_files).and_return(true)
      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      form_field = FactoryGirl.create(:form_field,
        fieldable: activity_type, type: 'FormField::Attachment')


      campaign.activity_types << activity_type

      with_resque do # So the document is processed
        visit event_path(event)

        click_js_link('New Activity')

        within visible_modal do
          select_from_chosen('Activity Type #1', from: 'Activity type')

          attach_file "file", 'spec/fixtures/file.pdf'
          expect(page).to have_content('Uploading file.pdf....')
          expect(page).to have_no_content('is not a valid file')
          wait_for_ajax(30) # For the file to upload to S3
          expect(page).to have_content('File attached: file.pdf')

          select_from_chosen(user.name, from: 'User')
          fill_in 'Date', with: '05/16/2013'
          wait_for_photo_to_process 30 do
            click_js_button 'Create'
          end
        end
        ensure_modal_was_closed

        within('#activities-list li') do
          expect(page).to have_content(user.name)
          expect(page).to have_content('THU May 16')
          expect(page).to have_content('Activity Type #1')
        end

        activity = Activity.last
        photo = AttachedAsset.last
        expect(photo.attachable).to be_a FormFieldResult
        expect(photo.file_file_name).to eql 'file.pdf'

        within("#activities-list li") do
          click_js_link('Activity Details')
        end
        expect(page).to have_selector('h2', text: 'Activity Type #1')
        expect(current_path).to eql activity_path(activity)
        file = AttachedAsset.last
        src = file.reload.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
        expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]")

        visit event_path(event)

        # Remove the file
        within('#activities-list li') do
          click_js_link('Edit')
        end
        expect{
          within visible_modal do
            expect(page).to have_content('File attached: file.pdf')
            click_js_link('Remove')
            expect(page).to have_no_content('File attached')
            click_js_button 'Save'
            wait_for_ajax(30) # To wait for the file being deleted from S3
          end
          ensure_modal_was_closed
        }.to change(AttachedAsset, :count).by(-1)

      end
    end

    scenario 'activities from events should be displayed within the venue' do
      event_activity = FactoryGirl.create(:activity,
        company_user: company_user, activitable: event,
        activity_type: FactoryGirl.create(:activity_type, name: 'Test ActivityType', company: company, campaign_ids: [campaign.id]))

      visit venue_path(event.venue)

      within('#activities-list') do
        expect(page).to have_content('Test ActivityType')
      end
    end

    scenario 'allows the user to edit an activity from a Venue' do
      venue = FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil))
      FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      campaign = FactoryGirl.create(:campaign, name: 'Campaign #1', company: company)
      brand = FactoryGirl.create(:brand, name: 'Unique Brand')
      FactoryGirl.create(:marque, name: 'Marque #1 for Brand', brand: brand)
      FactoryGirl.create(:marque, name: 'Marque #2 for Brand', brand: brand)
      campaign.brands << brand

      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
      campaign.activity_types << activity_type

      activity = FactoryGirl.create(:activity,
        activity_type: activity_type,
        activitable: venue,
        campaign: campaign,
        company_user: company_user,
        activity_date: "08/21/2014"
      )

      visit venue_path(venue)

      hover_and_click("#activities-list #activity_#{activity.id}", 'Edit')

      within visible_modal do
        select_from_chosen('Juanito Bazooka', from: 'User')
        fill_in 'Date', with: '05/16/2013'
        click_js_button 'Save'
      end

      ensure_modal_was_closed

      within('#activities-list li') do
        expect(page).to have_content('Juanito Bazooka')
        expect(page).to have_content('THU May 16')
        expect(page).to have_content('Activity Type #1')
      end
    end
  end

  feature "non admin user", js: true, search: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that view the activiy details" do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [[:show, 'Activity'], [:show, 'Event']] }
    end
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create({action: p[0], subject_class: p[1]}, without_protection: true)
    end
  end
end