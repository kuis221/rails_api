require 'rails_helper'

describe Results::EventDataHelper, type: :helper do
  let(:campaign) { create(:campaign, name: 'Test Campaign FY01') }
  before do
    allow(helper).to receive(:current_company_user).and_return(build(:company_user, company: campaign.company))
    allow(helper).to receive(:params).and_return(campaign: [campaign.id])
    Kpi.create_global_kpis
  end

  describe '#custom_fields_to_export_values and #custom_fields_to_export_headers' do
    it 'include NUMBER fields that are not linked to a KPI' do
      field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)

      event = build(:approved_event, campaign: campaign)
      event.results_for([field]).first.value = 123
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'normal', 123]])
    end

    it 'include RADIO fields that are not linked to a KPI' do
      field = create(:form_field_radio, name: 'My Radio Field',
        fieldable: campaign, options: [
          option = create(:form_field_option, name: 'Radio Opt1'),
          create(:form_field_option, name: 'Radio Opt2')])

      event = build(:approved_event, campaign: campaign)
      event.results_for([field]).first.value = option.id
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY RADIO FIELD'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', 'Radio Opt1']])
    end

    it 'include CHECKBOX fields that are not linked to a KPI' do
      field = create(:form_field_checkbox, name: 'My Chk Field',
        fieldable: campaign, options: [
          option1 = create(:form_field_option, name: 'Chk Opt1'),
          option2 = create(:form_field_option, name: 'Chk Opt2')])

      event = build(:approved_event, campaign: campaign)
      event.results_for([field]).first.value = { option1.id.to_s => 1, option2.id.to_s => 1 }
      event.save
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY CHK FIELD'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', 'Chk Opt1,Chk Opt2']])
    end

    it 'include DROPDOWN fields that are not linked to a KPI' do
      field = create(:form_field_dropdown, name: 'My Ddown Field',
        fieldable: campaign, options: [
          option1 = create(:form_field_option, name: 'Ddwon Opt1'),
          option2 = create(:form_field_option, name: 'Ddwon Opt2')])

      event = build(:approved_event, campaign: campaign)
      event.results_for([field]).first.value = option1.id
      event.save
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY DDOWN FIELD'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', 'Ddwon Opt1']])
    end

    it 'include TIME fields that are not linked to a KPI' do
      field = create(:form_field, type: 'FormField::Time', name: 'My Time Field',
        fieldable: campaign)

      event = build(:approved_event, campaign: campaign)
      event.results_for([field]).first.value = '12:22 pm'
      event.save
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY TIME FIELD'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', '12:22 pm']])
    end

    it 'include DATE fields that are not linked to a KPI' do
      field = create(:form_field, type: 'FormField::Date', name: 'My Date Field',
        fieldable: campaign)

      event = build(:approved_event, campaign: campaign)
      event.results_for([field]).first.value = '01/31/2014'
      event.save
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY DATE FIELD'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', '01/31/2014']])
    end

    it 'returns all the segments results in order' do
      kpi = build(:kpi, company: campaign.company, kpi_type: 'percentage', name: 'My KPI')
      seg1 = kpi.kpis_segments.build(text: 'Uno')
      seg2 = kpi.kpis_segments.build(text: 'Dos')
      kpi.save
      campaign.add_kpi kpi

      event = build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = { seg1.id.to_s => '88', seg2.id.to_s => '12' }
      expect(event.save).to be_truthy

      expect(helper.custom_fields_to_export_headers).to eq(['MY KPI: UNO', 'MY KPI: DOS'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'percentage', 0.88], ['Number', 'percentage', 0.12]])
    end

    it 'correctly include segmented kpis and non-segmented kpis together' do
      kpi = build(:kpi, company_id: campaign.company_id, kpi_type: 'percentage', name: 'My KPI')
      seg1 = kpi.kpis_segments.build(text: 'Uno')
      seg2 = kpi.kpis_segments.build(text: 'Dos')
      kpi.save
      campaign.add_kpi kpi

      kpi2 = create(:kpi, company_id: campaign.company_id, name: 'A Custom KPI')
      campaign.add_kpi kpi2

      # Set the results for the event
      event = create(:approved_event, campaign: campaign)

      expect(helper.custom_fields_to_export_values(event)).to eq([nil, nil, nil])

      event.result_for_kpi(kpi).value = { seg1.id.to_s => '66', seg2.id.to_s => '34' }
      event.save

      expect(helper.custom_fields_to_export_values(event)).to eq([nil, ['Number', 'percentage', 0.66], ['Number', 'percentage', 0.34]])

      event.result_for_kpi(kpi2).value = '666666'
      event.save

      expect(helper.custom_fields_to_export_headers).to eq(['A CUSTOM KPI', 'MY KPI: UNO', 'MY KPI: DOS'])
      expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'normal', 666_666], ['Number', 'percentage', 0.66], ['Number', 'percentage', 0.34]])
    end

    it "returns nil for the fields that doesn't apply to the event's campaign" do
      campaign2 = create(:campaign, company: campaign.company)
      allow(helper).to receive(:params).and_return(campaign: [campaign.id, campaign2.id])

      kpi = create(:kpi, company_id: campaign.company_id, name: 'A Custom KPI')
      kpi2 = create(:kpi, company_id: campaign.company_id, name: 'Another KPI')

      campaign.add_kpi kpi
      campaign2.add_kpi kpi2

      event = build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = '9876'
      event.save

      event2 = build(:approved_event, campaign: campaign2)
      event2.result_for_kpi(kpi2).value = '7654'
      event2.save

      expect(helper.custom_fields_to_export_headers).to eq(['A CUSTOM KPI', 'ANOTHER KPI'])

      expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'normal', 9876], nil])
      expect(helper.custom_fields_to_export_values(event2)).to eq([nil, ['Number', 'normal', 7654]])
    end

    it 'returns the segment name for count kpis' do
      kpi = build(:kpi, company_id: campaign.company_id, kpi_type: 'count', name: 'Are you Great?')
      answer = kpi.kpis_segments.build(text: 'Yes')
      kpi.kpis_segments.build(text: 'No')
      kpi.save
      campaign.add_kpi kpi

      event = build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = answer.id
      event.save

      event2 = build(:approved_event, campaign: campaign)
      event2.result_for_kpi(kpi).value = answer.id
      event2.save

      expect(helper.custom_fields_to_export_headers).to eq(['ARE YOU GREAT?'])
      expect(helper.custom_fields_to_export_values(event)).to eq([%w(String normal Yes)])
      expect(helper.custom_fields_to_export_values(event2)).to eq([%w(String normal Yes)])
    end

    it 'returns custom kpis grouped on the same column' do
      campaign2 = create(:campaign, company: campaign.company)
      allow(helper).to receive(:params).and_return(campaign: [campaign.id, campaign2.id])

      kpi = create(:kpi, company_id: campaign.company_id, name: 'A Custom KPI')
      kpi2 = create(:kpi, company_id: campaign.company_id, name: 'Another KPI')

      campaign.add_kpi kpi
      campaign.add_kpi kpi2

      campaign2.add_kpi kpi
      campaign2.add_kpi kpi2

      event = build(:approved_event, campaign: campaign)
      event.result_for_kpi(kpi).value = '1111'
      event.result_for_kpi(kpi2).value = '2222'
      event.save

      event2 = build(:approved_event, campaign: campaign2)
      event2.result_for_kpi(kpi).value = '3333'
      event2.result_for_kpi(kpi2).value = '4444'
      event2.save

      expect(helper.custom_fields_to_export_headers).to eq(['A CUSTOM KPI', 'ANOTHER KPI'])

      expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'normal', 1111], ['Number', 'normal', 2222]])
      expect(helper.custom_fields_to_export_values(event2)).to eq([['Number', 'normal', 3333], ['Number', 'normal', 4444]])
    end
  end

  describe '#area_for_event' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company) }

    it 'should return the area name' do
      place_la = create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      event = create(:event, campaign: campaign, place: place_la)

      city_la = create(:city, name: 'Los Angeles', country: 'US', state: 'California')
      area = create(:area, name: 'MyArea', company: company)

      area.places << city_la
      campaign.areas << area

      expect(area_for_event(event)).to eql 'MyArea'
    end

    it 'should return the area names separated by comma if more than one' do
      place_la = create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      event = create(:event, campaign: campaign, place: place_la)

      city_la = create(:city, name: 'Los Angeles', country: 'US', state: 'California')
      area1 = create(:area, name: 'MyArea1', company: company)
      area2 = create(:area, name: 'MyArea2', company: company)

      area1.places << city_la
      area2.places << place_la
      campaign.areas << [area1, area2]

      expect(area_for_event(event)).to eql 'MyArea1, MyArea2'
    end

    it 'should NOT include the area if the place was excluded from it' do
      place_la = create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      event = create(:event, campaign: campaign, place: place_la)

      city_la = create(:city, name: 'Los Angeles', country: 'US', state: 'California')
      area1 = create(:area, name: 'MyArea1', company: company)
      area2 = create(:area, name: 'MyArea2', company: company)

      area1.places << city_la
      area2.places << place_la
      create(:areas_campaign, area: area1, campaign: campaign)
      create(:areas_campaign, area: area2, campaign: campaign, exclusions: [place_la.id])

      expect(area_for_event(event)).to eql 'MyArea1'
    end
  end
end
