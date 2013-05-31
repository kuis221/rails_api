# == Schema Information
#
# Table name: brand_portfolios_brands
#
#  id                 :integer          not null, primary key
#  brand_id           :integer
#  brand_portfolio_id :integer
#

class BrandPortfoliosBrand < ActiveRecord::Base
  belongs_to :brand
  belongs_to :brand_portfolio
end
