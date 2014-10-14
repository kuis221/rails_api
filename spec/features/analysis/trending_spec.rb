require 'rails_helper'

feature 'Trending report' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) do
    create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat',
      state: 'San Jose', is_custom_place: true, reference: nil)
  end
  let(:permissions) { [] }
  let(:event) { create(:approved_event, campaign: campaign, company: company, place: place) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can view the trending report' do
    scenario 'can see the bubbles with the most popular words in comments' do
      campaign.modules = { 'comments' => {} }
      expect(campaign.save).to be_truthy
      visit event_path(event)

      add_comment 'hola mundo'
      add_comment 'Costa Rica es el pais mas feliz del mundo'
      add_comment 'Copa del mundo Brasil 2014'

      Sunspot.commit

      visit sources_analysis_trends_path

      select_from_chosen(campaign.name, from: '1. Choose one or more campaigns')
      select_from_chosen('Comments', from: '2. Choose one or more data sources within those campaigns')
      click_button 'Done'

      expect(page).to have_text 'QUESTIONS'
      expect(current_path).to eql(questions_analysis_trends_path)

      click_button 'Done'

      expect(page).to have_filter_section(
        title: 'SOURCE',
        options: ['Comments'])
      expect(find('input[name="source[]"][value="Comment"]', visible: false)).to be_checked

      expect(page).to have_selector('a.bubble-label', text: 'mundo 3')
      expect(page).to have_selector('a.bubble-label', text: 'costa 1')
      expect(page).to have_selector('a.bubble-label', text: 'rica 1')
      expect(page).to have_selector('a.bubble-label', text: 'copa 1')
      expect(page).to have_selector('a.bubble-label', text: 'hola 1')

      # Deletes a word from the cloud
      delete_bubble 'costa 1'

      find('a.bubble-label', text: 'mundo 3').trigger('click')

      expect(page).to have_selector('h2', text: 'Mundo')
      expect(current_path).to eql '/analysis/trends/t/mundo'
    end

    scenario 'can see the bubbles with the most popular words in event data fields' do
      event = create(:late_event, campaign: campaign, place: place)
      create(:form_field_text,
             fieldable: campaign, name: 'My Text Field')
      create(:form_field_text_area,
             fieldable: campaign, name: 'My Paragraph Field')

      visit event_path(event)

      fill_in 'My Text Field', with: 'Texto con hola en medio!'
      fill_in 'My Paragraph Field', with: 'hola mundo'
      click_button 'Save'

      expect(page).to have_selector('.form-result-value', text: 'hola mundo')

      visit sources_analysis_trends_path

      select_from_chosen(campaign.name, from: '1. Choose one or more campaigns')
      select_from_chosen('Comments', from: '2. Choose one or more data sources within those campaigns')
      click_button 'Done'

      expect(page).to have_text 'QUESTIONS'
      unicheck 'My Text Field'
      unicheck 'My Paragraph Field'
      expect(current_path).to eql(questions_analysis_trends_path)

      click_button 'Done'

      expect(page).to have_filter_section(
        title: 'QUESTIONS',
        options: ['My Paragraph Field', 'My Text Field'])
      expect(find_field('My Text Field', visible: false)).to be_checked
      expect(find_field('My Paragraph Field', visible: false)).to be_checked

      expect(page).to have_selector('a.bubble-label', text: 'hola 2')
      expect(page).to have_selector('a.bubble-label', text: 'texto 1')
      expect(page).to have_selector('a.bubble-label', text: 'medio 1')
      expect(page).to have_selector('a.bubble-label', text: 'mundo 1')

      # Deletes a word from the cloud
      delete_bubble 'medio 1'

      find('a.bubble-label', text: 'hola 2').click

      expect(current_path).to eql '/analysis/trends/t/hola'

      expect(page).to have_selector('h2', text: 'Hola')
    end
  end

  feature 'admin user', js: true, search: true do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can view the trending report'
  end

  feature 'non admin user', js: true, search: true do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can view the trending report' do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) do
        [[:access, 'Symbol', 'trends_report'], [:show, 'Event'],
         [:index_comments, 'Event'], [:create_comment, 'Event'],
         [:edit_unsubmitted_data, 'Event'], [:view_submitted_data, 'Event']]
      end
    end
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create(action: p[0], subject_class: p[1])
    end
  end

  def delete_bubble(text)
    find('a.bubble-label', text: text).hover
    click_js_link('Remove this word')
    expect(page).to have_no_selector('a.bubble-label', text: text)
  end

  def add_comment(text)
    click_js_button 'Add Comment'
    within visible_modal do
      fill_in 'comment[content]', with: text
      click_js_button 'Create'
    end
    ensure_modal_was_closed
    within '.event-comments-list' do
      expect(page).to have_content(text)
    end
  end
end
