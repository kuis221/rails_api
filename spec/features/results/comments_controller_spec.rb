require 'spec_helper'

feature "Results Comments Page", js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  let(:campaign){ FactoryGirl.create(:campaign, name: 'First Campaign', company: @company) }

  feature "/results/comments", js: true, search: true  do
    scenario "GET index should display a table with the comments" do
      Kpi.create_global_kpis
      campaign.add_kpi(Kpi.comments)
      event = FactoryGirl.create(:approved_event, campaign: campaign, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm', place: FactoryGirl.create(:place, name: 'Place 1'))
      comment = FactoryGirl.create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = FactoryGirl.create(:comment, content: 'Comment #2', commentable: event, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      event.comments << comment
      event.comments << comment2
      event.save

      Sunspot.commit
      visit results_comments_path

      within("ul#comment-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('WED Aug 21, 2013 8:00 PM – 11:00 PM')
          expect(page).to have_content('Place 1, New York City, NY, 12345')
          expect(page).to have_content('Comment #1')
          expect(page).to have_content('Aug 22 @ 11:59 AM')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('WED Aug 21, 2013 8:00 PM – 11:00 PM')
          expect(page).to have_content('Place 1, New York City, NY, 12345')
          expect(page).to have_content('Comment #2')
          expect(page).to have_content('Aug 23 @ 9:15 AM')
        end
      end
    end
  end
end