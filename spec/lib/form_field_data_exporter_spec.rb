require 'rails_helper'

describe FormFieldDataExporter, type: :model do
  let(:company) { campaign.company }
  let(:campaign) { create(:campaign) }
  let(:event) { create(:approved_event, campaign: campaign) }
  let(:activity_type) { create(:activity_type, campaign_ids: [campaign.id], company: company) }
  let(:activity) { create(:activity, activity_type: activity_type, activitable: event, company_user: company_user) }
  let(:company_user) { create(:company_user, company: campaign.company) }
  let(:params) { { campaign: [campaign.id] } }

  before { Kpi.create_global_kpis }

  let(:resource_class) { Event }

  let(:subject) { FormFieldDataExporter.new(company_user, params, resource_class) }

  describe '#custom_fields_to_export_values and #custom_fields_to_export_headers' do
    describe 'for event data' do
      it 'includes NUMBER fields that are not linked to a KPI' do
        field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)

        event.results_for([field]).first.value = 123
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD'])
        expect(subject.custom_fields_to_export_values(event)).to eq([123])
      end

      it 'includes RADIO fields that are not linked to a KPI' do
        field = create(:form_field_radio, name: 'My Radio Field',
          fieldable: campaign, options: [
            option = create(:form_field_option, name: 'Radio Opt1'),
            create(:form_field_option, name: 'Radio Opt2')])

        event.results_for([field]).first.value = option.id
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY RADIO FIELD'])
        expect(subject.custom_fields_to_export_values(event)).to eq(['Radio Opt1'])
      end

      it 'includes CHECKBOX fields that are not linked to a KPI' do
        field = create(:form_field_checkbox, name: 'My Chk Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Chk Opt1'),
            option2 = create(:form_field_option, name: 'Chk Opt2')])

        event.results_for([field]).first.value = { option1.id.to_s => 1, option2.id.to_s => 1 }
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY CHK FIELD: CHK OPT1', 'MY CHK FIELD: CHK OPT2'])
        expect(subject.custom_fields_to_export_values(event)).to eq(['Yes', 'Yes'])
      end

      it 'return empty if no options were selected in checkbox fields' do
        field = create(:form_field_checkbox, name: 'My Chk Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Chk Opt1'),
            option2 = create(:form_field_option, name: 'Chk Opt2')])

        event.results_for([field]).first.value = { }
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY CHK FIELD: CHK OPT1', 'MY CHK FIELD: CHK OPT2'])
        expect(subject.custom_fields_to_export_values(event)).to eq([nil, nil])
      end

      it 'includes DROPDOWN fields that are not linked to a KPI' do
        field = create(:form_field_dropdown, name: 'My Ddown Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Ddwon Opt1'),
            create(:form_field_option, name: 'Ddwon Opt2')])

        event.results_for([field]).first.value = option1.id
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY DDOWN FIELD'])
        expect(subject.custom_fields_to_export_values(event)).to eq(['Ddwon Opt1'])
      end

      it 'includes PERCENTAGE fields that are not linked to a KPI' do
        field = create(:form_field_percentage, name: 'My Perc Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Perc Opt1'),
            option2 = create(:form_field_option, name: 'Perc Opt2')])

        event.results_for([field]).first.value = { option1.id.to_s => 30, option2.id.to_s => 70 }
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2'])
        expect(subject.custom_fields_to_export_values(event)).to eq([0.3,  0.7])
      end

      it 'includes SUMMATION fields that are not linked to a KPI' do
        field = create(:form_field_summation, name: 'My Summation Field',
          fieldable: campaign, options: [
            option1 = create(:form_field_option, name: 'Sum Opt1'),
            option2 = create(:form_field_option, name: 'Sum Opt2')])

        event.results_for([field]).first.value = { option1.id.to_s => 20, option2.id.to_s => 50 }
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq([
          'MY SUMMATION FIELD: SUM OPT1', 'MY SUMMATION FIELD: SUM OPT2', 'MY SUMMATION FIELD: TOTAL'
        ])
        expect(subject.custom_fields_to_export_values(event)).to eq([
          '20', '50', 70.0
        ])
      end

      describe 'LIKERT SCALE fields' do
        let(:option1) { create(:form_field_option, name: 'LikertScale Opt1') }
        let(:option2) { create(:form_field_option, name: 'LikertScale Opt2') }
        let(:statement1) { create(:form_field_statement, name: 'LikertScale Stat1') }
        let(:statement2) { create(:form_field_statement, name: 'LikertScale Stat2') }
        let(:field) { create(:form_field_likert_scale, name: 'My LikertScale Field',
                                                       fieldable: campaign,
                                                       multiple: false,
                                                       options: [option1, option2],
                                                       statements: [statement1, statement2]
                      )
        }

        it 'includes single answer LIKERT SCALE fields that are not linked to a KPI' do
          event.results_for([field]).first.value = { statement1.id.to_s => option1.id.to_s,
                                                     statement2.id.to_s => option2.id.to_s }
          expect(event.save).to be_truthy

          event2 = create(:approved_event, campaign: campaign)

          expect(subject.custom_fields_to_export_headers).to eq([
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE STAT2'
          ])
          expect(subject.custom_fields_to_export_values(event)).to eq([
            'LikertScale Opt1', 'LikertScale Opt2'
          ])

          expect(subject.custom_fields_to_export_values(event2)).to eq([
            nil, nil
          ])
        end

        it 'includes multiple answer LIKERT SCALE fields that are not linked to a KPI' do
          field.update_attribute(:multiple, true)
          event.results_for([field]).first.value = { statement1.id.to_s => [option1.id.to_s],
                                                     statement2.id.to_s => [option1.id.to_s, option2.id.to_s] }
          expect(event.save).to be_truthy

          event2 = create(:approved_event, campaign: campaign)

          expect(subject.custom_fields_to_export_headers).to eq([
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT1 - LIKERTSCALE OPT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE STAT1 - LIKERTSCALE OPT2',
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT2 - LIKERTSCALE OPT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE STAT2 - LIKERTSCALE OPT2'
          ])
          expect(subject.custom_fields_to_export_values(event)).to eq([
            '1', nil, '1', '1'
          ])

          expect(subject.custom_fields_to_export_values(event2)).to eq([
            nil, nil, nil, nil
          ])
        end
      end

      it 'includes TIME fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Time', name: 'My Time Field',
          fieldable: campaign)

        event.results_for([field]).first.value = '12:22 pm'
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY TIME FIELD'])
        expect(subject.custom_fields_to_export_values(event)).to eq(['12:22 pm'])
      end

      it 'includes DATE fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Date', name: 'My Date Field',
          fieldable: campaign)

        event.results_for([field]).first.value = '01/31/2014'
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY DATE FIELD'])
        expect(subject.custom_fields_to_export_values(event)).to eq(['01/31/2014'])
      end

      it 'includes MARQUE fields' do
        brand = create(:brand, name: 'My Brand', company: company)
        marque = create(:marque, name: 'My Brand Marque', brand: brand)
        campaign.brands << brand
        brand_field = create(:form_field, type: 'FormField::Brand', name: 'My Brand Field',
          fieldable: campaign, ordering: 0)

        marque_field = create(:form_field, type: 'FormField::Marque', name: 'My Marque Field',
          fieldable: campaign, ordering: 1)

        event.results_for([brand_field]).first.value = brand.id
        event.results_for([marque_field]).first.value = marque.id
        event.save
        expect(event.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY BRAND FIELD', 'MY MARQUE FIELD'])
        expect(subject.custom_fields_to_export_values(event)).to eq([
          'My Brand',
          'My Brand Marque'])
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

          expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD'])
          expect(subject.custom_fields_to_export_values(event)).to eq([123.0])
          expect(subject.custom_fields_to_export_values(event2)).to eq([456.0])
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

          expect(subject.custom_fields_to_export_headers).to eq(['MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2'])
          expect(subject.custom_fields_to_export_values(event)).to eq([0.3, 0.7])
          expect(subject.custom_fields_to_export_values(event2)).to eq([0.1, 0.9])
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

          expect(subject.custom_fields_to_export_headers).to eq([
            'MY PERC FIELD', 'MY PERC FIELD: PERC OPT1',
            'MY PERC FIELD: PERC OPT2', 'MY PERC FIELD: PERC OPT3'])
          expect(subject.custom_fields_to_export_values(event)).to eq([nil, 0.3, 0.7, nil])
          expect(subject.custom_fields_to_export_values(event2)).to eq([nil, 0.1, 0.2, 0.7])
        end

        it 'does not merge custom fields of the same campaigns with the same name and type into the same column' do
          field1 = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
          field2 = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)

          event.results_for([field1]).first.value = 123
          event.results_for([field2]).first.value = 456
          event.save
          expect(event.save).to be_truthy

          expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD', 'MY NUMERIC FIELD'])
          expect(subject.custom_fields_to_export_values(event)).to match_array([
            123.0, 456.0
          ])
        end

        it 'does not merge custom fields of different campaigns with the SAME name but DIFFERENT type into the same column' do
          create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
          create(:form_field_text, name: 'My Numeric Field', fieldable: campaign2)

          expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD', 'MY NUMERIC FIELD'])
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

        expect(subject.custom_fields_to_export_headers).to eq(['MY KPI: UNO', 'MY KPI: DOS'])
        expect(subject.custom_fields_to_export_values(event)).to eq([0.88, 0.12])
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
        expect(subject.custom_fields_to_export_values(event)).to eq([nil, nil, nil])

        event.result_for_kpi(kpi).value = { seg1.id.to_s => '66', seg2.id.to_s => '34' }
        event.save

        expect(subject.custom_fields_to_export_values(event)).to eq([
          0.66, 0.34, nil
        ])

        event.result_for_kpi(kpi2).value = '666666'
        event.save

        expect(subject.custom_fields_to_export_headers).to eq([
          'MY KPI: UNO', 'MY KPI: DOS', 'A CUSTOM KPI'])
        expect(subject.custom_fields_to_export_values(event)).to eq([
          0.66, 0.34, 666_666])
      end

      it "returns nil for the fields that doesn't apply to the event's campaign" do
        campaign2 = create(:campaign, company: campaign.company)
        subject.params = { campaign: [campaign.id, campaign2.id] }

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

        expect(subject.custom_fields_to_export_headers).to eq(['A CUSTOM KPI', 'ANOTHER KPI'])

        expect(subject.custom_fields_to_export_values(event)).to eq([9876, nil])
        expect(subject.custom_fields_to_export_values(event2)).to eq([nil, 7654])
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

        expect(subject.custom_fields_to_export_headers).to eq(['ARE YOU GREAT?'])
        expect(subject.custom_fields_to_export_values(event)).to eq(['Yes'])
        expect(subject.custom_fields_to_export_values(event2)).to eq(['Yes'])
      end

      it 'returns custom kpis grouped on the same column' do
        campaign2 = create(:campaign, company: campaign.company)
        subject.params = { campaign: [campaign.id, campaign2.id] }

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

        expect(subject.custom_fields_to_export_headers).to eq(['A CUSTOM KPI', 'ANOTHER KPI'])

        expect(subject.custom_fields_to_export_values(event)).to eq([1111, 2222])
        expect(subject.custom_fields_to_export_values(event2)).to eq([3333, 4444])
      end

    end

    describe 'for activity data' do
      let(:resource_class) { Activity }

      it 'includes NUMBER fields' do
        field = create(:form_field_number, name: 'My Numeric Field', fieldable: activity_type)

        activity.results_for([field]).first.value = 123
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD'])
        expect(subject.custom_fields_to_export_values(activity)).to eq([123])
      end

      it 'includes RADIO fields' do
        field = create(:form_field_radio, name: 'My Radio Field',
          fieldable: activity_type, options: [
            option = create(:form_field_option, name: 'Radio Opt1'),
            create(:form_field_option, name: 'Radio Opt2')])

        activity.results_for([field]).first.value = option.id
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY RADIO FIELD'])
        expect(subject.custom_fields_to_export_values(activity)).to eq(['Radio Opt1'])
      end

      it 'includes CHECKBOX fields' do
        field = create(:form_field_checkbox, name: 'My Chk Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Chk Opt1'),
            option2 = create(:form_field_option, name: 'Chk Opt2')])

        activity.results_for([field]).first.value = { option1.id.to_s => 1, option2.id.to_s => 1 }
        activity.save
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY CHK FIELD: CHK OPT1', 'MY CHK FIELD: CHK OPT2'])
        expect(subject.custom_fields_to_export_values(activity)).to eq([
          'Yes',
          'Yes'
        ])
      end

      it 'includes DROPDOWN fields' do
        field = create(:form_field_dropdown, name: 'My Ddown Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Ddwon Opt1'),
            create(:form_field_option, name: 'Ddwon Opt2')])

        activity.results_for([field]).first.value = option1.id
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY DDOWN FIELD'])
        expect(subject.custom_fields_to_export_values(activity)).to eq(['Ddwon Opt1'])
      end

      it 'includes PERCENTAGE fields that are not linked to a KPI' do
        field = create(:form_field_percentage, name: 'My Perc Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Perc Opt1'),
            option2 = create(:form_field_option, name: 'Perc Opt2')])

        activity.results_for([field]).first.value = { option1.id.to_s => 30, option2.id.to_s => 70 }
        activity.save
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY PERC FIELD: PERC OPT1', 'MY PERC FIELD: PERC OPT2'])
        expect(subject.custom_fields_to_export_values(activity)).to eq([0.3, 0.7])
      end

      it 'includes SUMMATION fields that are not linked to a KPI' do
        field = create(:form_field_summation, name: 'My Summation Field',
          fieldable: activity_type, options: [
            option1 = create(:form_field_option, name: 'Sum Opt1'),
            option2 = create(:form_field_option, name: 'Sum Opt2')])

        activity.results_for([field]).first.value = { option1.id.to_s => 20, option2.id.to_s => 50 }
        activity.save
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq([
          'MY SUMMATION FIELD: SUM OPT1', 'MY SUMMATION FIELD: SUM OPT2', 'MY SUMMATION FIELD: TOTAL'
        ])
        expect(subject.custom_fields_to_export_values(activity)).to eq([
          '20', '50', 70.0
        ])
      end

      it 'includes BRAND fields' do
        field = create(:form_field_brand, name: 'My Brand Field',
          fieldable: activity_type)
        brand = create(:brand, name: 'My Brand', company: company)
        campaign.brands << brand

        activity.results_for([field]).first.value = brand.id
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY BRAND FIELD'])
        expect(subject.custom_fields_to_export_values(activity)).to eq(['My Brand'])
      end

      it 'includes TIME fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Time', name: 'My Time Field',
          fieldable: activity_type)

        activity.results_for([field]).first.value = '12:22 pm'
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY TIME FIELD'])
        expect(subject.custom_fields_to_export_values(activity)).to eq(['12:22 pm'])
      end

      it 'includes DATE fields that are not linked to a KPI' do
        field = create(:form_field, type: 'FormField::Date', name: 'My Date Field',
          fieldable: activity_type)

        activity.results_for([field]).first.value = '01/31/2014'
        expect(activity.save).to be_truthy

        expect(subject.custom_fields_to_export_headers).to eq(['MY DATE FIELD'])
        expect(subject.custom_fields_to_export_values(activity)).to eq(['01/31/2014'])
      end

      describe 'LIKERT SCALE fields' do
        let(:option1) { create(:form_field_option, name: 'LikertScale Opt1') }
        let(:option2) { create(:form_field_option, name: 'LikertScale Opt2') }
        let(:statement1) { create(:form_field_statement, name: 'LikertScale Stat1') }
        let(:statement2) { create(:form_field_statement, name: 'LikertScale Stat2') }
        let(:field) { create(:form_field_likert_scale, name: 'My LikertScale Field',
                                                       fieldable: activity_type,
                                                       multiple: false,
                                                       options: [option1, option2],
                                                       statements: [statement1, statement2]
                      )
        }

        it 'includes single answer LIKERT SCALE fields that are not linked to a KPI' do
          activity.results_for([field]).first.value = { statement1.id.to_s => option1.id.to_s,
                                                        statement2.id.to_s => option2.id.to_s }
          expect(activity.save).to be_truthy

          expect(subject.custom_fields_to_export_headers).to eq([
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE STAT2'
          ])
          expect(subject.custom_fields_to_export_values(activity)).to eq([
            'LikertScale Opt1', 'LikertScale Opt2'
          ])
        end

        it 'includes multiple answer LIKERT SCALE fields that are not linked to a KPI' do
          field.update_attribute(:multiple, true)
          activity.results_for([field]).first.value = { statement1.id.to_s => [option1.id.to_s],
                                                        statement2.id.to_s => [option1.id.to_s,
                                                                               option2.id.to_s] }
          expect(activity.save).to be_truthy

          expect(subject.custom_fields_to_export_headers).to eq([
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT1 - LIKERTSCALE OPT1',
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT1 - LIKERTSCALE OPT2',
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT2 - LIKERTSCALE OPT1',
            'MY LIKERTSCALE FIELD: LIKERTSCALE STAT2 - LIKERTSCALE OPT2'
          ])

          expect(subject.custom_fields_to_export_values(activity)).to eq([
            '1', nil, '1', '1'
          ])
        end
      end

      describe 'when filtered by activity_type' do
        let(:params) { { activity_type: [activity_type.id] } }

        it 'includes only fields that are assigned to the selected activity types' do
          activity_type2 = create(:activity_type, company: company)
          campaign.activity_types << activity_type2
          field1 = create(:form_field_number, name: 'My Numeric Field 1', fieldable: activity_type)
          field2 = create(:form_field_number, name: 'My Numeric Field 2', fieldable: activity_type2)

          activity.results_for([field1]).first.value = 123
          expect(activity.save).to be_truthy

          activity2 = create(:activity, activity_type: activity_type2, activitable: event, company_user: company_user)
          activity2.results_for([field2]).first.value = 666
          expect(activity2.save).to be_truthy

          expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD 1'])
          expect(subject.custom_fields_to_export_values(activity)).to eq([123])
        end
      end

      describe 'when filtered by activity_type and campaign ' do
        let(:params) { { activity_type: [activity_type.id], campaign: [campaign.id] } }

        it 'includes only fields that are assigned to the selected activity types' do
          activity_type2 = create(:activity_type, campaign_ids: [campaign.id], company: company)
          field1 = create(:form_field_number, name: 'My Numeric Field 1', fieldable: activity_type)
          field2 = create(:form_field_number, name: 'My Numeric Field 2', fieldable: activity_type2)

          activity.results_for([field1]).first.value = 123
          expect(activity.save).to be_truthy

          activity2 = create(:activity, activity_type: activity_type2, activitable: event, company_user: company_user)
          activity2.results_for([field2]).first.value = 666
          expect(activity2.save).to be_truthy

          expect(subject.custom_fields_to_export_headers).to eq(['MY NUMERIC FIELD 1'])
          expect(subject.custom_fields_to_export_values(activity)).to eq([123])
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

      expect(subject.area_for_event(event)).to eql 'MyArea'
    end

    it 'should return the area names separated by comma if more than one' do
      event = create(:event, campaign: campaign, place: place_la)

      area1 = create(:area, name: 'MyArea1', company: company)
      area2 = create(:area, name: 'MyArea2', company: company)

      area1.places << city_la
      area2.places << place_la
      campaign.areas << [area1, area2]

      expect(subject.area_for_event(event)).to eql 'MyArea1, MyArea2'
    end

    it 'should include the area if the place is part of a city included for it' do
      event = create(:event, campaign: campaign, place: place_la)

      area = create(:area, name: 'MyArea1', company: company)

      create(:areas_campaign, area: area, campaign: campaign, inclusions: [city_la.id])

      expect(subject.area_for_event(event)).to eql 'MyArea1'
    end

    it 'should NOT include the area if the place was excluded from it' do
      event = create(:event, campaign: campaign, place: place_la)

      area1 = create(:area, name: 'MyArea1', company: company)
      area2 = create(:area, name: 'MyArea2', company: company)

      area1.places << city_la
      area2.places << place_la
      create(:areas_campaign, area: area1, campaign: campaign)
      create(:areas_campaign, area: area2, campaign: campaign, exclusions: [place_la.id])

      expect(subject.area_for_event(event)).to eql 'MyArea1'
    end
  end
end
