# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :kpi do
    sequence(:name){|n| "Kpi #{n}"}
    description "MyText"
    kpi_type "number"
    capture_mechanism "integer"
    "module" "custom"
  end
end
