require 'rails_helper'

describe EventsController, type: :controller, search: true do
  describe 'As Super User' do
    let(:user) { sign_in_as_user }
    let(:company_user) { user.current_company_user }
    let(:company) { user.companies.first }
    let(:campaign) { create(:campaign, company: company) }

    before { user }

    describe 'GET calendar' do
      it 'should return the correct list of brands the count of events' do
        campaign.brands << create(:brand, company: company, name: 'Jose Cuervo')
        create(:event, start_date: '01/13/2013', end_date: '01/13/2013', campaign: campaign)
        Sunspot.commit
        get 'calendar', start: DateTime.new(2013, 01, 01, 0, 0, 0).to_i.to_s,
                        end: DateTime.new(2013, 01, 31, 23, 59, 59).to_i.to_s,
                        group: :brand,
                        format: :json
        expect(response).to be_success
        results = JSON.parse(response.body)
        expect(results.count).to eq(1)
        brand = results.first
        expect(brand['title']).to eq('Jose Cuervo')
        expect(brand['count']).to eq(1)
        expect(brand['start']).to eq('2013-01-13')
        expect(brand['end']).to eq('2013-01-13')
      end
    end
  end

end
