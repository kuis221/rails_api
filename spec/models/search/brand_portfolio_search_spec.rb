require 'spec_helper'

describe BrandPortfolio, type: :model, search: true do
  it "should search for brand portfolios" do
    # First populate the Database with some data
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    brand_portfolio = FactoryGirl.create(:brand_portfolio, company_id: 1, brand_ids: [brand.id])
    brand_portfolio2 = FactoryGirl.create(:brand_portfolio, company_id: 1, brand_ids: [brand.id, brand2.id])

    # Create a Brand Portfolio on company 2
    company2_brand_portfolio = FactoryGirl.create(:brand_portfolio, company_id: 2)

    Sunspot.commit

    # Search for all Brand Portfolios on a given Company
    expect(BrandPortfolio.do_search(company_id: 1).results).to match_array([brand_portfolio, brand_portfolio2])
    expect(BrandPortfolio.do_search(company_id: 2).results).to match_array([company2_brand_portfolio])

    # Search for brands associated to the Brand Portfolios
    expect(BrandPortfolio.do_search(company_id: 1, q: "brand,#{brand.id}").results).to match_array([brand_portfolio, brand_portfolio2])
    expect(BrandPortfolio.do_search(company_id: 1, q: "brand,#{brand2.id}").results).to match_array([brand_portfolio2])
    expect(BrandPortfolio.do_search(company_id: 1, brand: brand.id).results).to match_array([brand_portfolio, brand_portfolio2])
    expect(BrandPortfolio.do_search(company_id: 1, brand: brand2.id).results).to match_array([brand_portfolio2])
    expect(BrandPortfolio.do_search(company_id: 1, brand: [brand.id, brand2.id]).results).to match_array([brand_portfolio, brand_portfolio2])

    # Search for a given Brand Portfolio
    expect(BrandPortfolio.do_search({company_id: 1, q: "brand_portfolio,#{brand_portfolio.id}"}, true).results).to match_array([brand_portfolio])

    # Search for Brand Portfolios on a given status
    expect(BrandPortfolio.do_search(company_id: 1, status: ['Active']).results).to match_array([brand_portfolio, brand_portfolio2])
  end
end