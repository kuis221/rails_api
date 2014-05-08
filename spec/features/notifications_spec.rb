require 'spec_helper'

feature "Notifications", search: true, js: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    #Warden.test_mode!
    add_permissions permissions
    #sign_in user
  end

  # after do
  #   Warden.test_reset!
  # end

  shared_examples_for 'a user that can see notifications' do

    it "should receive notifications for new events" do
      visit new_user_session_path

      fill_in('E-mail', with: user.email)
      fill_in('Password', with: user.password)
      click_button 'Login'

      current_path.should == root_path
      expect(page).to have_text(user.full_name)


      without_current_user do
        FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'You have a new event'

      without_current_user{ FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'You have 2 new events'

      click_notification 'You have 2 new events'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)

      visit current_url

      # reload page and make sure that the two events are still there
      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end
  end

  feature "Admin user" do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can see notifications"
  end

  feature "Non Admin User" do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_behaves_like "a user that can see notifications" do
      before { company_user.campaigns << [campaign] }
      before { company_user.places << place }
      let(:permissions) { [[:index, 'Event'],  [:view_list, 'Event']] }
    end
  end

  def click_notification(text)
    if page.all('header li#notifications.open').count == 0
      page.find('header li#notifications a.dropdown-toggle').click
    end

    page.find("#notifications .notifications-container li a", text: text).click
  end
end