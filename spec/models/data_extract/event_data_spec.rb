# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

require 'rails_helper'

RSpec.describe DataExtract::EventData, type: :model do
  let(:company) { create(:company) }
  let(:user) { create(:company_user, company: company) }

  let(:campaign) { create(:campaign, name: 'Campaign Absolut FY12', company: company) }

  describe '#exportable_columns' do
    let(:subject) do
      described_class.new(company: company, current_user: user,
                    columns: %w(campaign_name start_date start_time end_date end_time event_status street place_city place_name place_state place_zipcode created_by created_at))
    end

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(campaign_name Campaign), ['end_date', 'End Date'], ['end_time', 'End Time'],
        ['start_date', 'Start Date'], ['start_time', 'Start Time'], ['place_street', 'Venue Street'],
        ['place_city', 'Venue City'], ['place_name', 'Venue Name'], ['place_state', 'Venue State'],
        ['place_zipcode', 'Venue ZIP Code'], ['event_team_members', 'Event Team'],
        ['event_status', 'Event Status'], ['status', 'Active State']])
    end

    it 'returns the campaign form fields' do
      subject.params = { 'campaign_id' => [campaign.id] }
      field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
      expect(subject.exportable_columns).to eql([
        %w(campaign_name Campaign), ['end_date', 'End Date'], ['end_time', 'End Time'],
        ['start_date', 'Start Date'], ['start_time', 'Start Time'], ['place_street', 'Venue Street'],
        ['place_city', 'Venue City'], ['place_name', 'Venue Name'], ['place_state', 'Venue State'],
        ['place_zipcode', 'Venue ZIP Code'], ['event_team_members', 'Event Team'],
        ['event_status', 'Event Status'], ['status', 'Active State'],
        ["ff_#{field.id}", 'My Numeric Field']])
    end

    it 'returns percentage segments as separate columns' do
      subject.params = { 'campaign_id' => [campaign.id] }
      field = create(:form_field_percentage,
                     fieldable: campaign, name: 'My percentage field',
                     options: [
                       option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                       option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                       option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
      )

      expect(subject.exportable_columns.slice(-3, 3)).to eql([
        ["ff_#{field.id}_#{option2.id}", 'My percentage field: Opt 2'],
        ["ff_#{field.id}_#{option3.id}", 'My percentage field: Opt 3'],
        ["ff_#{field.id}_#{option1.id}", 'My percentage field: Opt 1']])
    end

    it 'returns calcuations fields as separate columns' do
      subject.params = { 'campaign_id' => [campaign.id] }
      field = create(:form_field_calculation,
                     operation: '+', calculation_label: 'GRAND TOTAL',
                     fieldable: campaign, name: 'My sum field',
                     options: [
                       option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                       option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                       option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
      )

      expect(subject.exportable_columns.slice(-4, 4)).to eql([
        ["ff_#{field.id}_#{option2.id}", 'My sum field: Opt 2'],
        ["ff_#{field.id}_#{option3.id}", 'My sum field: Opt 3'],
        ["ff_#{field.id}_#{option1.id}", 'My sum field: Opt 1'],
        ["ff_#{field.id}__TOTAL", 'My sum field: GRAND TOTAL']])
    end

    it 'returns name for form fields place' do
      subject.params = { 'campaign_id' => [campaign.id] }
      field_place1 = create(:form_field_place, name: 'Place A', fieldable: campaign)
      field_place2 = create(:form_field_place, name: 'Place B', fieldable: campaign)

      expect(subject.exportable_columns.slice(-2, 2)).to eql([
        ["ff_#{field_place1.id}", 'Place A'],
        ["ff_#{field_place2.id}", 'Place B']])
    end
  end

  describe '#columns_definitions' do
    let(:subject) { described_class.new(company: company, current_user: user) }

    it 'includes all event fields' do
      subject.params = { 'campaign_id' => [campaign.id] }

      percentage_field = create(:form_field_percentage,
                                fieldable: campaign, name: 'My percentage field',
                                options: [
                                  option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                                  option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                                  option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
      )
      numeric_field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)

      expect(subject.columns_definitions).to include(
        "ff_#{percentage_field.id}_#{option2.id}".to_sym => "COALESCE(NULLIF(join_ff_#{percentage_field.id}.value->'#{option2.id}', ''), '0')::float",
        "ff_#{percentage_field.id}_#{option3.id}".to_sym => "COALESCE(NULLIF(join_ff_#{percentage_field.id}.value->'#{option3.id}', ''), '0')::float",
        "ff_#{percentage_field.id}_#{option1.id}".to_sym => "COALESCE(NULLIF(join_ff_#{percentage_field.id}.value->'#{option1.id}', ''), '0')::float",
        "ff_#{numeric_field.id}".to_sym => "join_ff_#{numeric_field.id}.value->'value'"
      )
    end

    it 'includes all calculation options including total' do
      subject.params = { 'campaign_id' => [campaign.id] }

      field = create(:form_field_calculation,
                     operation: '+', calculation_label: 'GRAND TOTAL',
                     fieldable: campaign, name: 'My sum field',
                     options: [
                       option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                       option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                       option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
      )

      expect(subject.columns_definitions).to include(
        "ff_#{field.id}_#{option2.id}".to_sym => "COALESCE(NULLIF(join_ff_#{field.id}.value->'#{option2.id}', ''), '0')::float",
        "ff_#{field.id}_#{option3.id}".to_sym => "COALESCE(NULLIF(join_ff_#{field.id}.value->'#{option3.id}', ''), '0')::float",
        "ff_#{field.id}_#{option1.id}".to_sym => "COALESCE(NULLIF(join_ff_#{field.id}.value->'#{option1.id}', ''), '0')::float",
        "ff_#{field.id}__TOTAL".to_sym => "COALESCE(NULLIF(join_ff_#{field.id}.value->'#{option2.id}', ''), '0')::float+"\
                                          "COALESCE(NULLIF(join_ff_#{field.id}.value->'#{option3.id}', ''), '0')::float+"\
                                          "COALESCE(NULLIF(join_ff_#{field.id}.value->'#{option1.id}', ''), '0')::float"
      )
    end
  end

  describe '#rows' do
    let(:subject) do
      described_class.new(company: company, current_user: user,
                                        columns: %w(campaign_name end_date end_time start_date start_time place_street place_city place_name place_state place_zipcode event_team_members event_status status))
    end

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      let(:event) do
        create(:event, campaign: campaign, start_date: '01/01/2014', start_time: '02:00 pm',
                       end_date: '01/01/2014', end_time: '03:00 pm', place: place,
                       users: [create(:company_user, company: company,
                                                     user: create(:user, first_name: 'Benito',
                                                                         last_name: 'Camelas'))]
        )
      end
      let(:place) do
        create(:place, name: 'My place', street_number: '21st', route: 'Jump Street',
                       city: 'Santa Rosa Beach', state: 'Florida')
      end
      before { event }

      it 'returns all the events in the company with all the columns' do
        event.users << create(:company_user, company: company,
                                             user: create(:user, first_name: 'Pedro', last_name: 'Almodovar'))
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '11:00 PM', '01/01/2014', '10:00 PM', '21st Jump Street',
           'Santa Rosa Beach', 'My place', 'Florida', '12345', 'Benito Camelas, Pedro Almodovar', 'Unsent', 'Active']
        ]
      end

      it 'ignores invalid columns names' do
        subject.columns = %w(campaign_name start_date ff_9999)
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014']
        ]
      end

      it 'returns all the results for the given campaign with the event data' do
        field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
        event.results_for([field]).first.value = '9876'
        event.save
        subject.params = { 'campaign_id' => [campaign.id] }
        subject.columns = ['campaign_name', 'start_date', "ff_#{field.id}"]
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '9876']
        ]
      end

      describe 'custom fields' do
        before { subject.params = { 'campaign_id' => [campaign.id] } }
        it 'returns the results for percentage fields' do
          field = create(:form_field_percentage,
                         fieldable: campaign,
                         options: [
                           option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                           option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                           option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
          )
          event.results_for([field]).first.value = {
            option1.id.to_s => 20, option2.id.to_s => 80,  option3.id.to_s => '' }
          event.save

          event2 = create(:event, campaign: campaign)
          event2.results_for([field]).first.value = {
            option2.id.to_s => 5, option1.id.to_s => 35,  option3.id.to_s => 60 }
          event2.save

          subject.columns = [
            'campaign_name', "ff_#{field.id}_#{option2.id}",
            "ff_#{field.id}_#{option3.id}", "ff_#{field.id}_#{option1.id}"]
          subject.default_sort_by = "ff_#{field.id}_#{option2.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  5.0, 60.0, 35.0],
            ['Campaign Absolut FY12',  80.0, 0.0, 20.0]
          ]
        end

        it 'returns the results for calculation ADD field' do
          subject.params = { 'campaign_id' => [campaign.id] }

          field = create(:form_field_calculation,
                         operation: '+', calculation_label: 'GRAND TOTAL', fieldable: campaign,
                         options: [
                           option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                           option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                           option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
          )

          event.results_for([field]).first.value = {
            option2.id.to_s => 5, option1.id.to_s => 35,  option3.id.to_s => '' }
          expect(event.save).to be_truthy

          event = create(:event, campaign: campaign)
          event.results_for([field]).first.value = {
            option2.id.to_s => 10, option1.id.to_s => 90,  option3.id.to_s => 20 }
          expect(event.save).to be_truthy

          subject.columns = [
            'campaign_name', "ff_#{field.id}_#{option2.id}", "ff_#{field.id}_#{option3.id}",
            "ff_#{field.id}_#{option1.id}", "ff_#{field.id}__TOTAL"]
          subject.default_sort_by = "ff_#{field.id}_#{option2.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  5.0, 0.0, 35.0, 40.0],
            ['Campaign Absolut FY12',  10.0, 20.0, 90.0, 120.0]
          ]
        end

        it 'returns the results for calculation MULTIPLY field' do
          subject.params = { 'campaign_id' => [campaign.id] }

          field = create(:form_field_calculation,
                         operation: '*', calculation_label: 'GRAND TOTAL', fieldable: campaign,
                         options: [
                           option1 = create(:form_field_option, name: 'Opt 1', ordering: 1),
                           option2 = create(:form_field_option, name: 'Opt 2', ordering: 2)]
          )

          event.results_for([field]).first.value = {
            option2.id.to_s => 5, option1.id.to_s => 5 }
          expect(event.save).to be_truthy

          event = create(:event, campaign: campaign)
          event.results_for([field]).first.value = {
            option2.id.to_s => 10, option1.id.to_s => 90 }
          expect(event.save).to be_truthy

          subject.columns = [
            'campaign_name', "ff_#{field.id}_#{option2.id}", "ff_#{field.id}_#{option1.id}",
            "ff_#{field.id}__TOTAL"]
          subject.default_sort_by = "ff_#{field.id}_#{option2.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  5.0, 5.0, 25.0],
            ['Campaign Absolut FY12',  10.0, 90.0, 900.0]
          ]
        end

        it 'returns the results for calculation DIVIDE field' do
          subject.params = { 'campaign_id' => [campaign.id] }

          field = create(:form_field_calculation,
                         operation: '/', calculation_label: 'GRAND TOTAL', fieldable: campaign,
                         options: [
                           option1 = create(:form_field_option, name: 'Opt 1', ordering: 1),
                           option2 = create(:form_field_option, name: 'Opt 2', ordering: 2)]
          )

          event.results_for([field]).first.value = {
            option2.id.to_s => 5, option1.id.to_s => 5 }
          expect(event.save).to be_truthy

          event = create(:event, campaign: campaign)
          event.results_for([field]).first.value = {
            option2.id.to_s => 10, option1.id.to_s => 100 }
          expect(event.save).to be_truthy

          subject.columns = [
            'campaign_name', "ff_#{field.id}_#{option2.id}", "ff_#{field.id}_#{option1.id}",
            "ff_#{field.id}__TOTAL"]
          subject.default_sort_by = "ff_#{field.id}_#{option2.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  5.0, 5.0, 1.0],
            ['Campaign Absolut FY12',  10.0, 100.0, 10.0]
          ]
        end

        it 'returns Infinity when dividing by 0' do
          subject.params = { 'campaign_id' => [campaign.id] }

          field = create(:form_field_calculation,
                         operation: '+', calculation_label: 'GRAND TOTAL', fieldable: campaign,
                         options: [
                           option1 = create(:form_field_option, name: 'Opt 1', ordering: 1),
                           option2 = create(:form_field_option, name: 'Opt 2', ordering: 2),
                           option3 = create(:form_field_option, name: 'Opt 3', ordering: 3)])

          event.results_for([field]).first.value = {
            option1.id.to_s => 5, option2.id.to_s => 0, option3.id.to_s => 4 }
          expect(event.save).to be_truthy

          field.update_attributes(operation: '/')

          subject.columns = [
            'campaign_name', "ff_#{field.id}_#{option1.id}", "ff_#{field.id}_#{option2.id}",
            "ff_#{field.id}_#{option3.id}", "ff_#{field.id}__TOTAL"]
          subject.default_sort_by = "ff_#{field.id}_#{option2.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  5.0, 0.0, 4.0, Float::INFINITY]
          ]
        end

        it 'returns the results for radio fields' do
          field = create(:form_field_radio,
                         fieldable: campaign,
                         options: [
                           option2 = create(:form_field_option, name: 'Opt 2', ordering: 1),
                           option1 = create(:form_field_option, name: 'Opt 1', ordering: 3),
                           option3 = create(:form_field_option, name: 'Opt 3', ordering: 2)]
          )
          event.results_for([field]).first.value = option1.id
          event.save

          event2 = create(:event, campaign: campaign)
          event2.results_for([field]).first.value = option3.id
          event2.save

          subject.columns = ['campaign_name', "ff_#{field.id}"]
          subject.default_sort_by = "ff_#{field.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  'Opt 1'],
            ['Campaign Absolut FY12',  'Opt 3']
          ]
        end

        it 'returns the results for place field' do
          place = create(:place, name: 'My place', street_number: '21st', route: 'Jump Street',
                       city: 'Santa Rosa Beach', state: 'Florida')
          place2 = create(:place, name: 'My place 2', street_number: '23st', route: 'Jump Street2',
                       city: 'Santa Rosa Beach', state: 'Florida')
          field = create(:form_field_place, fieldable: campaign)
          event.results_for([field]).first.value = place.id
          event.save

          event2 = create(:event, campaign: campaign)
          event2.results_for([field]).first.value = place2.id
          event2.save

          event3 = create(:event, campaign: campaign)
          event3.results_for([field]).first.value = ''
          event3.save

          subject.columns = ['campaign_name', "ff_#{field.id}"]
          subject.default_sort_by = "ff_#{field.id}"
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  'My place'],
            ['Campaign Absolut FY12',  'My place 2'],
            ['Campaign Absolut FY12',  nil]
          ]
        end

        it 'returns the results for kpis correctly' do
          kpi = create(:kpi, company: company, kpi_type: 'count', kpis_segments: [
            segment1 = build(:kpis_segment, text: 'Yes', ordering: 1),
            build(:kpis_segment, text: 'No', ordering: 2)
          ])
          field = campaign.add_kpi(kpi)

          event.result_for_kpi(kpi).value = segment1.id
          event.save

          subject.columns = ['campaign_name', "ff_#{field.id}"]
          expect(subject.rows).to eql [
            ['Campaign Absolut FY12',  'Yes']
          ]
        end
      end

      it 'returns only the requested columns' do
        subject.columns = %w(campaign_name start_date)
        expect(subject.rows).to eql [['Campaign Absolut FY12', '01/01/2014']]
      end

      it 'allows to filter the results' do
        subject.filters = { 'campaign' => [campaign.id + 1] }
        expect(subject.rows).to be_empty

        subject.filters = { 'campaign' => [campaign.id] }
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', '11:00 PM', '01/01/2014', '10:00 PM', '21st Jump Street',
           'Santa Rosa Beach', 'My place', 'Florida', '12345', 'Benito Camelas', 'Unsent', 'Active']
        ]
      end

      it 'allows to sort the results' do
        create(:event, campaign: create(:campaign, name: 'Campaign Absolut FY13', company: company),
                       start_date: '02/02/2014', start_time: '03:00 am',
                       end_date: '02/02/2014', end_time: '03:00 pm')

        subject.columns = %w(campaign_name start_date place_name)
        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', 'My place'],
          ['Campaign Absolut FY13', '02/02/2014', nil]
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY13', '02/02/2014', nil],
          ['Campaign Absolut FY12', '01/01/2014', 'My place']
        ]

        subject.default_sort_by = 'place_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY12', '01/01/2014', 'My place'],
          ['Campaign Absolut FY13', '02/02/2014', nil]
        ]

        subject.default_sort_by = 'place_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY13', '02/02/2014', nil],
          ['Campaign Absolut FY12', '01/01/2014', 'My place']
        ]

        create(:event, campaign: create(:campaign, name: 'Campaign Absolut FY13', company: company),
                       start_date: '02/02/2013', start_time: '03:00 am',
                       end_date: '02/02/2013', end_time: '03:00 pm')

        subject.default_sort_by = 'start_date'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY13', '02/02/2014', nil],
          ['Campaign Absolut FY12', '01/01/2014', 'My place'],
          ['Campaign Absolut FY13', '02/02/2013', nil]
        ]
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Campaign Absolut FY13', '02/02/2013', nil],
          ['Campaign Absolut FY12', '01/01/2014', 'My place'],
          ['Campaign Absolut FY13', '02/02/2014', nil]
        ]
      end
    end
  end
end
