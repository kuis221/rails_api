require 'rails_helper'

feature 'Areas', js: true, search: true  do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:permissions) { [] }
  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can edit areas' do
    let(:area) { create(:area, company: company) }

    scenario 'allows the user to edit the area' do
      visit area_path(area)

      within('.links-data') { click_js_button 'Edit Area' }

      within visible_modal do
        fill_in 'Name', with: 'edited area name'
        fill_in 'Description', with: 'edited area description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'edited area name')
      expect(page).to have_selector('div.description-data', text: 'edited area description')
    end

    scenario 'can add an existing place to the area' do
      venue = create(:venue,
                     company: company,
                     place: create(:place,
                                   name: 'Guillermitos Bar', street_number: '98',
                                   route: '3rd Ave', city: 'New York'))
      Sunspot.commit
      company_user.places << venue.place
      visit area_path(area)

      click_js_link 'Add Place'

      within visible_modal do
        select_from_autocomplete 'Search for a place', 'Guillermitos Bar'
        click_js_button 'Add Place'
      end
      ensure_modal_was_closed
      expect(page).to have_content('Guillermitos Bar')
      expect(page).to have_content('98 3rd Ave New York')
      expect(area.places.count).to eql 1
      expect(area.places.first).to eql venue.place

      hover_and_click '.area-place',  'Remove Place'
      expect(page).to have_no_content('Guillermitos Bar')
      expect(Area.last.places.count).to eql 0
    end

    scenario 'can add an NON existing place to the area. (place from Google\'s)' do
      visit area_path(area)

      click_js_link 'Add Place'

      expect do
        within visible_modal do
          select_from_autocomplete 'Search for a place', 'Walt Disney World Dolphin, 1500 Epcot Resorts Blvd'
          click_js_button 'Add Place'
        end
        ensure_modal_was_closed
        expect(page).to have_content('Walt Disney World Dolphin')
        expect(page).to have_content('1500 Epcot Resorts Blvd')
        expect(area.places.count).to eql 1
      end.to change(Place, :count).by(1)

      hover_and_click '.area-place',  'Remove Place'
      expect(page).to have_no_content('Walt Disney World Dolphin')
      expect(Area.last.places.count).to eql 0
    end
  end

  feature 'non admin user', js: true do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can edit areas' do
      let(:permissions) { [[:update, 'Area'], [:show, 'Area']] }
      before { company_user.places << create(:city, name: 'Lake Buena Vista', state: 'Florida', country: 'US') }
    end
  end

  feature 'admin user' do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can edit areas'

    feature '/areas' do
      scenario 'GET index should display a table with the areas' do
        areas = [
          create(:area, name: 'Gran Area Metropolitana',
                 description: 'Ciudades principales de Costa Rica', active: true, company: company),
          create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica',
                 active: true, company: company)
        ]
        Sunspot.commit
        visit areas_path

        within('#areas-list') do
          # First Row
          within resource_item areas[0] do
            expect(page).to have_text('Gran Area Metropolitana')
            expect(page).to have_text('Ciudades principales de Costa Rica')
            expect(page).to have_button('Edit Area')
            expect(page).to have_button('Deactivate Area')
          end
          # Second Row
          within resource_item areas[1] do
            expect(page).to have_text('Zona Norte')
            expect(page).to have_text('Ciudades del Norte de Costa Rica')
            expect(page).to have_button('Edit Area')
            expect(page).to have_button('Deactivate Area')
          end
        end
      end

      scenario 'should allow user to deactivate areas' do
        create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: true, company: company)
        Sunspot.commit
        visit areas_path

        expect(page).to have_text('Wild Wild West')
        within resource_item 1 do
          click_js_button 'Deactivate Area'
        end
        confirm_prompt 'Are you sure you want to deactivate this area?'

        expect(page).to have_no_content('Wild Wild West')
      end

      scenario 'should allow user to activate areas' do
        create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: false, company: company)
        Sunspot.commit
        visit areas_path

        filter_section('ACTIVE STATE').unicheck('Inactive')
        filter_section('ACTIVE STATE').unicheck('Active')

        within resource_item 1 do
          expect(page).to have_text('Wild Wild West')
          click_js_button 'Activate Area'
        end
        expect(page).to have_no_content('Wild Wild West')
      end
    end

    feature '/areas/:area_id', js: true do
      scenario 'GET show should display the area details page' do
        area = create(:area, name: 'Some Area', description: 'an area description', company: company)
        visit area_path(area)
        expect(page).to have_selector('h2', text: 'Some Area')
        expect(page).to have_selector('div.description-data', text: 'an area description')
      end

      scenario 'diplays a table of places within the area' do
        area = create(:area, name: 'Some do', description: 'an area description', company: company)
        places = [create(:place, name: 'Place 1'), create(:place, name: 'Place 2')]
        places.map { |p| area.places << p }
        visit area_path(area)
        within('#area-places-list') do
          within('div.area-place:nth-child(1)') do
            expect(page).to have_text('Place 1')
            expect(page).to have_selector('a.remove-area-btn', visible: :false)
          end
          within('div.area-place:nth-child(2)') do
            expect(page).to have_text('Place 2')
            expect(page).to have_selector('a.remove-area-btn', visible: :false)
          end
        end
      end

      scenario 'allows the user to activate/deactivate a area' do
        area = create(:area, name: 'Some area', description: 'an area description', active: true, company: company)
        visit area_path(area)
        within('.links-data') do
          click_js_button 'Deactivate Area'
        end

        confirm_prompt 'Are you sure you want to deactivate this area?'

        within('.links-data') do
          click_js_button 'Activate Area'
          expect(page).to have_button 'Deactivate Area' # test the link have changed
        end
      end
    end

    feature 'export' do
      let(:area1) { create(:area, name: 'Gran Area Metropolitana',
                                  description: 'Ciudades principales de Costa Rica',
                                  active: true, company: @company) }
      let(:area2) { create(:area, name: 'Zona Norte',
                                  description: 'Ciudades del Norte de Costa Rica',
                                  active: true, company: @company) }

      before do
        # make sure tasks are created before
        area1
        area2
        Sunspot.commit
      end

      scenario 'should be able to export as XLS' do
        visit areas_path

        click_js_link 'Download'
        click_js_link 'Download as XLS'

        within visible_modal do
          expect(page).to have_content('We are processing your request, the download will start soon...')
          expect(ListExportWorker).to have_queued(ListExport.last.id)
          ResqueSpec.perform_all(:export)
        end
        ensure_modal_was_closed

        expect(ListExport.last).to have_rows([
          ["NAME", "DESCRIPTION"],
          ["Gran Area Metropolitana", "Ciudades principales de Costa Rica"],
          ["Zona Norte", "Ciudades del Norte de Costa Rica"]
        ])
      end

      scenario 'should be able to export as PDF' do
        visit areas_path

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
          expect(text).to include 'Areas'
          expect(text).to include 'GranAreaMetropolitana'
          expect(text).to include 'CiudadesprincipalesdeCostaRica'
          expect(text).to include 'ZonaNorte'
          expect(text).to include 'CiudadesdelNortedeCostaRica'
        end
      end
    end
  end

end
