require 'rails_helper'
require 'collection_filter'

describe CollectionFilter do
  describe 'filters method' do
    let(:company) { create(:company) }
    let(:role) { create(:role, company: company) }
    let(:company_user) { create(:company_user, company: company, role: role) }
    let(:params) { { id: scope } }
    let(:subject) { described_class.new(scope, company_user, params) }

    describe 'for events' do
      let(:scope) { 'events' }

      it 'returns the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Campaigns', 'Brands', 'Areas', 'People', 'Event Status', 'Active State', 'Saved Filters'])
      end

      describe 'as not admin user' do
        let(:role) { create(:non_admin_role) }

        include_examples 'for areas bucket'
        include_examples 'for active state bucket'
      end
    end

    describe 'for areas' do
      let(:scope) { 'areas' }

      include_examples 'for active state bucket'

      it 'returns the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Active State', 'Saved Filters'])
      end
    end

    describe 'for activity types' do
      let(:scope) { 'activity_types' }

      include_examples 'for active state bucket'

      it 'returns the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Active State', 'Saved Filters'])
      end
    end

    describe 'for venues' do
      let(:scope) { 'venues' }
      let(:search_stats) { [double(rows: nil)] }

      before do
        allow_any_instance_of(Sunspot::Rails::StubSessionProxy::Search)
          .to receive(:stats).and_return(search_stats)
      end

      it 'returns the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Price', 'Areas', 'Campaigns', 'Brands', 'Saved Filters'])
      end

      describe 'Sliders' do
        let(:search_stats) do
          [
            double(rows: [
              double(stat_field: 'events_count_is', value: '1'),
              double(stat_field: 'promo_hours_es', value: '2'),
              double(stat_field: 'impressions_is', value: '3'),
              double(stat_field: 'interactions_is', value: '4'),
              double(stat_field: 'sampled_is', value: '5'),
              double(stat_field: 'spent_es', value: '6'),
              double(stat_field: 'venue_score_is', value: '7')
            ])
          ]
        end

        it 'returns the sliders' do
          expect(subject.filters.map { |b| b[:label] }).to eq([
            'Events', 'Impressions', 'Interactions', 'Promo Hours', 'Samples', 'Venue Score',
            '$ Spent', 'Price', 'Areas', 'Campaigns', 'Brands', 'Saved Filters'])
        end

        it 'returns the correct ranges for the events slider' do
          expect(subject.filters.find { |b| b[:label] == 'Events' }).to eql(
            label: 'Events', name: :events_count, min: 0, max: 1, selected_min: nil, selected_max: nil
          )
        end

        it 'returns the correct ranges for the promo hours slider' do
          expect(subject.filters.find { |b| b[:label] == 'Promo Hours' }).to eql(
            label: 'Promo Hours', name: :promo_hours, min: 0, max: 2, selected_min: nil, selected_max: nil
          )
        end

        it 'returns the correct ranges for the impressions slider' do
          expect(subject.filters.find { |b| b[:label] == 'Impressions' }).to eql(
            label: 'Impressions', name: :impressions, min: 0, max: 3, selected_min: nil, selected_max: nil
          )
        end

        it 'returns the correct ranges for the interactions slider' do
          expect(subject.filters.find { |b| b[:label] == 'Interactions' }).to eql(
            label: 'Interactions', name: :interactions, min: 0, max: 4, selected_min: nil, selected_max: nil
          )
        end

        it 'returns the correct ranges for the sampled slider' do
          expect(subject.filters.find { |b| b[:label] == 'Samples' }).to eql(
            label: 'Samples', name: :sampled, min: 0, max: 5, selected_min: nil, selected_max: nil
          )
        end

        it 'returns the correct ranges for the spend slider' do
          expect(subject.filters.find { |b| b[:label] == '$ Spent' }).to eql(
            label: '$ Spent', name: :spent, min: 0, max: 6, selected_min: nil, selected_max: nil
          )
        end
      end
    end

    describe 'company custom filters' do
      before { allow(subject).to receive(:scope_filters).and_return({}) }

      let(:scope) { 'events' }
      it 'returns empty if no custom filters have been created' do
        expect(subject.filters).to eql [{ label: 'Saved Filters', items: [] }]
      end

      it 'returns the saved custom filter' do
        filter = create(:custom_filter, name: 'CustomFilter1',
          owner: company_user, apply_to: scope,
          filters: 'my-filter=true', category: create(:custom_filters_category, name: 'My Filters'))
        expect(subject.filters).to eql [
          {
            label: 'MY FILTERS', items: [
              { id: filter.id.to_s, label: 'CustomFilter1', name: :cfid, selected: false }
            ]
          },
          { label: 'Saved Filters', items: [] }
        ]
      end

      it 'returns the saved custom filters for the company' do
        filter = create(:custom_filter, name: 'CustomFilter1',
          owner: company, apply_to: scope,
          filters: 'my-filter=true', category: create(:custom_filters_category, name: 'My Filters'))
        expect(subject.filters).to eql [
          {
            label: 'MY FILTERS', items: [
              { id: filter.id.to_s, label: 'CustomFilter1', name: :cfid, selected: false }
            ]
          },
          { label: 'Saved Filters', items: [] }
        ]
      end

      it 'returns the saved custom filters grouped by category' do
        global_filter = create(:custom_filter, name: 'CustomCompanyFilter1',
          owner: company, apply_to: scope,
          filters: 'my-filter=true', category: create(:custom_filters_category, name: 'Global Filters'))
        user_filter = create(:custom_filter, name: 'CustomUserFilter1',
          owner: company_user, apply_to: scope,
          filters: 'my-filter=true', category: create(:custom_filters_category, name: 'My Filters'))
        expect(subject.filters).to eql [
          {
            label: 'GLOBAL FILTERS', items: [
              { id: global_filter.id.to_s, label: 'CustomCompanyFilter1', name: :cfid, selected: false }
            ]
          },
          {
            label: 'MY FILTERS', items: [
              { id: user_filter.id.to_s, label: 'CustomUserFilter1', name: :cfid, selected: false }
            ]
          },
          { label: 'Saved Filters', items: [] }
        ]
      end

      describe 'when a custom filter have been included in the configuration' do
        before do
          allow(subject).to receive(:scope_filters).and_return(
            'brands' => { 'classes' => [Brand], 'label' => 'Brands' },
            'custom_filter' => 'Global Filters',
            'campaigns' => { 'classes' => [Campaign], 'label' => 'Campaigns' }
          )
        end

        it 'returns the company filters in a custom order' do
          global_filter = create(:custom_filter, name: 'CustomCompanyFilter1',
            owner: company, apply_to: scope,
            filters: 'my-filter=true', category: create(:custom_filters_category, name: 'Global Filters'))

          expect(subject.filters).to eql [
            { label: 'Brands', items: [] },
            { label: 'GLOBAL FILTERS', items: [
              { id: global_filter.id.to_s, label: 'CustomCompanyFilter1',
                name: :cfid, selected: false }] },
            { label: 'Campaigns', items: [] }, { label: 'Saved Filters', items: [] }]
        end
      end
    end
  end
end
