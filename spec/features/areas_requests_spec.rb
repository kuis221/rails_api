require 'spec_helper'

feature "Areas", js: true, search: true  do
  let(:company) { FactoryGirl.create(:company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:permissions) { [] }
  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can edit areas' do
    let(:area) { FactoryGirl.create(:area, company: company) }

    scenario 'allows the user to edit the area' do
      visit area_path(area)

      click_js_link('Edit')

      within visible_modal do
        fill_in 'Name', with: 'edited area name'
        fill_in 'Description', with: 'edited area description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'edited area name')
      expect(page).to have_selector('div.description-data', text: 'edited area description')
    end

    scenario 'can add a place to the area' do
      visit area_path(area)

      click_js_link 'Add Place'

      within visible_modal do
        select_from_autocomplete 'Enter a place', 'Bar None, 98 3rd Avenue'
        click_js_button 'Add Place'
      end
      ensure_modal_was_closed
      expect(page).to have_content('Bar None')
      expect(page).to have_content('98 3rd Ave New York')
      expect(area.places.count).to eql 1

      hover_and_click '.area-place',  'Remove Place'
      expect(page).to have_no_content('Bar None')
      expect(Area.last.places.count).to eql 0
    end
  end

  feature "non admin user", js: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that can edit areas" do
      let(:permissions) { [[:update, 'Area'], [:show, 'Area']] }
    end
  end

  feature "admin user" do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can edit areas"

    feature "/areas" do
      scenario "GET index should display a table with the areas" do
        areas = [
          FactoryGirl.create(:area, name: 'Gran Area Metropolitana', description: 'Ciudades principales de Costa Rica', active: true, company: @company),
          FactoryGirl.create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica', active: true, company: @company)
        ]
        Sunspot.commit
        visit areas_path

        within("#areas-list") do
          # First Row
          within("li#area_#{areas[0].id}") do
            expect(page).to have_text('Gran Area Metropolitana')
            expect(page).to have_text('Ciudades principales de Costa Rica')
            expect(page).to have_selector('a.edit')
            expect(page).to have_selector('a.disable')
          end
          # Second Row
          within("li#area_#{areas[1].id}") do
            expect(page).to have_text('Zona Norte')
            expect(page).to have_text('Ciudades del Norte de Costa Rica')
            expect(page).to have_selector('a.edit')
            expect(page).to have_selector('a.disable')
          end
        end
      end

      scenario "should allow user to deactivate areas" do
        FactoryGirl.create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: true, company: company)
        Sunspot.commit
        visit areas_path

        expect(page).to have_text('Wild Wild West')
        within("ul#areas-list li:nth-child(1)") do
          click_js_link('Deactivate')
        end
        confirm_prompt "Are you sure you want to deactivate this area?"

        expect(page).to have_no_content('Wild Wild West')
      end

      scenario "should allow user to activate areas" do
        FactoryGirl.create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: false, company: company)
        Sunspot.commit
        visit areas_path

        filter_section('ACTIVE STATE').unicheck('Inactive')
        filter_section('ACTIVE STATE').unicheck('Active')

        within("ul#areas-list li:nth-child(1)") do
          expect(page).to have_text('Wild Wild West')
          click_js_link('Activate')
        end
        within("ul#areas-list") do
          expect(page).to have_no_content('Wild Wild West')
        end
      end
    end

    feature "/areas/:area_id", :js => true do
      scenario "GET show should display the area details page" do
        area = FactoryGirl.create(:area, name: 'Some Area', description: 'an area description', company: company)
        visit area_path(area)
        expect(page).to have_selector('h2', text: 'Some Area')
        expect(page).to have_selector('div.description-data', text: 'an area description')
      end

      scenario 'diplays a table of places within the area' do
        area = FactoryGirl.create(:area, name: 'Some do', description: 'an area description', company: company)
        places = [FactoryGirl.create(:place, name: 'Place 1'), FactoryGirl.create(:place, name: 'Place 2')]
        places.map {|p| area.places << p }
        visit area_path(area)
        within('#area-places-list') do
          within("div.area-place:nth-child(1)") do
            expect(page).to have_text('Place 1')
            expect(page).to have_selector('a.remove-area-btn', visible: :false)
          end
          within("div.area-place:nth-child(2)") do
            expect(page).to have_text('Place 2')
            expect(page).to have_selector('a.remove-area-btn', visible: :false)
          end
        end
      end

      scenario 'allows the user to activate/deactivate a area' do
        area = FactoryGirl.create(:area, name: 'Some area', description: 'an area description', active: true, company: company)
        visit area_path(area)
        within('.links-data') do
          click_js_link('Deactivate')
        end

        confirm_prompt "Are you sure you want to deactivate this area?"

        within('.links-data') do
          click_js_link('Activate')
          expect(page).to have_link('Deactivate') # test the link have changed
        end
      end
    end
  end

end