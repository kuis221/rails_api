# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    campaign_id 1
    start_date "01/23/2019"
    start_time "10:00am"
    end_date "01/23/2019"
    end_time "12:00pm"
    company_id 1
    aasm_state 'unsent'
    active true

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
