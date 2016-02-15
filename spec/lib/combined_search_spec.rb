require 'rails_helper'

describe CombinedSearch, type: :model do
  describe '#search', search: true do
    let(:google_results) { { results: [] } }
    let(:company_user) { create(:company_user, role: create(:non_admin_role)) }

    describe 'without stubbed google results' do
      it 'rescue from errors when fetching results form Google' do
        expect_any_instance_of(described_class).to receive(:open) { fail OpenURI::HTTPError.new('', double(:io)) }

        params = { q: 'qw', current_company_user: company_user }
        expect(described_class.new(params).results).to be_empty
      end
    end

    describe 'with stubbed google results' do
      before do
        expect_any_instance_of(described_class).to receive(:open).and_return(
          double(read: JSON.generate(google_results))
        )
      end

      it 'should return empty if no results' do
        expect(described_class.new(q: 'aa').results).to eql []
      end

      it 'reuturs only places valid for the current user' do
        venue = create(:venue,
                       place: create(:place, name: 'Qwerty', city: 'AB', state: 'California', country: 'CR'),
                       company: company_user.company)
        create(:venue,
               place: create(:place, name: 'Qwerty', city: 'XY', state: 'California', country: 'CR'),
               company: company_user.company)

        Sunspot.commit

        company_user.places << create(:city, name: 'AB', state: 'California', country: 'CR')

        params = { q: 'qw', current_company_user: company_user }
        expect(described_class.new(params).results).to eql [
          {
            value: 'Qwerty, 123 My Street',
            label: 'Qwerty, 123 My Street',
            id: venue.place_id,
            location: { latitude: nil, longitude: nil },
            valid: true
          }
        ]
      end

      describe 'with results form Google API' do
        let(:google_results) do
          {
            results: [
              {
                'formatted_address' => 'Los Angeles, CA, USA',
                'place_id' => 'PLACEID1',
                'name' => 'Los Angeles',
                'reference' => 'REFERENCE1',
                'types' => %w(locality political),
                'geometry' => { 'location' => { 'lat' => 22.22, 'lng' => 33.33 }  }
              }, {
                'formatted_address' => 'Los Angeles, ON, Canada',
                'place_id' => 'PLACEID2',
                'name' => 'Los Angeles',
                'reference' => 'REFERENCE2',
                'types' => %w(locality political),
                'geometry' => { 'location' => { 'lat' => 11.22, 'lng' => 22.33 }  }
              }, {
                'formatted_address' => 'Tower 42, Los Angeles, CA 23211, United States',
                'place_id' => 'PLACEID3',
                'name' => 'Vertigo 42',
                'reference' => 'REFERENCE3',
                'types' => %w(food bar establishment),
                'geometry' => { 'location' => { 'lat' => 11.11, 'lng' => 44.44 }  }
              }, {
                'formatted_address' => 'St Petersburg, Florida, United States',
                'place_id' => 'PLACEID4',
                'name' => 'St Petersburg',
                'city' => 'St Petersburg',
                'reference' => 'REFERENCE4',
                'types' => %w(locality political),
                'geometry' => { 'location' => { 'lat' => 33.33, 'lng' => 55.55 }  }
              }, {
                'formatted_address' => 'Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
                'place_id' => 'PLACEID5',
                'name' => 'Sheikh Zayed Road',
                'city' => 'Sheikh Zayed Road',
                'reference' => 'REFERENCE5',
                'types' => %w(locality political),
                'geometry' => { 'location' => { 'lat' => 66.66, 'lng' => 77.77 }  }
              }
            ]
          }
        end

        it "should include all the places returned by google with the 'valid' flag set to false" do
          params = { q: 'qw', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Los Angeles, CA, USA',
              label: 'Los Angeles, CA, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: false
            },
            {
              value: 'Los Angeles, ON, Canada',
              label: 'Los Angeles, ON, Canada',
              id: 'REFERENCE2||PLACEID2',
              location: { latitude: 11.22, longitude: 22.33 },
              valid: false
            },
            {
              value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              id: 'REFERENCE3||PLACEID3',
              location: { latitude: 11.11, longitude: 44.44 },
              valid: false
            },
            {
              value: 'St Petersburg, Florida, United States',
              label: 'St Petersburg, Florida, United States',
              id: 'REFERENCE4||PLACEID4',
              location: { latitude: 33.33, longitude: 55.55 },
              valid: false
            },
            {
              value: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              label: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              id: 'REFERENCE5||PLACEID5',
              location: { latitude: 66.66, longitude: 77.77 },
              valid: false
            }
          ]
        end

        it "should set the 'valid' flag to true for places the user is allowed to access" do
          company_user.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
          company_user.places << create(:city, name: 'St Petersburg', state: 'Florida', country: 'US')
          company_user.places << create(:place, name: 'United Arab Emirates', city: nil, state: nil, country: 'AE', types: %w(political country))
          params = { q: 'qw', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Los Angeles, CA, USA',
              label: 'Los Angeles, CA, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            },
            {
              value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              id: 'REFERENCE3||PLACEID3',
              location: { latitude: 11.11, longitude: 44.44 },
              valid: true
            },
            {
              value: 'St Petersburg, Florida, United States',
              label: 'St Petersburg, Florida, United States',
              id: 'REFERENCE4||PLACEID4',
              location: { latitude: 33.33, longitude: 55.55 },
              valid: true
            },
            {
              value: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              label: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              id: 'REFERENCE5||PLACEID5',
              location: { latitude: 66.66, longitude: 77.77 },
              valid: true
            },
            {
              value: 'Los Angeles, ON, Canada',
              label: 'Los Angeles, ON, Canada',
              id: 'REFERENCE2||PLACEID2',
              location: { latitude: 11.22, longitude: 22.33 },
              valid: false
            }
          ]
        end

        it "returns mixed places from Google and the app listing app's places first" do
          venue = create(:venue,
                         place: create(:place, name: 'Qwerty', city: 'Los Angeles',
                                               state: 'California', country: 'US',
                                               lonlat: 'POINT(1 2)'),
                         company: company_user.company)
          create(:venue,
                 place: create(:place, name: 'Qwerty', city: 'XY', state: 'California', country: 'CR'),
                 company: company_user.company)

          Sunspot.commit

          company_user.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

          params = { q: 'Angeles', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Qwerty, 123 My Street',
              label: 'Qwerty, 123 My Street',
              id: venue.place_id,
              location: { latitude: 2.0, longitude: 1.0 },
              valid: true
            },
            {
              value: 'Los Angeles, CA, USA',
              label: 'Los Angeles, CA, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            },
            {
              value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              id: 'REFERENCE3||PLACEID3',
              location: { latitude: 11.11, longitude: 44.44 },
              valid: true
            },
            {
              value: 'Los Angeles, ON, Canada',
              label: 'Los Angeles, ON, Canada',
              id: 'REFERENCE2||PLACEID2',
              location: { latitude: 11.22, longitude: 22.33 },
              valid: false
            },
            {
              value: 'St Petersburg, Florida, United States',
              label: 'St Petersburg, Florida, United States',
              id: 'REFERENCE4||PLACEID4',
              location: { latitude: 33.33, longitude: 55.55 },
              valid: false
            },
            {
              value: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              label: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              id: 'REFERENCE5||PLACEID5',
              location: { latitude: 66.66, longitude: 77.77 },
              valid: false
            }
          ]
        end

        it 'returns places from Google and the app removing repeated places from Google' do
          venue = create(:venue,
                         place: create(:place, name: 'Vertigo 42',
                                               reference: 'REFERENCE3',
                                               place_id: 'PLACEID3',
                                               formatted_address: 'Tower 42, Los Angeles, CA 23211, United States',
                                               city: 'Los Angeles', state: 'California', country: 'US',
                                               lonlat: 'POINT(44.44 11.11)'),
                         company: company_user.company)

          Sunspot.commit

          company_user.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

          params = { q: 'Vertigo', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              id: venue.place_id,
              location: { latitude: 11.11, longitude: 44.44 },
              valid: true
            },
            {
              value: 'Los Angeles, CA, USA',
              label: 'Los Angeles, CA, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            },
            {
              value: 'Los Angeles, ON, Canada',
              label: 'Los Angeles, ON, Canada',
              id: 'REFERENCE2||PLACEID2',
              location: { latitude: 11.22, longitude: 22.33 },
              valid: false
            },
            {
              value: 'St Petersburg, Florida, United States',
              label: 'St Petersburg, Florida, United States',
              id: 'REFERENCE4||PLACEID4',
              location: { latitude: 33.33, longitude: 55.55 },
              valid: false
            },
            {
              value: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              label: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              id: 'REFERENCE5||PLACEID5',
              location: { latitude: 66.66, longitude: 77.77 },
              valid: false
            }
          ]
        end

        it 'returns places from Google and the app removing merged places' do
          place1 = create(:place, name: 'Vertigo 42',
                                  reference: 'REFERENCE3',
                                  place_id: 'PLACEID3',
                                  formatted_address: 'Tower 42, Los Angeles, CA 23211, United States',
                                  city: 'Los Angeles', state: 'California', country: 'US',
                                  lonlat: 'POINT(44.44 11.11)')

          place2 = create(:place, name: 'Vertigo 42 Copy',
                                  reference: 'REFERENCE3',
                                  place_id: 'PLACEID4',
                                  formatted_address: 'Tower 42 Copy, Los Angeles, CA 23211, United States',
                                  city: 'Los Angeles', state: 'California', country: 'US',
                                  lonlat: 'POINT(44.44 11.11)',
                                  merged_with_place_id: place1.id)

          venue = create(:venue, place: place1, company: company_user.company)

          create(:venue, place: place2, company: company_user.company)

          Sunspot.commit

          company_user.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

          params = { q: 'Vertigo', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
              id: venue.place_id,
              location: { latitude: 11.11, longitude: 44.44 },
              valid: true
            },
            {
              value: 'Los Angeles, CA, USA',
              label: 'Los Angeles, CA, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            },
            {
              value: 'Los Angeles, ON, Canada',
              label: 'Los Angeles, ON, Canada',
              id: 'REFERENCE2||PLACEID2',
              location: { latitude: 11.22, longitude: 22.33 },
              valid: false
            },
            {
              value: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              label: 'Sheikh Zayed Road, Fairmont Hotel, Sheikh Zayed Road - Dubai - United Arab Emirates',
              id: 'REFERENCE5||PLACEID5',
              location: { latitude: 66.66, longitude: 77.77 },
              valid: false
            }
          ]
        end
      end

      describe 'allow small differences on city names' do
        let(:google_results) do
          {
            results: [
              {
                'formatted_address' => 'Bayou Restaurant, 580 Gramatan Avenue, Mount Vernon, NY 10552, United States',
                'place_id' => 'PLACEID1',
                'name' => 'Los Angeles',
                'reference' => 'REFERENCE1',
                'types' => %w(locality political),
                'geometry' => { 'location' => { 'lat' => 22.22, 'lng' => 33.33 }  }
              }
            ]
          }
        end

        it 'finds a proper city for a user' do
          company_user.places << create(:city, name: 'MT Vernon', state: 'New York', country: 'US')
          params = { q: 'Bayou', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Los Angeles, Bayou Restaurant, 580 Gramatan Avenue, Mount Vernon, NY 10552, United States',
              label: 'Los Angeles, Bayou Restaurant, 580 Gramatan Avenue, Mount Vernon, NY 10552, United States',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            }
          ]
        end
      end

      describe 'states' do
        let(:google_results) do
          {
            results: [
              {
                'formatted_address' => 'New Jersey, USA',
                'place_id' => 'PLACEID1',
                'name' => 'New Jersey',
                'reference' => 'REFERENCE1',
                'types' => %w(administrative_area_level_1 political),
                'geometry' => { 'location' => { 'lat' => 22.22, 'lng' => 33.33 }  }
              }
            ]
          }
        end

        it 'allows the user if has geolocation permitions for the state' do
          company_user.places << create(:country, name: 'United States')
          params = { q: 'new', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'New Jersey, USA',
              label: 'New Jersey, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            }
          ]
        end
      end

      describe 'cities' do
        let(:google_results) do
          {
            results: [
              {
                'formatted_address' => 'Trenton, New Jersey, USA',
                'place_id' => 'PLACEID1',
                'name' => 'Trenton',
                'reference' => 'REFERENCE1',
                'types' => %w(locality political),
                'geometry' => { 'location' => { 'lat' => 22.22, 'lng' => 33.33 }  }
              }
            ]
          }
        end

        it 'allows the user if has geolocation permitions for the state' do
          company_user.places << create(:country, name: 'United States')
          params = { q: 'new', current_company_user: company_user }
          expect(described_class.new(params).results).to eql [
            {
              value: 'Trenton, New Jersey, USA',
              label: 'Trenton, New Jersey, USA',
              id: 'REFERENCE1||PLACEID1',
              location: { latitude: 22.22, longitude: 33.33 },
              valid: true
            }
          ]
        end
      end
    end
  end
end
