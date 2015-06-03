require 'rails_helper'

feature 'Trending report' do
  let(:company) { create(:company) }
  let(:activity_type) { create(:activity_type, company: company, name: 'Whiskey Survey') }
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
      click_button 'Next'

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
      page.driver.add_header("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36")
      event = create(:late_event, campaign: campaign, place: place)
      create(:form_field_text,
             fieldable: campaign, name: 'My Text Field')
      create(:form_field_text_area,
             fieldable: campaign, name: 'My Paragraph Field')

      visit event_path(event)

      fill_in 'My Text Field', with: 'Texto con hola en medio!'
      fill_in 'My Paragraph Field', with: 'hola mundo'
      click_js_button 'Save'

      expect(page).to have_selector('.form-result-value', text: 'hola mundo')

      visit sources_analysis_trends_path

      select_from_chosen(campaign.name, from: '1. Choose one or more campaigns')
      select_from_chosen('Comments', from: '2. Choose one or more data sources within those campaigns')
      click_button 'Next'

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

      expect(page).to have_selector('h2', text: 'Hola')
      expect(current_path).to eql '/analysis/trends/t/hola'
    end

    scenario 'can see the bubbles with the most popular words in activity types fields' do
      event = create(:late_event, campaign: campaign, place: place)
      create(:form_field_text,
             fieldable: activity_type, name: 'My Text Field')
      create(:form_field_text_area,
             fieldable: activity_type, name: 'My Paragraph Field')
      campaign.activity_types << activity_type

      visit event_path(event)

      click_js_button('Add Activity')

      within visible_modal do
        choose 'Whiskey Survey'
        click_js_button 'Create'
      end

      fill_in 'My Text Field', with: 'Texto con hola en medio!'
      fill_in 'My Paragraph Field', with: 'hola mundo'
      select_from_chosen(user.full_name, from: 'User')
      fill_in 'Date', with: '05/16/2013'
      click_js_button 'Submit'

      expect(page).to have_content 'Thank You!'

      visit sources_analysis_trends_path

      select_from_chosen(campaign.name, from: '1. Choose one or more campaigns')
      select_from_chosen('Whiskey Survey', from: '2. Choose one or more data sources within those campaigns')
      click_button 'Next'

      expect(page).to have_text 'QUESTIONS'
      unicheck 'My Text Field'
      unicheck 'My Paragraph Field'
      expect(current_path).to eql(questions_analysis_trends_path)

      click_button 'Done'

      expect(page).to have_filter_section(
        title: 'SOURCE',
        options: ['Whiskey Survey'])
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

      expect(page).to have_selector('h2', text: 'Hola')
      expect(current_path).to eql '/analysis/trends/t/hola'
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
         [:show, 'Activity'], [:create, 'Activity'],
         [:edit_unsubmitted_data, 'Event'], [:view_submitted_data, 'Event']]
      end
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
