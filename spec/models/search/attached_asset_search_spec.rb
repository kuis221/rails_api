require 'rails_helper'

describe AttachedAsset, type: :model, search: true do
  it "should search for roles" do
    # First populate the Database with some data
    company = FactoryGirl.create(:company)
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    campaign = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    place = FactoryGirl.create(:place, name: 'Island Creek Oyster Bar', city: "Boston", latitude: '42.348774', longitude: '-71.094994')
    place2 = FactoryGirl.create(:place, name: 'Bar None', city: "San Francisco", latitude: '37.79764', longitude: '-122.431913')
    venue = FactoryGirl.create(:venue, place: place, company_id: company.id)
    venue2 = FactoryGirl.create(:venue, place: place2, company_id: company.id)
    event = FactoryGirl.create(:event, campaign: campaign, place: place, start_date: "02/22/2013", end_date: "02/23/2013")
    event2 = FactoryGirl.create(:event, campaign: campaign2, place: place2, start_date: "03/22/2013", end_date: "03/22/2013")
    asset = FactoryGirl.create(:attached_asset, asset_type: 'photo', attachable: event)
    asset2 = FactoryGirl.create(:attached_asset, asset_type: 'document', attachable: event2)

    Sunspot.commit

    # Search for all Attached Assets
    expect(AttachedAsset.do_search(company_id: company.id).results).to match_array([asset, asset2])

    # Search for Attached Assets on a given type
    expect(AttachedAsset.do_search(company_id: company.id, asset_type: 'photo').results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, asset_type: 'document').results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, asset_type: 'another').results).to match_array([])

    # Search for brands associated to the Attached Assets
    expect(AttachedAsset.do_search(company_id: company.id, q: "brand,#{brand.id}").results).to match_array([asset, asset2])
    expect(AttachedAsset.do_search(company_id: company.id, q: "brand,#{brand2.id}").results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, brand: brand.id).results).to match_array([asset, asset2])
    expect(AttachedAsset.do_search(company_id: company.id, brand: brand2.id).results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, brand: [brand.id, brand2.id]).results).to match_array([asset, asset2])

    # Search for campaigns associated to the Attached Assets
    expect(AttachedAsset.do_search({company_id: company.id, q: "campaign,#{campaign.id}"}, true).results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, q: "campaign,#{campaign2.id}").results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, campaign: campaign.id).results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, campaign: campaign2.id).results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, campaign: [campaign.id, campaign2.id]).results).to match_array([asset, asset2])

    # Search for a specific Attached Asset's place
    expect(AttachedAsset.do_search(company_id: company.id, q: "venue,#{venue.id}").results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, q: "venue,#{venue2.id}").results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, location: [place.location_id]).results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, location: [place2.location_id]).results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, location: [place.location_id, place2.location_id]).results).to match_array([asset, asset2])

    # Search for Attached Assets on a given date range
    expect(AttachedAsset.do_search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013').results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, start_date: '02/22/2013').results).to match_array([asset])
    expect(AttachedAsset.do_search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013').results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, start_date: '03/22/2013').results).to match_array([asset2])
    expect(AttachedAsset.do_search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013').results).to eq([])

    # Search for Attached Assets on a given status
    expect(AttachedAsset.do_search(company_id: company.id, status: ['Active']).results).to match_array([asset, asset2])
  end
end