# == Schema Information
#
# Table name: areas_campaigns
#
#  id          :integer          not null, primary key
#  area_id     :integer
#  campaign_id :integer
#  exclusions  :integer          default([]), is an Array
#  inclusions  :integer          default([]), is an Array
#

require 'rails_helper'

describe AreasCampaign, type: :model do
  it { is_expected.to belong_to(:campaign) }
  it { is_expected.to belong_to(:area) }

  describe '#place_in_scope?' do
    let(:area) { create(:area) }
    let(:campaign) { create(:campaign) }
    let(:areas_campaign) { create(:areas_campaign, area: area, campaign: campaign) }

    it 'should return false if place is nil' do
      expect(areas_campaign.place_in_scope?(nil)).to be_falsey
    end

    it 'should return true if the place belongs to the area' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      area.places << create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')

      expect(areas_campaign.place_in_scope?(bar)).to be_truthy
    end

    it "should return false if the place doesn't belongs to the area" do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'San Francisco', state: 'California', country: 'US')
      area.places << create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      expect(areas_campaign.place_in_scope?(bar)).to be_falsey
    end

    it 'should return false if the place is a state and the area has cities of that state' do
      california = create(:place, types: ['locality'], route: nil, street_number: nil, city: nil, state: 'California', country: 'US')
      area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      area.places << create(:city, name: 'San Francisco', state: 'California', country: 'US')

      expect(areas_campaign.place_in_scope?(california)).to be_falsey
    end

    it 'should return true if the place is a neighborhood and the area includes the city' do
      neighborhood = create(:place, types: ['locality'], route: nil, street_number: nil, neighborhood: 'South Central Houston', city: 'Houston', state: 'Texas', country: 'US')
      area.places << create(:place, types: ['locality'], city: 'Houston', state: 'Texas', country: 'US')

      expect(areas_campaign.place_in_scope?(neighborhood)).to be_truthy
    end

    it 'should return true if the place is directly assigned to the area' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      area.places << bar

      expect(areas_campaign.place_in_scope?(bar)).to be_truthy
    end

    it 'should return false if the place is in the exclusions list' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      area.places << bar

      areas_campaign.exclusions = [bar.id]

      expect(areas_campaign.place_in_scope?(bar)).to be_falsey
    end

    it 'should return false if the place belongs to a exluded city' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      city = create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      area.places << city

      areas_campaign.exclusions = [city.id]

      expect(areas_campaign.place_in_scope?(bar)).to be_falsey
    end

    it 'should return true if the place is in the inclusions list' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')

      areas_campaign.inclusions = [bar.id]

      expect(areas_campaign.place_in_scope?(bar)).to be_truthy
    end
  end
end
