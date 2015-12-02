require 'rails_helper'

describe KbmgSyncher do
  let(:module_settings) do
    { 'api_key' => 'api_key' }
  end
  let!(:campaign) do
    create(:campaign,
           modules: { 'attendance' => { 'settings' => module_settings } })
  end

  let(:place1) { create :place, city: 'Los Angeles', state: 'California' }
  let(:place2) { create :place, city: 'Breckenridge', state: 'Colorado' }

  describe 'synch' do
    let(:subject) { described_class }

    it 'loads the correct syncher for the campaign' do
      expect_any_instance_of(KbmgSyncher).to receive(:process)

      subject.synch
    end
  end

  describe 'instance methods' do
    let(:module_settings) do
      { 'api_key' => api_key }
    end
    let(:api_key) { 'valid-key' }

    let!(:campaign) do
      create(:campaign,
             modules: { 'attendance' => { 'settings' => module_settings } })
    end

    describe 'test_api_call' do
      let(:subject) { described_class.new(campaign) }

      it 'returns true if valid' do
        expect_any_instance_of(KBMG).to receive(:events).with(limit: 1) do
          { 'Success' => true }
        end
        expect(subject.test_api_call).to be_truthy
      end

      it 'returns true if valid' do
        expect_any_instance_of(KBMG).to receive(:events).with(limit: 1) do
          { 'Success' => false, 'Error' => { 'ErrorCode' => 'API01' }  }
        end
        expect(subject.test_api_call).to be_falsey
      end
    end

    describe 'campaign with a KBMG API Key' do
      let(:subject) { described_class.new(campaign) }

      describe 'with invalid key' do
        before do
          expect(subject).to receive(:valid_campaign_api_key?).and_return(false)
        end

        it 'logs an error' do
          expect(subject.logger).to receive(:info).with("Campaign #{campaign.name} has an invalid KBMG API KEY")
          subject.process
        end
      end

      describe 'with valid key' do
        before do
          expect(subject).to receive(:valid_campaign_api_key?).and_return(true)
        end

        before do
          stub_api_data :events, page: 0, limit: 1000 do
            { 'Success' => true, 'Total' => 2, 'Data' => { 'Events' => [
              {  'StartDate' => '2015-01-01T12:00:00', 'EventId' => 'EVNT1',
                 'RelatedPlace' => { 'PlaceId' => 'PLACE1' } },
              {  'StartDate' => '2015-01-02T12:00:00', 'EventId' => 'EVNT2',
                 'RelatedPlace' => { 'PlaceId' => 'PLACE2' } }
            ] } }
          end

          stub_api_data :event, 'EVNT1' do
            { 'StartDate' => '2015-01-01T12:00:00', 'EventId' => 'EVNT1',
              'RelatedPlace' => { 'PlaceId' => 'PLACE1' } }
          end

          stub_api_data :event, 'EVNT2' do
            { 'StartDate' => '2015-01-02T12:00:00', 'EventId' => 'EVNT2',
              'RelatedPlace' => { 'PlaceId' => 'PLACE2' } }
          end

          stub_api_data :place, 'PLACE1' do
            { 'City' => 'Los Angeles', 'MajorMarket' => 'Some Market',
              'CountryName' => 'United States', 'CountryCode' => 'US',
              'Name' => 'Bar None', 'AddressLine1' => '1233 Union Street',
              'ProvinceCode' => 'CA',
              'ProvinceName' => 'California', 'PostalCode' => '12233' }
          end

          stub_api_data :place, 'PLACE2' do
            { 'City' => 'Breckenridge', 'MajorMarket' => 'Some Market',
              'CountryName' => 'United States', 'CountryCode' => 'US',
              'Name' => 'Bar None', 'AddressLine1' => '1233 Union Street',
              'ProvinceCode' => 'CO',
              'ProvinceName' => 'Colorado', 'PostalCode' => '80424' }
          end

          stub_api_data :event_registrations, 'EVNT1' do
            { 'Success' => true, 'Total' => 2, 'Data' => { 'Registrations' => [
              { 'PersonId' => 'PER1', 'Attended' => true },
              { 'PersonId' => 'PER2', 'Attended' => false }
            ] } }
          end

          stub_api_data :event_registrations, 'EVNT2' do
            { 'Success' => true, 'Total' => 2, 'Data' => { 'Registrations' => [
              { 'PersonId' => 'PER1', 'Attended' => true, 'Rsvp' => true },
              { 'PersonId' => 'PER2', 'Attended' => false, 'Rsvp' => false }
            ] } }
          end

          stub_api_data :person, 'PER1' do
            { 'FirstName' => 'Miguel', 'LastName' => 'Angelo', 'PostalCode' => '11122',
              'DateOfBirth' => '1946-02-15T00:00:00', 'Email' => 'person1@email.net',
              'CreatedDate' => '2015-04-06T17:03:34.8376182', 'IsOptedOut' => false }
          end

          stub_api_data :person, 'PER2' do
            { 'FirstName' => 'Raphael', 'LastName' => nil,  'PostalCode' => '33456',
              'DateOfBirth' => '1946-02-15T00:00:00', 'Email' => 'person2@email.net',
              'CreatedDate' => '2015-04-06T17:03:34.8376182', 'IsOptedOut' => false }
          end
        end

        it 'synchs the data for the events' do
          event1 = create(:event, campaign: campaign, start_date: '01/01/2015', place: place1, end_date: '01/01/2015')
          event2 = create(:event, campaign: campaign, start_date: '01/02/2015', place: place2, end_date: '01/02/2015')
          create :place, name: 'Bar None', state: 'California', zipcode: '12233', street_number: '1233', route: 'Union Street'

          expect do
            expect do
              expect do
                subject.process
              end.to change(Invite, :count).by(2)
            end.to change(InviteIndividual, :count).by(4) # Two per event
          end.to change(Venue, :count).by(2)

          expect(event1.reload.kbmg_event_id).to eql 'EVNT1'
          expect(Invite.pluck(:rsvps_count, :attendees, :invitees)).to match_array([
            [0, 1, 2], [1, 1, 2]
          ])
          expect(Invite.all.map(&:venue).uniq).to match_array Venue.last(2)
        end

        it 'correctly finds the event based on the place\'s city' do
          # Create two events in the same date but different city, only one
          # should get synched since start date + city matches the one from
          # the API
          event1 = create(:event, campaign: campaign, start_date: '01/01/2015', place: place1, end_date: '01/01/2015')
          event2 = create(:event, campaign: campaign, start_date: '01/01/2015', place: place2, end_date: '01/01/2015')
          expect do
            expect do
              expect do
                subject.process
              end.to change(Invite, :count).by(1)
            end.to change(InviteIndividual, :count).by(2) # Two per event
          end.to change(Venue, :count).by(1)
        end

        pending 'creates the place if a good match cannot be found' do
          # This should be implemented when making it to assign the correct
          # venue to each individual invite
          event1 = create(:event, campaign: campaign, place: place1, start_date: '01/01/2015', end_date: '01/01/2015')
          event2 = create(:event, campaign: campaign, place: place2, start_date: '01/02/2015', end_date: '01/02/2015')

          expect do
            subject.process
          end.to change(Place, :count).by(2)

          expect(event1.reload.kbmg_event_id).to eql 'EVNT1'
          expect(Invite.pluck(:rsvps_count, :attendees, :invitees)).to match_array([
            [0, 1, 2], [1, 1, 2]
          ])
          expect(Invite.all.map(&:venue).uniq).to match_array Venue.last(2)
          place = Place.last
          expect(place.name).to eql 'Bar None'
          expect(place.formatted_address).to eql '1233 Union Street, Los Angeles, CA, United States'
          expect(place.street_number).to eql '1233'
          expect(place.route).to eql 'Union Street'
          expect(place.city).to eql 'Los Angeles'
          expect(place.country).to eql 'US'
          expect(place.state).to eql 'California'
        end
      end
    end

    def stub_api_data(method, params)
      allow_any_instance_of(KBMG).to receive(method).with(params) do
        yield
      end
    end
  end
end
