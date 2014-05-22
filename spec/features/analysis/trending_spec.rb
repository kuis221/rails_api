require 'spec_helper'

feature 'Trending report' do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:permissions) { [] }
  let(:event) { FactoryGirl.create(:event, campaign: campaign, company: company, place: place) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can view the trending report' do
    scenario "can see the bubbles with the most popular words" do
      FactoryGirl.create(:comment, commentable: event, content: 'hola mundo')
      FactoryGirl.create(:comment, commentable: event, content: 'Costa Rica es el pais mas feliz del mundo')
      FactoryGirl.create(:comment, commentable: event, content: 'Copa del mundo Brasil 2014')
      Sunspot.commit

      visit analysis_trends_report_index_path

      expect(page).to have_selector('a.bubble-label', text: 'mundo 3')
      expect(page).to have_selector('a.bubble-label', text: 'costa 1')
      expect(page).to have_selector('a.bubble-label', text: 'rica 1')
      expect(page).to have_selector('a.bubble-label', text: 'copa 1')
      expect(page).to have_selector('a.bubble-label', text: 'hola 1')

      # Deletes a word from the cloud
      find('a.bubble-label', text: 'costa 1').hover
      click_js_link('Remove this word')
      expect(page).to have_no_selector('a.bubble-label', text: 'costa 1')


      find('a.bubble-label', text: 'mundo 3').click

      expect(current_path).to eql '/analysis/trends/t/mundo'

      expect(page).to have_selector('h2', text: 'Mundo')
    end
  end

  feature "admin user", js: true, search: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like 'a user that can view the trending report'
  end

  feature "non admin user", js: true, search: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that can view the trending report" do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [[:access, 'Symbol', 'trends_report']] }
    end
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create({action: p[0], subject_class: p[1]}, without_protection: true)
    end
  end
end