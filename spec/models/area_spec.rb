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

describe Area, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_many(:campaigns).through(:areas_campaigns) }
  it { is_expected.to have_many(:areas_campaigns) }
  it { is_expected.to have_many(:placeables) }
  it { is_expected.to have_many(:places).through(:placeables) }
  it { is_expected.to validate_presence_of(:name) }

  describe '#activate' do
    let(:area) { build(:area, active: false) }

    it 'should return the active value as true' do
      area.activate!
      area.reload
      expect(area.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:area) { build(:area, active: false) }

    it 'should return the active value as false' do
      area.deactivate!
      area.reload
      expect(area.active).to be_falsey
    end
  end

  describe '#locations' do
    let(:area) { create(:area) }

    it 'should return the locations for continent, country, state and city' do
      place = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      expect(area.locations.map(&:path)).to match_array ['north america/united states/california/los angeles']
    end

    it 'should not return duplicated elements' do
      place = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      place2 = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      area.places << place2
      expect(area.locations.map(&:path)).to match_array ['north america/united states/california/los angeles']
    end

    it 'should all the paths for all place' do
      place = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      place2 = create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      area.places << place
      area.places << place2
      expect(area.locations.map(&:path)).to match_array ['north america/united states/california/los angeles', 'north america/united states/california/san francisco']
    end

    it 'should result the neighborhood on the path if the place has the type sublocality' do
      place = create(:place, name: 'Beverly Hills', types: ['sublocality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      expect(area.locations.map(&:path)).to match_array ['north america/united states/california/los angeles/beverly hills']
    end

    it 'should not include establishments as locations' do
      place = create(:place, name: 'Guille\'s Place', types: ['establishment'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      expect(area.locations).to be_empty
    end
  end

  describe '#update_common_denominators' do
    let(:area) { create(:area) }

    it 'should include the city if all the places are in the same city' do
      place  = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      place2 = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << place
      area.places << place2
      expect(area.common_denominators).to eq(['North America', 'United States', 'California', 'Los Angeles'])
      expect(area.common_denominators_locations.length).to eql 4
      paths = Location.where(id: area.common_denominators_locations).pluck(:path)
      expect(paths).to match_array [
        'north america',
        'north america/united states',
        'north america/united states/california',
        'north america/united states/california/los angeles'
      ]
    end

    it 'should include the up to the state if all the places are in the same state but different cities' do
      place  = create(:place, types: ['locality'], city: 'Los Angeles',   state: 'California', country: 'US')
      place2 = create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      area.places << place
      expect(area.reload.common_denominators).to eq(['North America', 'United States', 'California', 'Los Angeles'])
      area.places << place2
      expect(area.reload.common_denominators).to eq(['North America', 'United States', 'California'])
    end
  end

  describe '#place_in_scope?' do
    it 'should return false if place is nil' do
      area = create(:area)
      expect(area.place_in_scope?(nil)).to be_falsey
    end

    it 'should return true if the place belongs to the area' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      area = create(:area)
      area.places << create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')

      expect(area.place_in_scope?(bar)).to be_truthy
    end

    it "should return false if the place doesn't belongs to the area" do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'San Francisco', state: 'California', country: 'US')
      area = create(:area)
      area.places << create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      expect(area.place_in_scope?(bar)).to be_falsey
    end

    it 'should return false if the place is a state and the area has cities of that state' do
      california = create(:place, types: ['locality'], route: nil, street_number: nil, city: nil, state: 'California', country: 'US')
      area = create(:area)
      area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      area.places << create(:city, name: 'San Francisco', state: 'California', country: 'US')

      expect(area.place_in_scope?(california)).to be_falsey
    end

    it 'should return true if the place is a neighborhood and the area includes the city' do
      neighborhood = create(:place, types: ['locality'], route: nil, street_number: nil, neighborhood: 'South Central Houston', city: 'Houston', state: 'Texas', country: 'US')
      area = create(:area)
      area.places << create(:place, types: ['locality'], city: 'Houston', state: 'Texas', country: 'US')

      expect(area.place_in_scope?(neighborhood)).to be_truthy
    end

    it 'should return true if the place is directly assigned to the area' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      area = create(:area)
      area.places << bar

      expect(area.place_in_scope?(bar)).to be_truthy
    end
  end

  describe '#accessible_by_user' do
    describe 'for not admin role' do
      let(:company) { create(:company) }
      let(:user) { create(:company_user, company: company, role: create(:non_admin_role, company: company)) }

      it 'should return any areas assigned to the user' do
        create(:area, company: company) # another area
        area = create(:area, company: company)
        expect(Area.accessible_by_user(user).to_a).to be_empty
        user.areas << area
        expect(Area.accessible_by_user(user).to_a).to eql [area]
      end

      it "should return any within the scope of user's allowed locations" do
        create(:area, company: company) # another area
        area = create(:area, company: company)
        area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
        expect(Area.accessible_by_user(user).to_a).to be_empty
        user.places << create(:country, name: 'US')
        expect(Area.accessible_by_user(user).to_a).to eql [area]
      end

      it "should NOT return areas that have places outside the scope of user's allowed locations" do
        area = create(:area, company: company)
        area.places << [
          create(:city, name: 'Los Angeles', state: 'California', country: 'US'),
          create(:city, name: 'Curridabat', state: 'San Jose', country: 'CR')
        ]
        expect(Area.accessible_by_user(user).to_a).to be_empty
        user.places << create(:country, name: 'US')
        expect(Area.accessible_by_user(user).to_a).to be_empty
      end
    end
  end

  describe '#cities' do
    let(:area) { create(:area, company: create(:company)) }

    it 'should return emtpy if the area has no cities' do
      expect(area.cities).to eql []
    end

    it 'should return the cities added to the area' do
      area.places << create(:city, name: 'Los Angeles', state: 'California')
      area.places << create(:city, name: 'Austin', state: 'Texas')
      area.places << create(:city, name: 'Houston', state: 'Texas')
      expect(area.cities.map(&:name)).to eql ['Austin', 'Houston', 'Los Angeles']
    end

    it 'should not return non cities' do
      area.places << create(:place, city: 'Los Angeles', state: 'California')
      area.places << create(:state, name: 'California', country: 'US')
      area.places << create(:country, name: 'United States')
      expect(area.cities.map(&:name)).to eql []
    end
  end
end
