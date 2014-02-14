# == Schema Information
#
# Table name: td_linxes
#
#  id                     :integer          not null, primary key
#  store_code             :string(255)
#  retailer_dba_name      :string(255)
#  retailer_address       :string(255)
#  retailer_city          :string(255)
#  retailer_state         :string(255)
#  retailer_trade_channel :string(255)
#  license_type           :string(255)
#  fixed_address          :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :td_linx do
    store_code "MyString"
    retailer_dba_name "MyString"
    retailer_address "MyString"
    retailer_city "MyString"
    retailer_state "MyString"
    retailer_trade_channel "MyString"
    license_type "MyString"
  end
end
