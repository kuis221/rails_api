# == Schema Information
#
# Table name: areas
#
#  id                            :integer          not null, primary key
#  name                          :string(255)
#  description                   :text
#  active                        :boolean          default(TRUE)
#  company_id                    :integer
#  created_by_id                 :integer
#  updated_by_id                 :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  common_denominators           :text
#  common_denominators_locations :integer          default([]), is an Array
#

require 'rails_helper'

describe AreasCampaign, :type => :model do
  it { is_expected.to belong_to(:campaign) }
  it { is_expected.to belong_to(:area) }

  describe "#place_in_scope?" do
    let(:area) { FactoryGirl.create(:area) }
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:areas_campaign) { FactoryGirl.create(:areas_campaign, area: area, campaign: campaign) }

    it "should return false if place is nil" do
      expect(areas_campaign.place_in_scope?(nil)).to be_falsey
    end

    it "should return true if the place belongs to the area" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'Los Angeles', state:'California', country:'US')
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state:'California', country:'US')

      expect(areas_campaign.place_in_scope?(bar)).to be_truthy
    end

    it "should return false if the place doesn't belongs to the area" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'San Francisco', state:'California', country:'US')
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state:'California', country:'US')
      expect(areas_campaign.place_in_scope?(bar)).to be_falsey
    end

    it "should return false if the place is a state and the area has cities of that state" do
      california = FactoryGirl.create(:place, types: ['locality'], route:nil, street_number: nil, city: nil, state:'California', country:'US')
      area.places << FactoryGirl.create(:city, name: 'Los Angeles', state:'California', country:'US')
      area.places << FactoryGirl.create(:city, name: 'San Francisco', state:'California', country:'US')

      expect(areas_campaign.place_in_scope?(california)).to be_falsey
    end

    it "should return true if the place is a neighborhood and the area includes the city" do
      neighborhood = FactoryGirl.create(:place, types: ['locality'], route:nil, street_number: nil, neighborhood: 'South Central Houston', city: 'Houston', state:'Texas', country:'US')
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Houston', state:'Texas', country:'US')

      expect(areas_campaign.place_in_scope?(neighborhood)).to be_truthy
    end

    it "should return true if the place is directly assigned to the area" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'Los Angeles', state:'California', country:'US')
      area.places << bar

      expect(areas_campaign.place_in_scope?(bar)).to be_truthy
    end

    it "should return false if the place is in the exclusions list" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'Los Angeles', state:'California', country:'US')
      area.places << bar

      areas_campaign.exclusions = [bar.id]

      expect(areas_campaign.place_in_scope?(bar)).to be_falsey
    end

    it "should return false if the place belongs to a exluded city" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'Los Angeles', state:'California', country:'US')
      city = FactoryGirl.create(:city, name: 'Los Angeles', state:'California', country:'US')
      area.places << city

      areas_campaign.exclusions = [city.id]

      expect(areas_campaign.place_in_scope?(bar)).to be_falsey
    end
  end
end
