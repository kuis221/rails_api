require 'rails_helper'

feature 'BrandPortfolios', js: true, search: true do
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company) { create(:company) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature '/brand_portfolios' do
    feature 'GET index' do
      scenario 'should display a table with the portfolios' do
        portfolios = [
          create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: company),
          create(:brand_portfolio, name: 'B Licores Costarricenses', description: 'Licores ticos', active: true, company: company)
        ]
        Sunspot.commit
        visit brand_portfolios_path

        # First Row
        within resource_item 1, list: '#brand_portfolios-list' do
          expect(page).to have_content(portfolios[0].name)
          expect(page).to have_content(portfolios[0].description)
        end
        # Second Row
        within resource_item 2, list: '#brand_portfolios-list' do
          expect(page).to have_content(portfolios[1].name)
          expect(page).to have_content(portfolios[1].description)
        end
      end

      scenario 'should allow user to deactivate brand portfolios' do
        create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: company)
        Sunspot.commit
        visit brand_portfolios_path

        expect(page).to have_content('A Vinos ticos')
        within resource_item do
          click_js_button 'Deactivate Brand Portfolio'
        end
        confirm_prompt 'Are you sure you want to deactivate this brand portfolio?'

        expect(page).to have_no_content('A Vinos ticos')
      end

      scenario 'should allow user to activate brand portfolios' do
        create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: false, company: company)
        Sunspot.commit
        visit brand_portfolios_path

        expect(page).to have_content '0 brand portfolios found for: Active'

        add_filter 'ACTIVE STATE', 'Inactive'
        remove_filter 'Active'

        expect(page).to have_content '1 brand portfolio found for: Inactive'

        expect(page).to have_content('A Vinos ticos')
        within resource_item do
          click_js_button 'Activate Brand Portfolio'
        end
        expect(page).to have_no_content('A Vinos ticos')
      end
    end

    scenario 'allows the user to create a new portfolio' do
      visit brand_portfolios_path

      click_js_button 'New Brand Portfolio'

      within('form#new_brand_portfolio') do
        fill_in 'Name', with: 'new portfolio name'
        fill_in 'Description', with: 'new portfolio description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new portfolio name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new portfolio name')
      expect(page).to have_selector('div.description-data', text: 'new portfolio description')
    end
  end

  feature '/brand_portfolios/:brand_portfolio_id', js: true do
    scenario 'GET show should display the portfolio details page' do
      portfolio = create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', company: company)
      visit brand_portfolio_path(portfolio)
      expect(page).to have_selector('h2', text: 'Some Brand Portfolio')
      expect(page).to have_selector('div.description-data', text: 'a portfolio description')
    end

    scenario 'diplays a table of brands within the brand portfolio' do
      portfolio = create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', company: company)
      brands = [create(:brand, name: 'Brand 1'), create(:brand, name: 'Brand 2')]
      brands.map { |b| portfolio.brands << b }
      visit brand_portfolio_path(portfolio)
      within('#brands-list') do
        within("div#brand-#{brands[0].id}") do
          expect(page).to have_content('Brand 1')
          expect(page).to have_selector('a.remove-brand-btn', visible: :false)
        end
        within("div#brand-#{brands[1].id}") do
          expect(page).to have_content('Brand 2')
          expect(page).to have_selector('a.remove-brand-btn', visible: :false)
        end
      end
    end

    scenario 'allows the user to activate/deactivate a portfolio' do
      portfolio = create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', active: true, company: company)
      visit brand_portfolio_path(portfolio)
      within('.links-data') do
        click_js_button 'Deactivate Brand Portfolio'
      end

      confirm_prompt 'Are you sure you want to deactivate this brand portfolio?'

      within('.links-data') do
        click_js_button 'Activate Brand Portfolio'
        expect(page).to have_button 'Deactivate Brand Portfolio' # test the link have changed
      end
    end

    scenario 'allows the user to edit the portfolio' do
      portfolio = create(:brand_portfolio, name: 'Old name', company: company)
      visit brand_portfolio_path(portfolio)
      expect(page).to have_content('Old name')
      within('.links-data') { click_js_button 'Edit Brand Portfolio' }

      within("form#edit_brand_portfolio_#{portfolio.id}") do
        fill_in 'Name', with: 'edited portfolio name'
        fill_in 'Description', with: 'edited portfolio description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed
      expect(page).to have_no_content('Old name')

      expect(page).to have_selector('h2', text: 'edited portfolio name')
      expect(page).to have_selector('div.description-data', text: 'edited portfolio description')
    end

    scenario 'allows the user to add brands to the portfolio' do
      portfolio = create(:brand_portfolio, company: company)
      brand = create(:brand, name: 'Guaro Cacique', company: company) # Create the brand to be added
      create(:brand, name: 'BrandOtherCompany', company: create(:company)) # Create the brand to be added
      visit brand_portfolio_path(portfolio)

      click_js_button 'Add Brand'

      within visible_modal do
        within resource_item brand do
          click_js_link 'Add'
        end
      end

      # Make sure the new brand was added to the portfolio
      within '#brands-list' do
        within 'div.brand' do
          expect(page).not_to have_content('BrandOtherCompany')
          expect(page).to have_content('Guaro Cacique')
          expect(page).to have_selector('a.remove-brand-btn', visible: :false)
        end
      end

      within visible_modal do
        click_js_link('Create New Brand')
      end

      within visible_modal do
        fill_in('brand[name]', with: 'Ron Centenario')
        click_js_button('Create')
      end

      # Make sure the new brand was added to the portfolio
      within('#brands-list div.brand:nth-child(2)') do
        expect(page).to have_content('Ron Centenario')
        expect(page).to have_selector('a.remove-brand-btn', visible: :false)
      end
    end
  end

  feature 'custom filters', search: true, js: true do
    let(:brand_portfolio1) { create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: company) }
    let(:brand_portfolio2) { create(:brand_portfolio, name: 'B Licores Costarricenses', description: 'Licores ticos', active: true, company: company) }
    let(:brand1) { create(:brand, name: 'Brand 1', company: company) }
    let(:brand2) { create(:brand, name: 'Brand 2', company: company) }

    before do
      # make sure brand portfolios are created before
      brand_portfolio1
      brand_portfolio2
      brand_portfolio1.brands << brand1
      brand_portfolio2.brands << brand2
      brand_portfolio1.save
      brand_portfolio2.save
      Sunspot.commit
    end

    scenario 'allows to create a new custom filter' do
      visit brand_portfolios_path

      filter_section('BRANDS').unicheck('Brand 1')
      filter_section('ACTIVE STATE').unicheck('Inactive')

      click_button 'Save'

      within visible_modal do
        fill_in('Filter name', with: 'My Custom Filter')
        expect do
          click_button 'Save'
          wait_for_ajax
        end.to change(CustomFilter, :count).by(1)

        custom_filter = CustomFilter.last
        expect(custom_filter.owner).to eq(company_user)
        expect(custom_filter.name).to eq('My Custom Filter')
        expect(custom_filter.apply_to).to eq('brand_portfolios')
        expect(custom_filter.filters).to eq("brand%5B%5D=#{brand1.id}&status%5B%5D=Active&status%5B%5D=Inactive")
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('My Custom Filter')
      end
    end

    scenario 'allows to apply custom filters' do
      create(:custom_filter,
             owner: company_user, name: 'Custom Filter 1', apply_to: 'brand_portfolios',
             filters: "brand%5B%5D=#{brand1.id}&status%5B%5D=Active")
      create(:custom_filter,
             owner: company_user, name: 'Custom Filter 2', apply_to: 'brand_portfolios',
             filters: "brand%5B%5D=#{brand2.id}&status%5B%5D=Active")

      visit brand_portfolios_path

      within brand_portfolios_list do
        expect(page).to have_content('A Vinos ticos')
        expect(page).to have_content('B Licores Costarricenses')
      end

      # Using Custom Filter 1
      filter_section('SAVED FILTERS').unicheck('Custom Filter 1')

      within brand_portfolios_list do
        expect(page).to have_content('A Vinos ticos')
        expect(page).to_not have_content('B Licores Costarricenses')
      end

      within '.form-facet-filters' do
        expect(find_field('Brand 1')['checked']).to be_truthy
        expect(find_field('Brand 2')['checked']).to be_falsey
        expect(find_field('Active')['checked']).to be_truthy
        expect(find_field('Inactive')['checked']).to be_falsey
        expect(find_field('Custom Filter 1')['checked']).to be_truthy
        expect(find_field('Custom Filter 2')['checked']).to be_falsey
      end

      # Using Custom Filter 2 should update results and checked/unchecked checkboxes
      filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

      within brand_portfolios_list do
        expect(page).to_not have_content('A Vinos ticos')
        expect(page).to have_content('B Licores Costarricenses')
      end

      within '.form-facet-filters' do
        expect(find_field('Brand 1')['checked']).to be_falsey
        expect(find_field('Brand 2')['checked']).to be_truthy
        expect(find_field('Active')['checked']).to be_truthy
        expect(find_field('Inactive')['checked']).to be_falsey
        expect(find_field('Custom Filter 1')['checked']).to be_falsey
        expect(find_field('Custom Filter 2')['checked']).to be_truthy
      end
    end
  end

  feature 'export' do
    let(:brand_portfolio1) { create(:brand_portfolio,
                                name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica',
                                active: true, company: company) }
    let(:brand_portfolio2) { create(:brand_portfolio,
                                name: 'B Licores Costarricenses', description: 'Licores ticos',
                                active: true, company: company) }

    before do
      # make sure tasks are created before
      brand_portfolio1
      brand_portfolio2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit brand_portfolios_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['A Vinos ticos', 'Algunos vinos de Costa Rica', 'Active'],
        ['B Licores Costarricenses', 'Licores ticos', 'Active']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit brand_portfolios_path

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
        expect(text).to include 'BrandPortfolios'
        expect(text).to include 'AVinosticos'
        expect(text).to include 'AlgunosvinosdeCostaRica'
        expect(text).to include 'BLicoresCostarricenses'
        expect(text).to include 'Licoresticos'
      end
    end
  end

  def brand_portfolios_list
    '#brand_portfolios-list'
  end
end
