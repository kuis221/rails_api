require 'rails_helper'

feature 'Results Comments Page', js: true, search: true  do

  let(:company) { user.companies.first }
  let(:company_user) { user.company_users.first }
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }

  before do
    Kpi.destroy_all
    Warden.test_mode!
    sign_in user
    allow_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  let(:campaign1) { create(:campaign, name: 'First Campaign', company: company) }
  let(:campaign2) { create(:campaign, name: 'Second Campaign', company: company) }

  feature '/results/comments', js: true, search: true  do
    scenario 'a user can play and dismiss the video tutorial' do
      visit results_comments_path

      feature_name = 'GETTING STARTED: COMMENTS REPORT'

      expect(page).to have_content(feature_name)
      expect(page).to have_content('Get to know your consumers')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit results_comments_path
      expect(page).to have_no_content(feature_name)
    end

    scenario 'GET index should display a table with the comments' do
      event = create(:approved_event, campaign: campaign1, company: company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      comment = create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = create(:comment, content: 'Comment #2', commentable: event, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      event.comments << comment
      event.comments << comment2
      event.save

      Sunspot.commit
      visit results_comments_path

      within('#comment-list') do
        # First Row
        within resource_item 1 do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('WED Aug 21, 2013 8:00 PM - 11:00 PM')
          expect(page).to have_content('Place 1, 11 Main St., New York City, 12345')
          expect(page).to have_content('Comment #1')
          expect(page).to have_content('Aug 22 @ 11:59 AM')
        end
        # Second Row
        within resource_item 2 do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('WED Aug 21, 2013 8:00 PM - 11:00 PM')
          expect(page).to have_content('Place 1, 11 Main St., New York City, 12345')
          expect(page).to have_content('Comment #2')
          expect(page).to have_content('Aug 23 @ 9:15 AM')
        end
      end
    end
  end

  it_behaves_like 'a list that allow saving custom filters' do

    before do
      create(:campaign, name: 'Campaign 1', company: company)
      create(:campaign, name: 'Campaign 2', company: company)
      create(:area, name: 'Area 1', company: company)
    end

    let(:list_url) { results_comments_path }

    let(:filters) do
      [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
       { section: 'CAMPAIGNS', item: 'Campaign 2' },
       { section: 'AREAS', item: 'Area 1' },
       { section: 'PEOPLE', item: user.full_name },
       { section: 'ACTIVE STATE', item: 'Inactive' }]
    end
  end
end
