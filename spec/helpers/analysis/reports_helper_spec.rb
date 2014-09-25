require 'rails_helper'

describe Analysis::ReportsHelper, type: :helper do
  before do
    @company = create(:company)
    @company_user = create(:company_user, company: @company)
  end

  describe '#each_events_goal' do
    it 'should return the goals results for each campaign KPI and Activity Type' do
      place = create(:place)
      activity_type1 = create(:activity_type, company: @company)
      activity_type2 = create(:activity_type, company: @company)
      kpi_impressions = create(:kpi, name: 'Impressions', kpi_type: 'number', capture_mechanism: 'integer', company: @company)
      kpi_events = create(:kpi, name: 'Events', kpi_type: 'events_count', capture_mechanism: '', company: @company)
      kpi_interactions = create(:kpi, name: 'Interactions', kpi_type: 'number', capture_mechanism: 'integer', company: @company)

      campaign = create(:campaign, company: @company)
      campaign.add_kpi kpi_impressions
      campaign.add_kpi kpi_events
      campaign.add_kpi kpi_interactions
      campaign.activity_types << activity_type1
      campaign.activity_types << activity_type2

      goals = [
        create(:goal, goalable: campaign, kpi: kpi_impressions, value: '100'),
        create(:goal, goalable: campaign, kpi: kpi_events, value: '20'),
        create(:goal, goalable: campaign, kpi: kpi_interactions, value: '400'),
        create(:goal, goalable: campaign, kpi: nil, activity_type_id: activity_type1.id, value: '5'),
        create(:goal, goalable: campaign, kpi: nil, activity_type_id: activity_type2.id, value: '10')
      ]

      event = create(:approved_event, company: @company, campaign: campaign, place: place)
      event.result_for_kpi(kpi_impressions).value = 50
      event.result_for_kpi(kpi_interactions).value = 160
      event.save
      create(:activity, activity_type: activity_type1, activitable: event, company_user: @company_user, campaign: campaign)
      create(:activity, activity_type: activity_type2, activitable: event, company_user: @company_user, campaign: campaign)

      helper.instance_variable_set(:@events_scope, Event.where(id: event.id))
      helper.instance_variable_set(:@campaign, campaign)
      helper.instance_variable_set(:@goals, goals)

      results = helper.each_events_goal

      expect(results[goals[0].id][:goal].kpi_id).to eq(kpi_impressions.id)
      expect(results[goals[0].id][:goal].goalable_id).to eq(campaign.id)
      expect(results[goals[0].id][:completed_percentage]).to eq(50.0)
      expect(results[goals[0].id][:remaining_percentage]).to eq(50.0)
      expect(results[goals[0].id][:remaining_count]).to eq(50.0)
      expect(results[goals[0].id][:total_count]).to eq(50)
      expect(results[goals[0].id][:submitted]).to eq(0)

      expect(results[goals[1].id][:goal].kpi_id).to eq(kpi_events.id)
      expect(results[goals[1].id][:goal].goalable_id).to eq(campaign.id)
      expect(results[goals[1].id][:completed_percentage]).to eq(5.0)
      expect(results[goals[1].id][:remaining_percentage]).to eq(95.0)
      expect(results[goals[1].id][:remaining_count]).to eq(19.0)
      expect(results[goals[1].id][:total_count]).to eq(1)
      expect(results[goals[1].id][:submitted]).to eq(0)

      expect(results[goals[2].id][:goal].kpi_id).to eq(kpi_interactions.id)
      expect(results[goals[2].id][:goal].goalable_id).to eq(campaign.id)
      expect(results[goals[2].id][:completed_percentage]).to eq(40.0)
      expect(results[goals[2].id][:remaining_percentage]).to eq(60.0)
      expect(results[goals[2].id][:remaining_count]).to eq(240.0)
      expect(results[goals[2].id][:total_count]).to eq(160)
      expect(results[goals[2].id][:submitted]).to eq(0)

      expect(results[goals[3].id][:goal].activity_type_id).to eq(activity_type1.id)
      expect(results[goals[3].id][:goal].goalable_id).to eq(campaign.id)
      expect(results[goals[3].id][:completed_percentage]).to eq(20.0)
      expect(results[goals[3].id][:remaining_percentage]).to eq(80.0)
      expect(results[goals[3].id][:remaining_count]).to eq(4.0)
      expect(results[goals[3].id][:total_count]).to eq(1)
      expect(results[goals[3].id][:submitted]).to eq(0)

      expect(results[goals[4].id][:goal].activity_type_id).to eq(activity_type2.id)
      expect(results[goals[4].id][:goal].goalable_id).to eq(campaign.id)
      expect(results[goals[4].id][:completed_percentage]).to eq(10.0)
      expect(results[goals[4].id][:remaining_percentage]).to eq(90.0)
      expect(results[goals[4].id][:remaining_count]).to eq(9.0)
      expect(results[goals[4].id][:total_count]).to eq(1)
      expect(results[goals[4].id][:submitted]).to eq(0)
    end
  end

  describe '#total_accounts_for_events' do
    it 'should return the total number of accounts where Events have taken place' do
      company_user = create(:company_user, company: @company, role: create(:non_admin_role, company: @company))

      campaign1 = create(:campaign, company: @company)
      campaign2 = create(:campaign, company: @company)

      place1 = create(:place)
      place2 = create(:place)
      place3 = create(:place)

      company_user.campaigns << campaign1
      company_user.places << place1
      company_user.places << place2

      events = [
        create(:approved_event, company: @company, campaign: campaign1, place: place1),
        create(:approved_event, company: @company, campaign: campaign1, place: place2),
        create(:approved_event, company: @company, campaign: campaign2, place: place2),
        create(:approved_event, company: @company, campaign: campaign2, place: place3)
      ]

      helper.instance_variable_set(:@events_scope, Event.accessible_by_user(company_user).by_campaigns(campaign1.id))

      result = helper.total_accounts_for_events

      expect(result).to eq(2)
    end
  end
end
