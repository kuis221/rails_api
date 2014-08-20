# == Schema Information
#
# Table name: areas
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  description         :text
#  active              :boolean          default(TRUE)
#  company_id          :integer
#  created_by_id       :integer
#  updated_by_id       :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  common_denominators :text
#

require 'rails_helper'

describe Area, :type => :model do
  it { is_expected.to belong_to(:company) }

  it { is_expected.to validate_presence_of(:name) }


  describe "#activate" do
    let(:area) { FactoryGirl.build(:area, active: false) }

    it "should return the active value as true" do
      area.activate!
      area.reload
      expect(area.active).to be_truthy
    end
  end

  describe "#deactivate" do
    let(:area) { FactoryGirl.build(:area, active: false) }

    it "should return the active value as false" do
      area.deactivate!
      area.reload
      expect(area.active).to be_falsey
    end
  end

  describe "#locations" do
    let(:area) { FactoryGirl.create(:area) }

    it "should return the locations for continent, country, state and city" do
      place = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      expect(area.locations.map(&:path)).to match_array ["north america/united states/california/los angeles"]
    end

    it "should not return duplicated elements" do
      place = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      place2 = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      area.places << place2
      expect(area.locations.map(&:path)).to match_array ["north america/united states/california/los angeles"]
    end

    it "should all the paths for all place" do
      place = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      place2 = FactoryGirl.create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      area.places << place
      area.places << place2
      expect(area.locations.map(&:path)).to match_array ["north america/united states/california/los angeles", "north america/united states/california/san francisco"]
    end

    it "should result the neighborhood on the path if the place has the type sublocality" do
      place = FactoryGirl.create(:place, name:'Beverly Hills', types: ['sublocality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      expect(area.locations.map(&:path)).to match_array ["north america/united states/california/los angeles/beverly hills"]
    end

    it "should not include establishments as locations" do
      place = FactoryGirl.create(:place, name: 'Guille\'s Place', types: ['establishment'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      expect(area.locations).to be_empty
    end
  end


  describe "#update_common_denominators" do
    let(:area) { FactoryGirl.create(:area) }

    it "should include the city if all the places are in the same city" do
      place  = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      place2 = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      area.places << place2
      expect(area.common_denominators).to eq(["North America","United States","California","Los Angeles"])
    end

    it "should include the up to the state if all the places are in the same state but different cities" do
      place  = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles',   state: 'California', country: 'US')
      place2 = FactoryGirl.create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      area.places << place
      expect(area.reload.common_denominators).to eq(["North America","United States","California", "Los Angeles"])
      area.places << place2
      expect(area.reload.common_denominators).to eq(["North America","United States","California"])
    end
  end

  describe "#place_in_scope?" do
    it "should return false if place is nil" do
      area = FactoryGirl.create(:area)
      expect(area.place_in_scope?(nil)).to be_falsey
    end

    it "should return true if the place belogns to the area" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'Los Angeles', state:'California', country:'US')
      area = FactoryGirl.create(:area)
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state:'California', country:'US')

      expect(area.place_in_scope?(bar)).to be_truthy
    end

    it "should return false if the place belogns to the area" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'San Francisco', state:'California', country:'US')
      area = FactoryGirl.create(:area)
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state:'California', country:'US')
      expect(area.place_in_scope?(bar)).to be_falsey
    end

    it "should return false if the place is a state and the area has cities of that state" do
      california = FactoryGirl.create(:place, types: ['locality'], route:nil, street_number: nil, city: nil, state:'California', country:'US')
      area = FactoryGirl.create(:area)
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state:'California', country:'US')
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'San Francisco', state:'California', country:'US')

      expect(area.place_in_scope?(california)).to be_falsey
    end

    it "should return true if the place is a neighborhood and the area includes the city" do
      neighborhood = FactoryGirl.create(:place, types: ['locality'], route:nil, street_number: nil, neighborhood: 'South Central Houston', city: 'Houston', state:'Texas', country:'US')
      area = FactoryGirl.create(:area)
      area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Houston', state:'Texas', country:'US')

      expect(area.place_in_scope?(neighborhood)).to be_truthy
    end
  end
end
