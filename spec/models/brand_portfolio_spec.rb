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

require 'rails_helper'

describe BrandPortfolio, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  describe '#activate' do
    let(:brand_portfolio) { build(:brand_portfolio, active: false) }

    it 'should return the active value as true' do
      brand_portfolio.activate!
      brand_portfolio.reload
      expect(brand_portfolio.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:brand_portfolio) { build(:brand_portfolio, active: false) }

    it 'should return the active value as false' do
      brand_portfolio.deactivate!
      brand_portfolio.reload
      expect(brand_portfolio.active).to be_falsey
    end
  end

  describe '#accessible_by_user' do
    let!(:company) { create :company }
    let!(:company_user) { create :company_user, company: company }

    let!(:brand_portfolio1) { create :brand_portfolio, company: company }
    let!(:brand_portfolio2) { create :brand_portfolio, company: company }

    let(:collection) { described_class.accessible_by_user(company_user).all }

    it 'should return all company brand portfolios' do
      expect(collection).to match_array([brand_portfolio1, brand_portfolio2])
    end
  end
end
