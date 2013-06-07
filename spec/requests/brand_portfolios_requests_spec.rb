require 'spec_helper'

describe "BrandPortfolios", :js => true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  describe "/brand_portfolios" do
    it "GET index should display a table with the portfolios" do
      portfolios = [
        FactoryGirl.create(:brand_portfolio, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true),
        FactoryGirl.create(:brand_portfolio, name: 'B Licores Costarricenses', description: 'Licores ticos', active: false)
      ]
      visit brand_portfolios_path

      within("table#brand-portfolios-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content(portfolios[0].name)
          find('td:nth-child(2)').should have_content(portfolios[0].description)
          find('td:nth-child(3)').should have_content('Active')
          find('td:nth-child(4)').should have_content('Edit')
          find('td:nth-child(4)').should have_content('Deactivate')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content(portfolios[1].name)
          find('td:nth-child(2)').should have_content(portfolios[1].description)
          find('td:nth-child(3)').should have_content('Inactive')
          find('td:nth-child(4)').should have_content('Edit')
          find('td:nth-child(4)').should have_content('Activate')
        end
      end

      assert_table_sorting ("table#brand-portfolios-list")

    end

    it 'allows the user to create a new portfolio' do
      visit brand_portfolios_path

      click_link('New Brand Portfolio')

      within("form#new_brand_portfolio") do
        fill_in 'Name', with: 'new portfolio name'
        fill_in 'Description', with: 'new portfolio description'
        click_button 'Create Brand portfolio'
      end

      find('h2', text: 'new portfolio name') # Wait for the page to load
      page.should have_selector('h2', text: 'new portfolio name')
      page.should have_selector('div.brand_portfolio-description', text: 'new portfolio description')
    end
  end

  describe "/brand_portfolios/:brand_portfolio_id", :js => true do
    it "GET show should display the portfolio details page" do
      portfolio = FactoryGirl.create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description')
      visit brand_portfolio_path(portfolio)
      page.should have_selector('h2', text: 'Some Brand Portfolio')
      page.should have_selector('div.brand_portfolio-description', text: 'a portfolio description')
    end

    it 'diplays a table of brands within the brand portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description')
      brands = [FactoryGirl.create(:brand, name: 'Brand 1'), FactoryGirl.create(:brand, name: 'Brand 2')]
      brands.map {|b| portfolio.brands << b }
      visit brand_portfolio_path(portfolio)
      within('table#brand_portfolio-brands') do
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content(brands[0].name)
          find('td:nth-child(2)').should have_content('Remove')
        end
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content(brands[1].name)
          find('td:nth-child(2)').should have_content('Remove')
        end
      end

      assert_table_sorting ("table#brand_portfolio-brands")
    end

    it 'allows the user to activate/deactivate a portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio, name: 'Some Brand Portfolio', description: 'a portfolio description', active: true)
      visit brand_portfolio_path(portfolio)
      within('.active-deactive-toggle') do
        page.should have_selector('a.btn-success.active', text: 'Active')
        page.should have_selector('a', text: 'Inactive')
        page.should_not have_selector('a.btn-danger', text: 'Inactive')

        click_link('Inactive')
        page.should have_selector('a.btn-danger.active', text: 'Inactive')
        page.should have_selector('a', text: 'Active')
        page.should_not have_selector('a.btn-success', text: 'Active')
      end
    end

    it 'allows the user to edit the portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio)
      visit brand_portfolio_path(portfolio)

      click_link('Edit')

      within("form#edit_brand_portfolio_#{portfolio.id}") do
        fill_in 'Name', with: 'edited portfolio name'
        fill_in 'Description', with: 'edited portfolio description'
        click_button 'Update Brand portfolio'
      end

      sleep(1) # Wait on second to avoid a strange error
      find('h2', text: 'edited portfolio name') # Wait for the page to reload
      page.should have_selector('h2', text: 'edited portfolio name')
      page.should have_selector('div.brand_portfolio-description', text: 'edited portfolio description')
    end

    it 'allows the user to add brands to the portfolio' do
      portfolio = FactoryGirl.create(:brand_portfolio)
      brand = FactoryGirl.create(:brand, name: 'Guaro Cacique') # Create the brand to be added
      visit brand_portfolio_path(portfolio)

      click_link('Add Brand')

      within("table#select-brands-list") do
        page.should have_content('Guaro Cacique')
        click_js_link 'Add'
      end


      # Make sure the new brand was added to the portfolio
      within('table#brand_portfolio-brands') do
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Guaro Cacique')
          find('td:nth-child(2)').should have_content('Remove')
        end
      end

      within visible_modal do
        click_js_link('Create New Brand')
      end

      within visible_modal do
        fill_in('Name', with: 'Ron Centenario')
        click_button('Create Brand')
      end

      # Make sure the new brand was added to the portfolio
      within('table#brand_portfolio-brands') do
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('Ron Centenario')
          find('td:nth-child(2)').should have_content('Remove')
        end
      end

    end
  end

end