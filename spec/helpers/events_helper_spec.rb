require 'rails_helper'

describe EventsHelper, type: :helper do
  describe 'describe_filters' do
    let(:company) { create(:company) }
    let(:user) { create(:company_user, company: company) }
    let(:params) { {} }

    before do
      allow(helper).to receive(:current_company).and_return(company)
      allow(helper).to receive(:current_company_user).and_return(user)
      allow(helper).to receive(:current_user).and_return(user.user)
      allow(helper).to receive(:collection_count).and_return(100)
      allow(helper).to receive(:resource_class).and_return(Event)

      allow(helper).to receive(:params).and_return(params)
    end

    subject { helper.describe_filters }

    describe 'without params' do
      it { is_expected.to eql '<span class="results-count">100</span> events found' }

      describe 'with just one result' do
        before { allow(helper).to receive(:collection_count).and_return(1) }
        it { is_expected.to eql '<span class="results-count">1</span> event found' }
      end
    end

    describe 'with one campaign selected' do
      let(:campaigns) do
        [
          create(:campaign, company: company, name: 'My Campaign 1'),
          create(:campaign, company: company, name: 'My Campaign 2')
        ]
      end
      let(:params) { { campaign: [campaigns.map(&:id)] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Campaign 1<a class="icon icon-close" '\
            'data-filter="campaign:' + campaigns[0].id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Campaign 2<a class="icon icon-close" '\
            'data-filter="campaign:' + campaigns[1].id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with start_date only' do
      let(:params) { { start_date: "11/01/2014", end_date: "" } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Nov 01, 2014<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with start_date and end_date' do
      let(:params) { { start_date: "11/01/2014", end_date: "11/05/2014" } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Nov 01, 2014 - Nov 05, 2014<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'end_date set to more than one year in the future' do
      let(:params) { { start_date: "11/01/2014", end_date: "11/05/#{Date.current.year+3}" } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Nov 01, 2014 to the future<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'start_date set to today end_date set to more than one year in the future' do
      let(:params) { { start_date: Time.current.to_date.to_s(:slashes), end_date: "11/05/#{Date.current.year+3}" } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">today to the future<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'start_date set to yesterday end_date set to more than one year in the future' do
      let(:params) { { start_date: (Time.current - 1.day).to_date.to_s(:slashes), end_date: "11/05/#{Date.current.year+3}" } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">yesterday to the future<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'start_date set to tomorrow end_date set to more than one year in the future' do
      let(:params) { { start_date: (Time.current + 1.day).to_date.to_s(:slashes), end_date: "11/05/#{Date.current.year+3}" } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">tomorrow to the future<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'end_date set to today' do
      let(:params) { { start_date: '11/01/2014', end_date: Time.current.to_date.to_s(:slashes) } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Nov 01, 2014 - today<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'end_date set to yesterday' do
      let(:params) { { start_date: '11/01/2014', end_date: (Time.current - 1.day).to_date.to_s(:slashes) } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Nov 01, 2014 - yesterday<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'end_date set to tomorrow' do
      let(:params) { { start_date: '11/01/2014', end_date: (Time.current + 1.day).to_date.to_s(:slashes) } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Nov 01, 2014 - tomorrow<a class="icon icon-close" '\
            'data-filter="date" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with status param' do
      let(:params) { { status: ['Active'] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Active<a class="icon icon-close" '\
            'data-filter="status:Active" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with event status param' do
      let(:params) { { event_status: ['Late', 'Approved'] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Approved<a class="icon icon-close" '\
            'data-filter="event_status:Approved" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">Late<a class="icon icon-close" '\
            'data-filter="event_status:Late" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with status and event status params' do
      let(:params) { { status: ['Active'], event_status: ['Late', 'Approved'] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Active<a class="icon icon-close" '\
            'data-filter="status:Active" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">Approved<a class="icon icon-close" '\
            'data-filter="event_status:Approved" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">Late<a class="icon icon-close" '\
            'data-filter="event_status:Late" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one campaign selected and another as a search param' do
      let(:campaign1) { create(:campaign, company: company, name: 'My Campaign 1') }
      let(:campaign2) { create(:campaign, company: company, name: 'My Campaign 2') }

      let(:params) { { q: "campaign,#{campaign1.id}", campaign: [campaign2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Campaign 1<a class="icon icon-close" '\
            'data-filter="campaign:' + campaign1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Campaign 2<a class="icon icon-close" '\
            'data-filter="campaign:' + campaign2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one activity type selected and another as a search param' do
      let(:activity_type1) { create(:activity_type, company: company, name: 'My Activity Type 1') }
      let(:activity_type2) { create(:activity_type, company: company, name: 'My Activity Type 2') }

      let(:params) { { q: "activity_type,#{activity_type1.id}", activity_type: [activity_type2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Activity Type 1<a class="icon icon-close" '\
            'data-filter="activity_type:' + activity_type1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Activity Type 2<a class="icon icon-close" '\
            'data-filter="activity_type:' + activity_type2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one date range selected and another as a search param' do
      let(:date_range1) { create(:date_range, company: company, name: 'My Date Range 1') }
      let(:date_range2) { create(:date_range, company: company, name: 'My Date Range 2') }

      let(:params) { { q: "date_range,#{date_range1.id}", date_range: [date_range2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Date Range 1<a class="icon icon-close" '\
            'data-filter="date_range:' + date_range1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Date Range 2<a class="icon icon-close" '\
            'data-filter="date_range:' + date_range2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one area selected and another as a search param' do
      let(:area1) { create(:area, company: company, name: 'My Area 1') }
      let(:area2) { create(:area, company: company, name: 'My Area 2') }

      let(:params) { { q: "area,#{area1.id}", area: [area2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Area 1<a class="icon icon-close" '\
            'data-filter="area:' + area1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Area 2<a class="icon icon-close" '\
            'data-filter="area:' + area2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one brand selected and another as a search param' do
      let(:brand1) { create(:brand, company: company, name: 'My Brand 1') }
      let(:brand2) { create(:brand, company: company, name: 'My Brand 2') }

      let(:params) { { q: "brand,#{brand1.id}", brand: [brand2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Brand 1<a class="icon icon-close" '\
            'data-filter="brand:' + brand1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Brand 2<a class="icon icon-close" '\
            'data-filter="brand:' + brand2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one brand portfolio selected and another as a search param' do
      let(:brand_portfolio1) { create(:brand_portfolio, company: company, name: 'My Brand Portfolio 1') }
      let(:brand_portfolio2) { create(:brand_portfolio, company: company, name: 'My Brand Portfolio 2') }

      let(:params) { { q: "brand_portfolio,#{brand_portfolio1.id}", brand_portfolio: [brand_portfolio2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Brand Portfolio 1<a class="icon icon-close" '\
            'data-filter="brand_portfolio:' + brand_portfolio1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Brand Portfolio 2<a class="icon icon-close" '\
            'data-filter="brand_portfolio:' + brand_portfolio2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one brand selected and another as a search param' do
      let(:venue1) { create(:venue, company: company, place: create(:place, name: 'My Venue 1')) }
      let(:venue2) { create(:venue, company: company, place: create(:place, name: 'My Venue 2')) }

      let(:params) { { q: "venue,#{venue1.id}", venue: [venue2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Venue 1<a class="icon icon-close" '\
            'data-filter="venue:' + venue1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Venue 2<a class="icon icon-close" '\
            'data-filter="venue:' + venue2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one user selected and another as a search param' do
      let(:user1) do
        create(:user, company: company, first_name: 'Elvis', last_name: 'Presley')
          .company_users.first
      end
      let(:user2) do
        create(:user, company: company, first_name: 'Michael', last_name: 'Jackson')
          .company_users.first
      end

      let(:params) { { q: "user,#{user1.id}", user: [user2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Elvis Presley<a class="icon icon-close" '\
            'data-filter="user:' + user1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">Michael Jackson<a class="icon icon-close" '\
            'data-filter="user:' + user2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one team selected and another as a search param' do
      let(:team1) { create(:team, company: company, name: 'My Team 1') }
      let(:team2) { create(:team, company: company, name: 'My Team 2') }

      let(:params) { { q: "team,#{team1.id}", team: [team2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Team 1<a class="icon icon-close" '\
            'data-filter="team:' + team1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Team 2<a class="icon icon-close" '\
            'data-filter="team:' + team2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one role selected and another as a search param' do
      let(:role1) { create(:role, company: company, name: 'My Role 1') }
      let(:role2) { create(:role, company: company, name: 'My Role 2') }

      let(:params) { { q: "role,#{role1.id}", role: [role2.id] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">My Role 1<a class="icon icon-close" '\
            'data-filter="role:' + role1.id.to_s + '" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">My Role 2<a class="icon icon-close" '\
            'data-filter="role:' + role2.id.to_s + '" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'with one team selected and another as a search param' do
      let(:params) { { q: "city,Baltimore", city: ['Austin'] } }

      it do
        is_expected.to eql(
            '<span class="results-count">100</span> events found for: '\
            '<div class="filter-item">Austin<a class="icon icon-close" '\
            'data-filter="city:Austin" href="#" title="Remove this filter"></a></div> '\
            '<div class="filter-item">Baltimore<a class="icon icon-close" '\
            'data-filter="city:Baltimore" href="#" title="Remove this filter"></a></div>')
      end
    end

    describe 'for visits' do
      before { allow(helper).to receive(:resource_class).and_return(BrandAmbassadors::Visit) }

      describe 'without params' do
        it { is_expected.to eql '<span class="results-count">100</span> visits found' }
      end
    end

  end
end
