# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    campaign_id 1
    start_date "01/23/2019"
    start_time "10:00am"
    end_date "01/23/2019"
    end_time "12:00pm"
    company_id 1
    active true

    ignore do
      results false
      expenses []
    end

    before(:create) do |event, evaluator|
      evaluator.expenses.each do |attrs|
        ex = event.event_expenses.build(attrs, without_protection: true)
      end

      if results = evaluator.results
        Kpi.create_global_kpis if Kpi.impressions.nil?
        event.campaign.assign_all_global_kpis if event.campaign.form_fields.empty?
        set_event_results(event, results, false)
      end

    end

    factory :approved_event do
      aasm_state 'approved'
    end

    factory :rejected_event do
      aasm_state 'approved'
    end

    factory :submitted_event do
      aasm_state 'submitted'
    end
  end
end
