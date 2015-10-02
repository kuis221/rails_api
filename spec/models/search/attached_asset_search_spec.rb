require 'rails_helper'

describe AttachedAsset, type: :model, search: true do
  let(:company)  { create(:company) }
  it 'should search for roles' do
    # First populate the Database with some data
    brand = create(:brand)
    brand2 = create(:brand)
    campaign = create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    place = create(:place, name: 'Island Creek Oyster Bar', city: 'Boston', state: 'Massachusetts', lonlat: 'POINT(-71.094994 42.348774)')
    place2 = create(:place, name: 'Bar None', city: 'San Francisco', state: 'California', lonlat: 'POINT(-122.431913 37.79764)')
    venue = create(:venue, place: place, company_id: company.id)
    venue2 = create(:venue, place: place2, company_id: company.id)
    san_francisco = create(:city, name: 'San Francisco', state: 'California')
    venue_city = create(:venue, place: san_francisco, company_id: company.id)
    event = create(:event, campaign: campaign, place: place, start_date: '02/22/2013', end_date: '02/23/2013')
    event2 = create(:event, campaign: campaign2, place: place2, start_date: '03/22/2013', end_date: '03/22/2013')
    asset = create(:attached_asset, asset_type: 'photo', attachable: event, rating: 1)
    asset2 = create(:attached_asset, asset_type: 'document', attachable: event2, rating: 2)
    tag = create(:tag, company: company)
    tag2 = create(:tag, company: company)
    company_user1 = create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company)
    company_user2 = create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Cantinflas'), company: company)
    team = create(:team, name: 'Team A', company: company)
    asset.tags << tag
    asset2.tags << [tag, tag2]
    company_user1.update_attributes(team_ids: [team.id])
    company_user2.update_attributes(team_ids: [team.id])
    event.users << company_user1
    event.teams << team
    event2.users << company_user2

    # Search for all Attached Assets
    expect(search(company_id: company.id)).to match_array([asset, asset2])

    # Search for Attached Assets on a given type
    expect(search(company_id: company.id, asset_type: 'photo'))
      .to match_array([asset])
    expect(search(company_id: company.id, asset_type: 'document'))
      .to match_array([asset2])
    expect(search(company_id: company.id, asset_type: 'another'))
      .to match_array([])

    # Search for Attached Assets on a given user
    expect(search(company_id: company.id, user: [company_user1.id]))
      .to match_array([asset])
    expect(search(company_id: company.id, user: [company_user2.id]))
      .to match_array([asset2])
    expect(search(company_id: company.id, user: [company_user1.id, company_user2.id]))
      .to match_array([asset, asset2])

    # Search for brands associated to the Attached Assets
    expect(search(company_id: company.id, brand: brand.id))
      .to match_array([asset, asset2])
    expect(search(company_id: company.id, brand: brand2.id))
      .to match_array([asset2])
    expect(search(company_id: company.id, brand: [brand.id, brand2.id]))
      .to match_array([asset, asset2])

    # Search for campaigns associated to the Attached Assets
    expect(search(company_id: company.id, campaign: campaign.id))
      .to match_array([asset])
    expect(search(company_id: company.id, campaign: campaign2.id))
      .to match_array([asset2])
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id]))
      .to match_array([asset, asset2])

    # Search for a specific Attached Asset's place location
    expect(search(company_id: company.id, location: [place.location_id]))
      .to match_array([asset])
    expect(search(company_id: company.id, location: [place2.location_id]))
      .to match_array([asset2])
    expect(search(company_id: company.id, location: [place.location_id, place2.location_id]))
      .to match_array([asset, asset2])

    # Search for a specific Attached Asset's place
    expect(search(company_id: company.id, place: [place.id]))
      .to match_array([asset])
    expect(search(company_id: company.id, place: [place2.id]))
      .to match_array([asset2])
    expect(search(company_id: company.id, place: [place.id, place2.id]))
      .to match_array([asset, asset2])
    expect(search(company_id: company.id, place: [san_francisco.id]))
      .to match_array([asset2])

    # Search for a specific Attached Asset's venue
    expect(search(company_id: company.id, venue: [venue.id]))
      .to match_array([asset])
    expect(search(company_id: company.id, venue: [venue2.id]))
      .to match_array([asset2])
    expect(search(company_id: company.id, venue: [venue.id, venue2.id]))
      .to match_array([asset, asset2])
    expect(search(company_id: company.id, venue: [venue_city.id]))
      .to match_array([asset2])

    # Search for a specific tags
    expect(search(company_id: company.id, tag: [tag.id]))
      .to match_array([asset, asset2])
    expect(search(company_id: company.id, tag: [tag2.id]))
      .to match_array([asset2])
    expect(search(company_id: company.id, tag: [tag.id, tag2.id]))
      .to match_array([asset, asset2])

    # Search by rating
    expect(search(company_id: company.id, rating: [1]))
      .to match_array([asset])
    expect(search(company_id: company.id, rating: [2]))
      .to match_array([asset2])
    expect(search(company_id: company.id, rating: [1, 2]))
      .to match_array([asset, asset2])

    # Search by place
    expect(search(company_id: company.id, place: [place.id]))
      .to match_array([asset])
    expect(search(company_id: company.id, place: [place2.id]))
      .to match_array([asset2])
    expect(search(company_id: company.id, place: [place.id, place2.id]))
      .to match_array([asset, asset2])

    # Search for Attached Assets on a given date range
    expect(search(company_id: company.id, start_date: ['02/21/2013'], end_date: ['02/23/2013']))
      .to match_array([asset])
    expect(search(company_id: company.id, start_date: ['02/22/2013'])).to match_array([asset])
    expect(search(company_id: company.id, start_date: ['03/21/2013'], end_date: ['03/23/2013']))
      .to match_array([asset2])
    expect(search(company_id: company.id, start_date: ['03/22/2013'])).to match_array([asset2])
    expect(search(company_id: company.id, start_date: ['01/21/2013'], end_date: ['01/23/2013']))
      .to be_empty

    # Search for Attached Assets on a given status
    expect(search(company_id: company.id, status: ['Active'])).to match_array([asset, asset2])
  end
end
