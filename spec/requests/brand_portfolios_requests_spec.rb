require 'spec_helper'

describe "BrandPortfolios", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  describe "/brand_portfolios" do
    describe "GET index" do
      it "should display a table with the portfolios" do
        portfolios = [
          FactoryGirl.create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: @company),
          FactoryGirl.create(:brand_portfolio, name: 'B Licores Costarricenses', description: 'Licores ticos', active: true, company: @company)
        ]
        Sunspot.commit
        visit brand_portfolios_path

        within("ul#brand_portfolios-list") do
          # First Row
          within("li:nth-child(1)") do
            page.should have_content(portfolios[0].name)
            page.should have_content(portfolios[0].description)
          end
          # Second Row
          within("li:nth-child(2)") do
            page.should have_content(portfolios[1].name)
            page.should have_content(portfolios[1].description)
          end
        end

      end

      it "should allow user to deactivate brand portfolios" do
        FactoryGirl.create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: @company)
        Sunspot.commit
        visit brand_portfolios_path

        page.should have_content('A Vinos ticos')
        within("ul#brand_portfolios-list li:nth-child(1)") do
          click_js_link('Deactivate')
        end
        visible_modal.click_js_link("OK")
        ensure_modal_was_closed
        page.should have_no_content('A Vinos ticos')
      end

      it "should allow user to activate brand portfolios" do
        FactoryGirl.create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: false, company: @company)
        Sunspot.commit
        visit brand_portfolios_path

        filter_section('ACTIVE STATE').unicheck('Inactive')
        filter_section('ACTIVE STATE').unicheck('Active')

        page.should have_content('A Vinos ticos')
        within("ul#brand_portfolios-list li:nth-child(1)") do
          click_js_link('Activate')
        end
        page.should have_no_content('A Vinos ticos')
      end
    end

    it 'allows the user to create a new portfolio' do
      visit brand_portfolios_path

      click_js_link('New Brand portfolio')

      within("form#new_brand_portfolio") do
        fill_in 'Name', with: 'new portfolio name'
        fill_in 'Description', with: 'new portfolio description'
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new portfolio name') # Wait for the page to load
      page.should have_selector('h2', text: 'new portfolio name')
      page.should have_selector('div.description-data', text: 'new portfolio description')
    end
  end

  describe "/brand_portfolios/:brand_portfolio_id", :js => true do
    it "GET show should display the portfolio details page" do
      portfolio = FactoryGirl.create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', company: @company)
      visit brand_portfolio_path(portfolio)
      page.should have_selector('h2', text: 'Some Brand Portfolio')
      page.should have_selector('div.description-data', text: 'a portfolio description')
    end

    it 'diplays a table of brands within the brand portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', company: @company)
      brands = [FactoryGirl.create(:brand, name: 'Brand 1'), FactoryGirl.create(:brand, name: 'Brand 2')]
      brands.map {|b| portfolio.brands << b }
      visit brand_portfolio_path(portfolio)
      within('#brands-list') do
        within("div#brand-#{brands[0].id}") do
          page.should have_content('Brand 1')
          page.should have_selector('a.remove-brand-btn', visible: :false)
        end
        within("div#brand-#{brands[1].id}") do
          page.should have_content('Brand 2')
          page.should have_selector('a.remove-brand-btn', visible: :false)
        end
      end
    end

    it 'allows the user to activate/deactivate a portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', active: true, company: @company)
      visit brand_portfolio_path(portfolio)
      within('.links-data') do
        click_js_link('Deactivate')
      end
      visible_modal.click_js_link("OK")
      ensure_modal_was_closed
      within('.links-data') do
        click_js_link('Activate')
      end
    end

    it 'allows the user to edit the portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio, company: @company)
      visit brand_portfolio_path(portfolio)

      click_js_link('Edit')

      within("form#edit_brand_portfolio_#{portfolio.id}") do
        fill_in 'Name', with: 'edited portfolio name'
        fill_in 'Description', with: 'edited portfolio description'
        click_button 'Save'
      end

      find('h2', text: 'edited portfolio name') # Wait for the page to reload
      page.should have_selector('h2', text: 'edited portfolio name')
      page.should have_selector('div.description-data', text: 'edited portfolio description')
    end

    it 'allows the user to add brands to the portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio, company: @company)
      brand = FactoryGirl.create(:brand, name: 'Guaro Cacique') # Create the brand to be added
      visit brand_portfolio_path(portfolio)

      click_js_link 'Add Brand'

      within visible_modal do
        page.should have_content('Guaro Cacique')
        click_js_link 'Add'
      end

      # Make sure the new brand was added to the portfolio
      within "#brands-list" do
        within("div.brand") do
          page.should have_content('Guaro Cacique')
          page.should have_selector('a.remove-brand-btn', visible: :false)
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
      within("#brands-list div.brand:nth-child(2)") do
        page.should have_content('Ron Centenario')
        page.should have_selector('a.remove-brand-btn', visible: :false)
      end

    end
  end

end