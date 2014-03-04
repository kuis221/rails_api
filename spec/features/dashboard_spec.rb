require 'spec_helper'

feature "Dashboard", search: true, js: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can view the upcoming events module' do
    let(:campaign1) { FactoryGirl.create(:campaign,  company: company,
        name: 'Jameson + Kahlua Rum Campaign',
        brands_list: 'Jameson,Kahlua Rum,Guaro Cacique,Ron Centenario,Ron Abuelo,Absolut Vodka') }

    let(:campaign2) { FactoryGirl.create(:campaign, company: company,
      name: 'Mama Walker\'s + Martel Campaign',
      brands_list: 'Mama Walker\'s,Martel') }

    let(:campaign3) { FactoryGirl.create(:campaign, company: company,
      name: 'Paddy Irish Whiskey Campaign',
      brands_list: 'Paddy Irish Whiskey') }

    let(:events) {[
      FactoryGirl.create(:event, campaign: campaign1, place: place, start_date: '01/14/2014', end_date: '01/15/2014'),
      FactoryGirl.create(:event, campaign: campaign2, place: place, start_date: '01/27/2014', end_date: '01/27/2014'),
      FactoryGirl.create(:event, campaign: campaign3, place: place, start_date: '01/14/2014', end_date: '01/14/2014') ]}


    feature "Events List View" do
      before { events.count; Sunspot.commit } # Create the events
      scenario "should display a list of upcoming events" do
        Timecop.travel(Time.zone.local(2014, 01, 14, 12, 00)) do
          visit root_path
          within upcoming_events_module do
            expect(all('li').count).to eql 3
            expect(page).to have_content('Jameson + Kahlua Rum Campaign')
            expect(page).to have_content('Mama Walker\'s + Martel Campaign')
            expect(page).to have_content('Paddy Irish Whiskey Campaign')
          end
        end
      end
    end

    feature "Events Calendar View" do
      before { events.count; Sunspot.commit } # Create the events

      scenario "should start with today's day and show 2 weeks" do
        # Today is Tuesday, Jan 11
        Timecop.travel(Time.zone.local(2014, 01, 14, 12, 00)) do

          visit root_path

          within upcoming_events_module do
            click_link "Calendar View"

            # Check that the calendar was correctly created starting with current week day
            expect(find('.calendar-header th:nth-child(1)')).to have_content('TUE')
            expect(find('.calendar-header th:nth-child(2)')).to have_content('WED')
            expect(find('.calendar-header th:nth-child(3)')).to have_content('THU')
            expect(find('.calendar-header th:nth-child(4)')).to have_content('FRI')
            expect(find('.calendar-header th:nth-child(5)')).to have_content('SAT')
            expect(find('.calendar-header th:nth-child(6)')).to have_content('SUN')
            expect(find('.calendar-header th:nth-child(7)')).to have_content('MON')

            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(1)')).to have_content('14')
            expect(find('.calendar-table tbody tr:nth-child(2) td:nth-child(7)')).to have_content('27')

            # Check that the brands appears on the correct cells
            #01/14/2014
            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(1)')).to have_content('Jameson')
            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(1)')).to have_content('Kahlua Rum')
            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(1)')).to have_content('Paddy Irish Whiskey')

            # 01/15/2014
            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(2)')).to have_content('Jameson')
            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(2)')).to have_content('Kahlua Rum')
            expect(find('.calendar-table tbody tr:nth-child(1) td:nth-child(2)')).to have_no_content('Paddy Irish Whiskey')

            #01/27/2014
            expect(find('.calendar-table tbody tr:nth-child(2) td:nth-child(7)')).to have_content('Mama Walker\'s')
            expect(find('.calendar-table tbody tr:nth-child(2) td:nth-child(7)')).to have_content('Martel')
          end
        end
      end

      scenario "clicking on the day should take the user to the event list for that day" do

        Timecop.travel(Time.zone.local(2014, 01, 14, 12, 00)) do
          visit root_path

          within upcoming_events_module do
            click_link "Calendar View"

            click_link '14'
          end

          expect(current_path).to eql events_path

          # The 14 should appear selected in the calendar
          expect(page).to have_selector('a.datepick-event.datepick-selected', text: 14)

          within("ul#events-list") do
            expect(all('li').count).to be 2
            expect(page).to have_content('Jameson + Kahlua Rum Campaign')
            expect(page).to have_content('Paddy Irish Whiskey Campaign')
          end
        end
      end

      scenario "clicking on the brand should take the user to the event list filtered for that date and brand" do
        Timecop.travel(Time.zone.local(2014, 01, 14, 12, 00)) do
          visit root_path

          within upcoming_events_module do
            click_link "Calendar View"

            click_link 'Paddy Irish Whiskey'
          end

          expect(current_path).to eql events_path

          # The 14 should appear selected in the calendar
          expect(page).to have_selector('a.datepick-event.datepick-selected', text: 14)

          within("ul#events-list") do
            expect(all('li').count).to be 1
            expect(page).to have_content('Paddy Irish Whiskey Campaign')
          end
        end
      end

      scenario "a day with more than 6 brands should display a 'more' link" do
        Timecop.travel(Time.zone.local(2014, 01, 14, 12, 00)) do
          FactoryGirl.create(:event,
              campaign: campaign1, place: place,
              start_date: '01/14/2014', end_date: '01/14/2014')
          Sunspot.commit

          visit root_path

          within upcoming_events_module do
            click_link "Calendar View"

            within '.calendar-table tbody tr:nth-child(1) td:nth-child(1)' do
              expect(page).to have_link('+1 More')
              click_link '+1 More'
              expect(page).to have_content('Tue Jan 14')
              expect(page).to have_no_content('+1 More')
            end
          end
        end
      end
    end
  end

  feature "Admin User" do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can view the upcoming events module"

    describe "recent comments module" do
      scenario "should display only 9 comments" do
        FactoryGirl.create_list(:comment, 15, commentable: FactoryGirl.create(:event, company: company))
        visit root_path
        within recent_comments_module do
          expect(all('.comment').count).to eql 9
        end
      end
    end
  end

  feature "Non Admin User", js: true, search: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that can view the upcoming events module" do
      before { company_user.campaigns << [campaign, campaign1, campaign2, campaign3] }
      before { company_user.places << FactoryGirl.create(:place, city: nil, state: 'San Jose', country: 'CR', types: ['locality']) }
      let(:permissions) { [[:upcomings_events_module, 'Symbol', 'dashboard'], [:index, 'Event'],  [:view_list, 'Event']] }
    end
  end

  def upcoming_events_module
    find('div#upcomming-events-module')
  end

  def recent_comments_module
    find('div#recent-comments-module')
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create({action: p[0], subject_class: p[1], subject_id: p[2]}, without_protection: true)
    end
  end

end