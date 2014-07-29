# == Schema Information
#
# Table name: brand_portfolios
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  active        :boolean          default(TRUE)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  description   :text
#

require 'spec_helper'

describe BrandPortfolio do
  it { should validate_presence_of(:name) }

  describe "#activate" do
    let(:brand_portfolio) { FactoryGirl.build(:brand_portfolio, active: false) }

    it "should return the active value as true" do
      brand_portfolio.activate!
      brand_portfolio.reload
      brand_portfolio.active.should be_truthy
    end
  end

  describe "#deactivate" do
    let(:brand_portfolio) { FactoryGirl.build(:brand_portfolio, active: false) }

    it "should return the active value as false" do
      brand_portfolio.deactivate!
      brand_portfolio.reload
      brand_portfolio.active.should be_falsey
    end
  end
end
