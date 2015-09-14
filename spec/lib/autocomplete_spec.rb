require 'rails_helper'

describe Autocomplete, type: :model do
  describe 'search method', search: true do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company) }
    let(:scope) { 'events' }
    let(:params) { { id: scope, q: 'jam' } }
    let(:subject) { described_class.new(scope, company_user, params) }

    describe 'Campaign bucket' do
      let(:active) { create(:campaign, company: company, name: 'Jameson FY14') }
      let(:inactive) { create(:campaign, company: company, name: 'Jamaica FY14', aasm_state: 'inactive') }
      let(:bucket) { subject.search.find { |b| b[:label] == 'Campaigns' } }

      before do
        active && inactive
        Sunspot.commit
      end

      it 'returns only active campaigns if no settings have been defined' do
        expect(bucket).to eql(
          label: 'Campaigns', value: [{ label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' }]
        )
      end

      it 'returns inactive campaigns if user have enabled it' do
        create(:filter_setting, company_user: company_user, apply_to: 'events',
               settings: %w(campaigns_events_present show_inactive_items))
        expect(bucket).to eql(
          label: 'Campaigns', value: [
            { label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' },
            { label: '<i>Jam</i>aica FY14', value: inactive.id.to_s, type: 'campaign' }
          ]
        )
      end

      it 'does not include the inactive campaign if the user have disabled show inactive option' do
        create(:filter_setting, company_user: company_user, apply_to: 'events',
               settings: %w(campaigns_events_present))
        expect(bucket).to eql(
          label: 'Campaigns', value: [{ label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' }]
        )
      end
    end

    describe 'No Limit Campaign bucket' do
      let!(:campaign1) { create(:campaign, company: company, name: 'Jameson FY14') }
      let!(:campaign2) { create(:campaign, company: company, name: 'Jameson FY15') }
      let!(:campaign3) { create(:campaign, company: company, name: 'Jameson FY16') }
      let!(:campaign4) { create(:campaign, company: company, name: 'Jameson FY17') }
      let!(:campaign5) { create(:campaign, company: company, name: 'Jameson FY18') }
      let!(:campaign6) { create(:campaign, company: company, name: 'Jameson FY19') }
      let!(:campaign7) { create(:campaign, company: company, name: 'Jameson FY20') }
      let!(:campaign8) { create(:campaign, company: company, name: 'Jameson FY21') }
      let!(:campaign9) { create(:campaign, company: company, name: 'Jameson FY22') }
      let!(:campaign10) { create(:campaign, company: company, name: 'Jameson FY23') }
      let(:bucket) { subject.search.find { |b| b[:label] == 'Campaigns' } }

      before do
        Sunspot.commit
      end

      it 'returns campaigns' do
        expect(bucket).to eql(
          label: 'Campaigns', value: [{ label: '<i>Jam</i>eson FY14', value: campaign1.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY15', value: campaign2.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY16', value: campaign3.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY17', value: campaign4.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY18', value: campaign5.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY19', value: campaign6.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY20', value: campaign7.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY21', value: campaign8.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY22', value: campaign9.id.to_s, type: 'campaign' },
                                      { label: '<i>Jam</i>eson FY23', value: campaign10.id.to_s, type: 'campaign' }]
        )
      end
    end
  end
end
