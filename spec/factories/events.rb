# == Schema Information
#
# Table name: events
#
#  id             :integer          not null, primary key
#  campaign_id    :integer
#  company_id     :integer
#  start_at       :datetime
#  end_at         :datetime
#  aasm_state     :string(255)
#  created_by_id  :integer
#  updated_by_id  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  active         :boolean          default(TRUE)
#  place_id       :integer
#  promo_hours    :decimal(6, 2)    default(0.0)
#  reject_reason  :text
#  summary        :text
#  timezone       :string(255)
#  local_start_at :datetime
#  local_end_at   :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :event do
    start_date "01/23/2019"
    start_time "10:00am"
    end_date "01/23/2019"
    end_time "12:00pm"
    aasm_state 'unsent'
    active true

    ignore do
      results false
      expenses []
    end

    # To keep the associations between campaign and company correct
    after(:build) do |event, evaluator|
      if event.company.present?
        event.campaign ||= FactoryGirl.create(:campaign, company: event.company)
      end
      event.campaign ||= FactoryGirl.create(:campaign)
      event.company ||= event.campaign.company if event.campaign.present?
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
      aasm_state 'rejected'
    end

    factory :submitted_event do
      aasm_state 'submitted'
    end

    factory :due_event do
      aasm_state 'unsent'
      start_date { Date.yesterday.to_s(:slashes) }
      end_date { Date.yesterday.to_s(:slashes) }
    end

    factory :late_event do
      aasm_state 'unsent'
      start_date 3.weeks.ago.to_s(:slashes)
      end_date 3.weeks.ago.to_s(:slashes)
    end
  end
end
