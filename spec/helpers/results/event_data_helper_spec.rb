require 'rails_helper'

describe Results::EventDataHelper, type: :helper do
  let(:company) { campaign.company }
  let(:campaign) { create(:campaign, name: 'Test Campaign FY01') }
  let(:event) { create(:approved_event, campaign: campaign) }
  let(:activity_type) { create(:activity_type, name: 'Test activity type', campaign_ids: [campaign.id], company: company) }
  let(:activity) { create(:activity, activity_type: activity_type, activitable: event, company_user: company_user) }
  let(:company_user) { create(:company_user, company: campaign.company) }
  let(:params) { { campaign: [campaign.id] } }

  before do
    # Ugly hack as a workoround for https://github.com/rspec/rspec-rails/issues/1076
    helper.class.class_attribute :resource_class
    allow(helper).to receive(:current_company_user).and_return(company_user)
    allow(helper).to receive(:params).and_return(params)
    Kpi.create_global_kpis
  end

  describe '#custom_fields_to_export_values and #custom_fields_to_export_headers' do
    describe 'for event data' do
      before do
        allow(helper).to receive(:resource_class).and_return(Event)
      end

      it 'include NUMBER fields that are not linked to a KPI' do
        field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)

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
            create(:form_field_option, name: 'Ddwon Opt2')])

        event.results_for([field]).first.value = option1.id
        event.save
        expect(event.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY DDOWN FIELD'])
        expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', 'Ddwon Opt1']])
      end

      it 'include PERCENTAGE fields that are not linked to a KPI' do
        field = create(:form_field_percentage, name: 'My Perc Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Perc Opt1'),
            option2 = create(:form_field_option, name: 'Perc Opt2')])

        event.results_for([field]).first.value = { option1.id.to_s => 30, option2.id.to_s => 70 }
        event.save
        expect(event.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2'])
        expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'percentage', 0.3], ['Number', 'percentage', 0.7]])
      end

      it 'include SUMMATION fields that are not linked to a KPI' do
        field = create(:form_field_summation, name: 'My Summation Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Sum Opt1'),
            option2 = create(:form_field_option, name: 'Sum Opt2')])

        event.results_for([field]).first.value = { option1.id.to_s => 20, option2.id.to_s => 50 }
        event.save
        expect(event.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq([
          'MY SUMMATION FIELD: SUM OPT1', 'MY SUMMATION FIELD: SUM OPT2', 'MY SUMMATION FIELD: TOTAL'
        ])
        expect(helper.custom_fields_to_export_values(event)).to eq([
          ['Number', 'normal', '20'], ['Number', 'normal', '50'], ['Number', 'normal', 70.0]
        ])
      end

      it 'include LIKERT SCALE fields that are not linked to a KPI' do
        field = create(:form_field_likert_scale, name: 'My LikertScale Field',
          fieldable: campaign,
          options: [
            option1 = create(:form_field_option, name: 'LikertScale Opt1'),
            option2 = create(:form_field_option, name: 'LikertScale Opt2')],
          statements: [
            statement1 = create(:form_field_statement, name: 'LikertScale Stat1'),
            statement2 = create(:form_field_statement, name: 'LikertScale Stat2')])

        event.results_for([field]).first.value = { statement1.id.to_s => option1.id.to_s,
                                                   statement2.id.to_s => option2.id.to_s }
        expect(event.save).to be_truthy

        event2 = create(:approved_event, campaign: campaign)
        event.results_for([field]).first.value = nil
        expect(event.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq([
          'MY LIKERTSCALE FIELD: LIKERTSCALE OPT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE OPT2'
        ])
        expect(helper.custom_fields_to_export_values(event)).to eq([
          ['String', 'normal', 'LikertScale Stat1'], ['String', 'normal', 'LikertScale Stat2']
        ])

        expect(helper.custom_fields_to_export_values(event2)).to eq([
          nil, nil
        ])
      end

      it 'include TIME fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Time', name: 'My Time Field',
          fieldable: campaign)

        event.results_for([field]).first.value = '12:22 pm'
        event.save
        expect(event.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY TIME FIELD'])
        expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', '12:22 pm']])
      end

      it 'include DATE fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Date', name: 'My Date Field',
          fieldable: campaign)

        event.results_for([field]).first.value = '01/31/2014'
        event.save
        expect(event.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY DATE FIELD'])
        expect(helper.custom_fields_to_export_values(event)).to eq([['String', 'normal', '01/31/2014']])
      end

      describe "form fields merging" do
        let(:campaign2) { create(:campaign, company: company) }
        let(:params) { { campaign: [campaign.id, campaign2.id] } }

        it 'merge custom fields of different campaigns with the same name and type into the same column' do
          field1 = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
          field2 = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign2)

          event.results_for([field1]).first.value = 123
          event.save
          expect(event.save).to be_truthy

          event2 = create(:approved_event, campaign: campaign2)
          event2.results_for([field2]).first.value = 456
          event2.save
          expect(event2.save).to be_truthy

          expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD'])
          expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'normal', 123.0]])
          expect(helper.custom_fields_to_export_values(event2)).to eq([['Number', 'normal', 456.0]])
        end

        it 'merge custom segmented fields of different campaigns with the same name and type into the same columns' do
          field1 = create(:form_field_percentage, name: 'My Perc Field',
            fieldable: campaign, options: [
              option11 = create(:form_field_option, name: 'Perc Opt1'),
              option12 = create(:form_field_option, name: 'Perc Opt2')])

          field2 = create(:form_field_percentage, name: 'My Perc Field',
            fieldable: campaign2, options: [
              option21 = create(:form_field_option, name: 'Perc Opt1'),
              option22 = create(:form_field_option, name: 'Perc Opt2')])

          event.results_for([field1]).first.value = { option11.id.to_s => 30, option12.id.to_s => 70 }
          event.save
          expect(event.save).to be_truthy

          event2 = create(:approved_event, campaign: campaign2)
          event2.results_for([field2]).first.value = { option21.id.to_s => 10, option22.id.to_s => 90 }
          event2.save
          expect(event2.save).to be_truthy

          expect(helper.custom_fields_to_export_headers).to eq(['MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2'])
          expect(helper.custom_fields_to_export_values(event)).to eq([['Number', 'percentage', 0.3], ['Number', 'percentage', 0.7]])
          expect(helper.custom_fields_to_export_values(event2)).to eq([['Number', 'percentage', 0.1], ['Number', 'percentage', 0.9]])
        end

      it 'merge custom segmented fields of different campaigns with the same name and type into the same column even with different options' do
          field1 = create(:form_field_percentage, name: 'My Perc Field',
            fieldable: campaign, options: [
              option11 = create(:form_field_option, name: 'Perc Opt1'),
              option12 = create(:form_field_option, name: 'Perc Opt2')])

          field2 = create(:form_field_percentage, name: 'My Perc Field',
            fieldable: campaign2, options: [
              option21 = create(:form_field_option, name: 'Perc Opt1'),
              option22 = create(:form_field_option, name: 'Perc Opt2'),
              option23 = create(:form_field_option, name: 'Perc Opt3')])

          # A numeric field with same name
          create(:form_field_number, name: 'My Perc Field', fieldable: campaign)

          event.results_for([field1]).first.value = { option11.id.to_s => 30, option12.id.to_s => 70 }
          event.save
          expect(event.save).to be_truthy

          event2 = create(:approved_event, campaign: campaign2)
          event2.results_for([field2]).first.value = {
            option21.id.to_s => 10,
            option22.id.to_s => 20,
            option23.id.to_s => 70 }
          event2.save
          expect(event2.save).to be_truthy

          expect(helper.custom_fields_to_export_headers).to eq(['MY PERC FIELD', 'MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2', 'MY PERC FIELD: PERC OPT3'])
          expect(helper.custom_fields_to_export_values(event)).to eq([nil, ['Number', 'percentage', 0.3], ['Number', 'percentage', 0.7], nil])
          expect(helper.custom_fields_to_export_values(event2)).to eq([nil, ['Number', 'percentage', 0.1], ['Number', 'percentage', 0.2], ['Number', 'percentage', 0.7]])
        end

        it 'does not merge custom fields of the same campaigns with the same name and type into the same column' do
          field1 = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
          field2 = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)

          event.results_for([field1]).first.value = 123
          event.results_for([field2]).first.value = 456
          event.save
          expect(event.save).to be_truthy

          expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD', 'MY NUMERIC FIELD'])
          expect(helper.custom_fields_to_export_values(event)).to match_array([
            ['Number', 'normal', 123.0], ['Number', 'normal', 456.0]
          ])
        end

        it 'does not merge custom fields of different campaigns with the SAME name but DIFFERENT type into the same column' do
          create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
          create(:form_field_text, name: 'My Numeric Field', fieldable: campaign2)

          expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD', 'MY NUMERIC FIELD'])
        end
      end

      it 'returns all the segments results in order' do
        kpi = build(:kpi, company: campaign.company, kpi_type: 'percentage', name: 'My KPI')
        seg1 = kpi.kpis_segments.build(text: 'Uno')
        seg2 = kpi.kpis_segments.build(text: 'Dos')
        kpi.save
        campaign.add_kpi kpi

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
        expect(helper.custom_fields_to_export_values(event)).to eq([nil, nil, nil])

        event.result_for_kpi(kpi).value = { seg1.id.to_s => '66', seg2.id.to_s => '34' }
        event.save

        expect(helper.custom_fields_to_export_values(event)).to eq([
          ["Number", "percentage", 0.66], ["Number", "percentage", 0.34], nil
        ])

        event.result_for_kpi(kpi2).value = '666666'
        event.save

        expect(helper.custom_fields_to_export_headers).to eq(
          ['MY KPI: UNO', 'MY KPI: DOS', 'A CUSTOM KPI'])
        expect(helper.custom_fields_to_export_values(event)).to eq([
          ['Number', 'percentage', 0.66], ['Number', 'percentage', 0.34], ['Number', 'normal', 666_666]
        ])
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

    describe 'for activity data' do
      before do
        allow(helper).to receive(:resource_class).and_return(Activity)
      end

      it 'include NUMBER fields' do
        field = create(:form_field_number, name: 'My Numeric Field', fieldable: activity_type)

        activity.results_for([field]).first.value = 123
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['Number', 'normal', 123]])
      end

      it 'include RADIO fields' do
        field = create(:form_field_radio, name: 'My Radio Field',
          fieldable: activity_type, options: [
            option = create(:form_field_option, name: 'Radio Opt1'),
            create(:form_field_option, name: 'Radio Opt2')])

        activity.results_for([field]).first.value = option.id
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY RADIO FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['String', 'normal', 'Radio Opt1']])
      end

      it 'include CHECKBOX fields' do
        field = create(:form_field_checkbox, name: 'My Chk Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Chk Opt1'),
            option2 = create(:form_field_option, name: 'Chk Opt2')])

        activity.results_for([field]).first.value = { option1.id.to_s => 1, option2.id.to_s => 1 }
        activity.save
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY CHK FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['String', 'normal', 'Chk Opt1,Chk Opt2']])
      end

      it 'include DROPDOWN fields' do
        field = create(:form_field_dropdown, name: 'My Ddown Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Ddwon Opt1'),
            create(:form_field_option, name: 'Ddwon Opt2')])

        activity.results_for([field]).first.value = option1.id
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY DDOWN FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['String', 'normal', 'Ddwon Opt1']])
      end

      it 'include PERCENTAGE fields that are not linked to a KPI' do
        field = create(:form_field_percentage, name: 'My Perc Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Perc Opt1'),
            option2 = create(:form_field_option, name: 'Perc Opt2')])

        activity.results_for([field]).first.value = { option1.id.to_s => 30, option2.id.to_s => 70 }
        activity.save
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['Number', 'percentage', 0.3], ['Number', 'percentage', 0.7]])
      end

      it 'include SUMMATION fields that are not linked to a KPI' do
        field = create(:form_field_summation, name: 'My Summation Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Sum Opt1'),
            option2 = create(:form_field_option, name: 'Sum Opt2')])

        activity.results_for([field]).first.value = { option1.id.to_s => 20, option2.id.to_s => 50 }
        activity.save
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq([
          'MY SUMMATION FIELD: SUM OPT1', 'MY SUMMATION FIELD: SUM OPT2', 'MY SUMMATION FIELD: TOTAL'
        ])
        expect(helper.custom_fields_to_export_values(activity)).to eq([
          ['Number', 'normal', '20'], ['Number', 'normal', '50'], ['Number', 'normal', 70.0]
        ])
      end

      it 'include BRAND fields' do
        field = create(:form_field_brand, name: 'My Brand Field',
          fieldable: activity_type)
        brand = create(:brand, name: 'My Brand', company: company)
        campaign.brands << brand

        activity.results_for([field]).first.value = brand.id
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY BRAND FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['String', 'normal', 'My Brand']])
      end

      it 'include TIME fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Time', name: 'My Time Field',
          fieldable: activity_type)

        activity.results_for([field]).first.value = '12:22 pm'
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY TIME FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['String', 'normal', '12:22 pm']])
      end

      it 'include DATE fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Date', name: 'My Date Field',
          fieldable: activity_type)

        activity.results_for([field]).first.value = '01/31/2014'
        expect(activity.save).to be_truthy

        expect(helper.custom_fields_to_export_headers).to eq(['MY DATE FIELD'])
        expect(helper.custom_fields_to_export_values(activity)).to eq([['String', 'normal', '01/31/2014']])
      end

      describe 'when filtered by activity_type' do
        let(:params) { { activity_type: [activity_type.id] } }

        it 'include only fields that are assigned to the selected activity types' do
          activity_type2 = create(:activity_type, campaign_ids: [campaign.id])
          field1 = create(:form_field_number, name: 'My Numeric Field 1', fieldable: activity_type)
          field2 = create(:form_field_number, name: 'My Numeric Field 2', fieldable: activity_type2)

          activity.results_for([field1]).first.value = 123
          expect(activity.save).to be_truthy

          activity2 = create(:activity, activity_type: activity_type2, activitable: event, company_user: company_user)
          activity2.results_for([field2]).first.value = 666
          expect(activity2.save).to be_truthy

          expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD 1'])
          expect(helper.custom_fields_to_export_values(activity)).to eq([['Number', 'normal', 123]])
        end
      end

      describe 'when filtered by activity_type and campaign ' do
        let(:params) { { activity_type: [activity_type.id], campaign: [campaign.id] } }

        it 'include only fields that are assigned to the selected activity types' do
          activity_type2 = create(:activity_type, campaign_ids: [campaign.id], company: company)
          field1 = create(:form_field_number, name: 'My Numeric Field 1', fieldable: activity_type)
          field2 = create(:form_field_number, name: 'My Numeric Field 2', fieldable: activity_type2)

          activity.results_for([field1]).first.value = 123
          expect(activity.save).to be_truthy

          activity2 = create(:activity, activity_type: activity_type2, activitable: event, company_user: company_user)
          activity2.results_for([field2]).first.value = 666
          expect(activity2.save).to be_truthy

          expect(helper.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD 1'])
          expect(helper.custom_fields_to_export_values(activity)).to eq([['Number', 'normal', 123]])
        end
      end
    end
  end

  describe '#area_for_event' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company) }
    let(:place_la) { create(:place, country: 'US', state: 'California', city: 'Los Angeles') }
    let(:city_la) { create(:city, name: 'Los Angeles', country: 'US', state: 'California') }

    it 'should return the area name' do
      event = create(:event, campaign: campaign, place: place_la)

      area = create(:area, name: 'MyArea', company: company)

      area.places << city_la
      campaign.areas << area

      expect(area_for_event(event)).to eql 'MyArea'
    end

    it 'should return the area names separated by comma if more than one' do
      event = create(:event, campaign: campaign, place: place_la)

      area1 = create(:area, name: 'MyArea1', company: company)
      area2 = create(:area, name: 'MyArea2', company: company)

      area1.places << city_la
      area2.places << place_la
      campaign.areas << [area1, area2]

      expect(area_for_event(event)).to eql 'MyArea1, MyArea2'
    end

    it 'should include the area if the place is part of a city included for it' do
      event = create(:event, campaign: campaign, place: place_la)

      area = create(:area, name: 'MyArea1', company: company)

      create(:areas_campaign, area: area, campaign: campaign, inclusions: [city_la.id])

      expect(area_for_event(event)).to eql 'MyArea1'
    end

    it 'should NOT include the area if the place was excluded from it' do
      event = create(:event, campaign: campaign, place: place_la)

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
