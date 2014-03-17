require 'spec_helper'

feature "Results Goals vs Actuals Page", js: true, search: true  do

  let(:user) {FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)}

  before do
    @company = user.companies.first
    sign_in user
  end

  feature "/results/gva", js: true, search: true  do
    feature "with a non admin user", search: false do
      let(:company) { FactoryGirl.create(:company) }
      let(:user){ FactoryGirl.create(:user, company: company, role_id: FactoryGirl.create(:non_admin_role, company: company).id) }
      let(:company_user) { user.company_users.first }

      scenario "should display the total number of accounts where Events have taken place" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = FactoryGirl.create(:kpi, company: company)
        campaign.add_kpi kpi
        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi, value: '100')

        place1 = FactoryGirl.create(:place)
        place2 = FactoryGirl.create(:place)
        place3 = FactoryGirl.create(:place)

        company_user.campaigns << campaign
        company_user.places << place1
        company_user.places << place2
        company_user.places << place3

        events = [
          FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place1),
          FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place2),
          FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place3)
        ]

        visit results_gva_path

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        expect(page).to have_content('3 VENUES')
      end
    end
  end
end