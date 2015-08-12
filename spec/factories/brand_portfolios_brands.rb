# == Schema Information
#
# Table name: brand_portfolios
#
#  id                    :integer          not null, primary key
#  brand_id              :integer
#  brand_portfolio_id    :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand_portfolios_brand do
    brand
    brand_portfolio
  end
end
