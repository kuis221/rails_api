require 'rails_helper'

feature 'Venues Section', js: true, search: true do
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }
  let(:company_user) { user.company_users.first }
  let(:company) { user.companies.first }
  let(:campaign) { create(:campaign, company: company) }

  before { sign_in user }

  after do
    Warden.test_reset!
  end

  feature 'List of venues' do
    scenario 'a user can play and dismiss the video tutorial' do
      visit venues_path

      feature_name = 'Getting Started: Venues'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content('Welcome to the Venues module!')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit venues_path
      expect(page).to have_no_selector('h5', text: feature_name)
    end

    scenario 'GET index should display a list with the venues' do
      with_resque do
        create(:event, campaign: campaign,
                       place: create(:place, name: 'Bar Benito'),
                       results: { impressions: 35, interactions: 65, samples: 15 },
                       expenses: [{ name: 'Expense 1', amount: 1000 }])

        create(:event, campaign: campaign,
                       place: create(:place, name: 'Bar Camelas'),
                       results: { impressions: 35, interactions: 65, samples: 15 },
                       expenses: [{ name: 'Expense 1', amount: 2000 }])
      end

      Venue.reindex
      Sunspot.commit

      visit venues_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content('Bar Benito')
        expect(page).to have_selector('div.n_spent', text: '$1,000.00')
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('Bar Camelas')
        expect(page).to have_selector('div.n_spent', text: '$2,000.00')
      end
    end
  end

  feature 'export' do
    let(:month_number) { Time.now.strftime('%m') }
    let(:month_name) { Time.now.strftime('%b') }
    let(:year_number) { Time.now.strftime('%Y') }
    let(:today) { Time.zone.local(year_number, month_number, 18, 12, 00) }
    let(:event1) { create(:event, campaign: campaign,
                          place: create(:place, name: 'Place 1', td_linx_code: '5155520'),
                          results: { impressions: 35, interactions: 65, samples: 15 },
                          expenses: [{ name: 'Expense 1', amount: 1000 }] )}
    let(:event2) { create(:event, campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                          place: create(:place, name: 'Place 2', formatted_address: '456 Your Street', city: 'Los Angeles', state: 'CA', zipcode: '67890', td_linx_code: '3929538'),
                          results: { impressions: 45, interactions: 75, samples: 25 },
                          expenses: [{ name: 'Expense 1', amount: 2000 }] )}

    before do
      # make sure events are created before
      with_resque do
        event1
        event2
      end
      Venue.reindex
      Sunspot.commit
    end

    scenario 'should be able to export as xls' do
      visit venues_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ["VENUE NAME", "TD LINX CODE", "ADDRESS", "CITY", "STATE", "EVENTS COUNT", "PROMO HOURS COUNT", "TOTAL $ SPENT"],
        ["Place 1", "5155520", "123 My Street", "New York City", "NY", "1", "2.0", "1000.0"],
        ["Place 2", "3929538", "456 Your Street", "Los Angeles", "CA", "1", "2.0", "2000.0"]
      ])
    end

    scenario 'should be able to export as PDF' do
      visit venues_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      export = ListExport.last
      # Test the generated PDF...
      reader = PDF::Reader.new(open(export.file.url))
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include 'Place1'
        expect(text).to include 'Place2'
        expect(text).to include '123MyStre'
        expect(text).to include '456YourStre'
        expect(text).to include '$1,000.00'
        expect(text).to include '$2,000.00'
      end
    end
  end

  feature '/venues/:venue_id' do
    scenario 'a user can play and dismiss the video tutorial' do
      venue = create(:venue, company: company,
                             place: create(:place, is_custom_place: true, reference: nil))

      visit venue_path(venue)

      feature_name = 'Getting Started: Venue Details'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content('You are now viewing the Venue Details page')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit venue_path(venue)
      expect(page).to have_no_selector('h5', text: feature_name)
    end
  end
end
