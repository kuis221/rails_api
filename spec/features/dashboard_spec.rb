require 'spec_helper'

feature "Dashboard", search: true, js: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  feature "upcoming events module" do
    before do
      campaign1 = FactoryGirl.create(:campaign,  company: @company,
        name: 'Jameson + Kahlua Rum Campaign',
        brands_list: 'Jameson,Kahlua Rum')
      campaign2 = FactoryGirl.create(:campaign, company: @company,
        name: 'Mama Walker\'s + Martel Campaign',
        brands_list: 'Mama Walker\'s,Martel')
      campaign3 = FactoryGirl.create(:campaign, company: @company,
        name: 'Paddy Irish Whiskey Campaign',
        brands_list: 'Paddy Irish Whiskey')

      FactoryGirl.create(:event, campaign: campaign1, start_date: '01/14/2014', end_date: '01/15/2014')
      FactoryGirl.create(:event, campaign: campaign2, start_date: '01/27/2014', end_date: '01/27/2014')
      FactoryGirl.create(:event, campaign: campaign3, start_date: '01/14/2014', end_date: '01/14/2014')
      Sunspot.commit
    end

    feature "Events List View" do
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

          campaign = FactoryGirl.create(:campaign, company: @company,
            name: 'Paddy Irish Whiskey Campaign',
            brands_list: 'Guaro Cacique,Ron Centenario,Ron Abuelo,Absolut Vodka')
          FactoryGirl.create(:event, campaign: campaign, start_date: '01/14/2014', end_date: '01/14/2014')
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

  def upcoming_events_module
    find('div#upcomming-events-module')
  end

end