require 'spec_helper'

describe AttachedAsset, search: true do
  it "should search for roles" do
    # First populate the Database with some data
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    campaign = FactoryGirl.create(:campaign, company_id: 1, brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company_id: 1, brand_ids: [brand.id, brand2.id])
    place = FactoryGirl.create(:place, name: 'Island Creek Oyster Bar', city: "Boston", latitude: '42.348774', longitude: '-71.094994')
    place2 = FactoryGirl.create(:place, name: 'Bar None', city: "San Francisco", latitude: '37.79764', longitude: '-122.431913')
    venue = FactoryGirl.create(:venue, place: place, company_id: 1)
    venue2 = FactoryGirl.create(:venue, place: place2, company_id: 1)
    event = FactoryGirl.create(:event, company_id: 1, campaign: campaign, place: place, start_date: "02/22/2013", end_date: "02/23/2013")
    event2 = FactoryGirl.create(:event, company_id: 1, campaign: campaign2, place: place2, start_date: "03/22/2013", end_date: "03/22/2013")
    asset = FactoryGirl.create(:attached_asset, asset_type: 'photo', attachable: event)
    asset2 = FactoryGirl.create(:attached_asset, asset_type: 'document', attachable: event2)

    Sunspot.commit

    # Search for all Attached Assets
    AttachedAsset.do_search(company_id: 1).results.should =~ [asset, asset2]

    # Search for Attached Assets on a given type
    AttachedAsset.do_search(company_id: 1, asset_type: 'photo').results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, asset_type: 'document').results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, asset_type: 'another').results.should =~ []

    # Search for brands associated to the Attached Assets
    AttachedAsset.do_search(company_id: 1, q: "brand,#{brand.id}").results.should =~ [asset, asset2]
    AttachedAsset.do_search(company_id: 1, q: "brand,#{brand2.id}").results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, brand: brand.id).results.should =~ [asset, asset2]
    AttachedAsset.do_search(company_id: 1, brand: brand2.id).results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, brand: [brand.id, brand2.id]).results.should =~ [asset, asset2]

    # Search for campaigns associated to the Attached Assets
    AttachedAsset.do_search({company_id: 1, q: "campaign,#{campaign.id}"}, true).results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, q: "campaign,#{campaign2.id}").results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, campaign: campaign.id).results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, campaign: campaign2.id).results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, campaign: [campaign.id, campaign2.id]).results.should =~ [asset, asset2]

    # Search for a specific Attached Asset's place
    place_id = "#{Place.location_for_index(place)}||#{place.name}"
    place2_id = "#{Place.location_for_index(place2)}||#{place2.name}"
    AttachedAsset.do_search(company_id: 1, q: "venue,#{venue.id}").results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, q: "venue,#{venue2.id}").results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, place: [Base64.encode64(place_id)]).results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, place: [Base64.encode64(place2_id)]).results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, place: [Base64.encode64(place_id), Base64.encode64(place2_id)]).results.should =~ [asset, asset2]

    # Search for Attached Assets on a given date range
    AttachedAsset.do_search(company_id: 1, start_date: '02/21/2013', end_date: '02/23/2013').results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, start_date: '02/22/2013').results.should =~ [asset]
    AttachedAsset.do_search(company_id: 1, start_date: '03/21/2013', end_date: '03/23/2013').results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, start_date: '03/22/2013').results.should =~ [asset2]
    AttachedAsset.do_search(company_id: 1, start_date: '01/21/2013', end_date: '01/23/2013').results.should == []

    # Search for Attached Assets on a given status
    AttachedAsset.do_search(company_id: 1, status: ['Active']).results.should =~ [asset, asset2]
  end
end