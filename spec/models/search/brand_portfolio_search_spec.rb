require 'spec_helper'

describe BrandPortfolio, search: true do
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
    BrandPortfolio.do_search(company_id: 1).results.should =~ [brand_portfolio, brand_portfolio2]
    BrandPortfolio.do_search(company_id: 2).results.should =~ [company2_brand_portfolio]

    # Search for brands associated to the Brand Portfolios
    BrandPortfolio.do_search(company_id: 1, q: "brand,#{brand.id}").results.should =~ [brand_portfolio, brand_portfolio2]
    BrandPortfolio.do_search(company_id: 1, q: "brand,#{brand2.id}").results.should =~ [brand_portfolio2]
    BrandPortfolio.do_search(company_id: 1, brand: brand.id).results.should =~ [brand_portfolio, brand_portfolio2]
    BrandPortfolio.do_search(company_id: 1, brand: brand2.id).results.should =~ [brand_portfolio2]
    BrandPortfolio.do_search(company_id: 1, brand: [brand.id, brand2.id]).results.should =~ [brand_portfolio, brand_portfolio2]

    # Search for a given Brand Portfolio
    BrandPortfolio.do_search({company_id: 1, q: "brand_portfolio,#{brand_portfolio.id}"}, true).results.should =~ [brand_portfolio]

    # Search for Brand Portfolios on a given status
    BrandPortfolio.do_search(company_id: 1, status: ['Active']).results.should =~ [brand_portfolio, brand_portfolio2]
  end
end