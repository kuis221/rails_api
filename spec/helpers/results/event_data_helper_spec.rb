require 'spec_helper'

describe Results::EventDataHelper do
  let(:campaign) { FactoryGirl.create(:campaign, name: 'Test Campaign FY01') }
  before do
    helper.stubs(:current_company_user).returns(FactoryGirl.build(:company_user, company: campaign.company))
    helper.stubs(:params).returns({campaign: [campaign.id]})
    Kpi.create_global_kpis
  end

  describe "#custom_fields_to_export_values and #custom_fields_to_export_headers" do
    it "returns all the segments results in order" do
      kpi = FactoryGirl.build(:kpi, company: campaign.company, kpi_type: 'percentage', name: 'My KPI')
      kpi.kpis_segments.build(text: 'Uno')
      kpi.kpis_segments.build(text: 'Dos')
      kpi.save
      campaign.add_kpi kpi

      event = FactoryGirl.build(:approved_event, campaign: campaign)
      results = event.result_for_kpi(kpi)
      results.first.value = '112233'
      results.last.value = '445566'
      event.save

      helper.custom_fields_to_export_headers.should == ['MY KPI: UNO', 'MY KPI: DOS']
      helper.custom_fields_to_export_values(event).should == [112233, 445566]
    end

    it "correctly include segmented kpis and non-segmented kpis together" do
      kpi = FactoryGirl.build(:kpi, company_id: campaign.company_id, kpi_type: 'percentage', name: 'My KPI')
      kpi.kpis_segments.build(text: 'Uno')
      kpi.kpis_segments.build(text: 'Dos')
      kpi.save
      campaign.add_kpi kpi

      kpi2 = FactoryGirl.create(:kpi, company_id: campaign.company_id, name: 'A Custom KPI')
      campaign.add_kpi kpi2


      # Set the results for the event
      event = FactoryGirl.create(:approved_event, campaign: campaign)

      helper.custom_fields_to_export_values(event).should == [nil, nil, nil]

      results = event.result_for_kpi(kpi)
      results.first.value = '112233'
      results.last.value = '445566'
      event.save

      helper.custom_fields_to_export_values(event).should == [nil, 112233, 445566]

      event.result_for_kpi(kpi2).value = '666666'
      event.save

      helper.custom_fields_to_export_headers.should == ['A CUSTOM KPI', 'MY KPI: UNO', 'MY KPI: DOS']
      helper.custom_fields_to_export_values(event).should == [666666, 112233, 445566]
    end

    it "returns nil for the fields that doesn't apply to the event's campaign" do
      campaign2 = FactoryGirl.create(:campaign, company: campaign.company)
      helper.stubs(:params).returns({campaign: [campaign.id,campaign2.id]})

      kpi = FactoryGirl.create(:kpi, company_id: campaign.company_id, name: 'A Custom KPI')
      kpi2 = FactoryGirl.create(:kpi, company_id: campaign.company_id, name: 'Another KPI')

      campaign.add_kpi kpi
      campaign2.add_kpi kpi2

      event = FactoryGirl.build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = '9876'
      event.save

      event2 = FactoryGirl.build(:approved_event, campaign: campaign2)
      event2.result_for_kpi(kpi2).value = '7654'
      event2.save

      helper.custom_fields_to_export_headers.should == ['A CUSTOM KPI', 'ANOTHER KPI']

      helper.custom_fields_to_export_values(event).should == [9876, nil]
      helper.custom_fields_to_export_values(event2).should == [nil, 7654]
    end

    it "returns the segment name for count kpis" do
      kpi = FactoryGirl.build(:kpi, company_id: campaign.company_id, kpi_type: 'count', name: 'Are you Great?')
      answer = kpi.kpis_segments.build(text: 'Yes')
      kpi.kpis_segments.build(text: 'No')
      kpi.save
      campaign.add_kpi kpi

      event = FactoryGirl.build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = answer.id
      event.save

      event2 = FactoryGirl.build(:approved_event, campaign: campaign)
      event2.result_for_kpi(kpi).value = answer.id
      event2.save

      helper.custom_fields_to_export_headers.should == ['ARE YOU GREAT?']
      helper.custom_fields_to_export_values(event).should == ['Yes']
      helper.custom_fields_to_export_values(event2).should == ['Yes']
    end



    it "returns custom kpis grouped on the same column" do
      campaign2 = FactoryGirl.create(:campaign)
      helper.stubs(:params).returns({campaign: [campaign.id,campaign2.id]})

      kpi = FactoryGirl.create(:kpi, company_id: campaign.company_id, name: 'A Custom KPI')
      kpi2 = FactoryGirl.create(:kpi, company_id: campaign.company_id, name: 'Another KPI')

      campaign.add_kpi kpi
      campaign2.add_kpi kpi
      campaign.add_kpi kpi2
      campaign2.add_kpi kpi2

      event = FactoryGirl.build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = '1111'
      event.result_for_kpi(kpi2).value = '2222'
      event.save

      event2 = FactoryGirl.build(:approved_event, campaign: campaign2)
      event2.result_for_kpi(kpi).value = '3333'
      event2.result_for_kpi(kpi2).value = '4444'
      event2.save

      helper.custom_fields_to_export_headers.should == ['A CUSTOM KPI', 'ANOTHER KPI']

      helper.custom_fields_to_export_values(event).should == [1111, 2222]
      helper.custom_fields_to_export_values(event2).should == [3333, 4444]
    end
  end
end