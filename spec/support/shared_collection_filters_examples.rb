RSpec.shared_examples 'for active state bucket' do
  describe 'a controller that include the areas bucket' do
    it 'should return the correct buckets in the right order' do
      filters = subject.filters.find { |f| f[:label] == 'Active State' }
      expect(filters[:items].count).to eq(2)
      expect(filters[:items].first[:label]).to eq('Active')
      expect(filters[:items].last[:label]).to eq('Inactive')
    end
  end
end

RSpec.shared_examples 'for areas bucket' do
  describe 'a controller that include the areas bucket' do
    it 'should return the correct items for the Area bucket' do
      company_user.role.permission_for(:view_list, Event).save

      # Assigned area with a common place, it should be in the filters
      area = create(:area, name: 'Austin', company: company)
      area.places << create(:city, name: 'Bee Cave', state: 'Texas', country: 'US')
      company_user.areas << area

      # Unassigned area with a common place, it should be in the filters
      area_unassigned = create(:area, name: 'San Antonio', company: company)
      area_unassigned.places << create(:city, name: 'Schertz',
                                              state: 'Texas', country: 'US')

      # Unassigned area with not common place, it should not be in the filters
      area_not_in_filter = create(:area, name: 'Miami', company: company)
      area_not_in_filter.places << create(:city, name: 'Doral',
                                                 state: 'Florida', country: 'US')

      # Assigned area with not common place, it should be in the filters
      company_user.areas << create(:area, name: 'San Francisco', company: company)

      # Assigned place, itis the responsible for the common areas in the filters
      company_user.places << create(:state, name: 'Texas', country: 'US')

      areas_filters = subject.filters.find { |f| f[:label] == 'Areas' }
      expect(areas_filters[:items].count).to eql 3

      expect(areas_filters[:items].first[:label]).to eql 'Austin'
      expect(areas_filters[:items].second[:label]).to eql 'San Antonio'
      expect(areas_filters[:items].third[:label]).to eql 'San Francisco'
    end

    describe 'when a user only a place assiged to it' do
      it 'returns all the areas that have at least one place inside' do
        company_user.role.permission_for(:view_list, Event).save

        # This is one area that have one place inside US
        area = create(:area, name: 'Austin', company: company)
        area.places << create(:place, name: 'Bee Cave',
              city: 'Bee Cave', state: 'Texas',
              country: 'US', types: %w(locality political))

        # This is another area that have one place inside US
        area = create(:area, name: 'San Antonio', company: company)
        area.places << create(:place, name: 'Schertz',
              types: %w(locality political), city: 'Schertz', state: 'Texas', country: 'US')

        # This area doesn't  have one place in US
        area = create(:area, name: 'Centro America', company: company)
        area.places << create(:place, name: 'Costa Rica',
              types: %w(country political), city: 'Schertz', state: nil, country: 'CR')

        # The user have US as the allowed places
        company_user.places << create(:place,
                                      name: 'United States', types: %w(country political),
                                      city: nil, state: nil, country: 'US')

        # It should return the first two areas
        areas_filters = subject.filters.find { |f| f[:label] == 'Areas' }
        expect(areas_filters[:items].count).to eql 2
        expect(areas_filters[:items].first[:label]).to eql 'Austin'
        expect(areas_filters[:items].second[:label]).to eql 'San Antonio'
      end
    end
  end
end
