require 'spec_helper'

feature 'Events section' do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { FactoryGirl.create(:event, campaign: campaign, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can attach expenses to events' do
    let(:event) { FactoryGirl.create(:event,
          start_date: "08/21/2013", end_date: "08/21/2013",
          start_time: '10:00am', end_time: '11:00am',
          campaign: campaign, active: true, place: place) }

    before do
      Kpi.create_global_kpis
      event.campaign.update_attribute :enabled_modules, ['expenses']
    end
    scenario "can attach a expense to event" do
      with_resque do # So the document is processed
        visit event_path(event)

        click_js_link 'Add Expense'

        within visible_modal do
          attach_file "file", 'spec/fixtures/file.pdf'

          # Test validations
          click_js_button 'Save'
          expect(find_field('Name')).to have_error('This field is required.')

          fill_in 'Name', with: 'test expense'
          expect(page).to have_content('File attached: file.pdf')

          wait_for_photo_to_process 15 do
            click_js_button 'Save'
          end
        end
        ensure_modal_was_closed

        within '.details_box.box_expenses' do
          expect(page).to have_content('test expense')
        end
        asset = AttachedAsset.last
        expect(asset.file_file_name).to eql 'file.pdf'

        # Test user can preview and download the receipt
        within '.details_box.box_expenses' do
          click_js_link 'View Receipt'
        end

        within visible_modal do
          src = asset.file.url(:thumbnail, timestamp: false)
          expect(page).to have_xpath("//img[starts-with(@src, \"#{src}\")]", wait: 10)
          find('.slider').hover

          src = asset.file.url(:original, timestamp: false).gsub('http:', 'https:')
          expect(page).to have_link('Download')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]")
        end
      end
    end
  end


  feature "admin user", js: true, search: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can attach expenses to events"
  end
end