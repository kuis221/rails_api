require 'rails_helper'

describe EventsHelper, type: :helper do
  describe 'describe_filters' do
    let(:company) { create(:company) }
    let(:user) { create(:company_user, company: company) }

    before do
      allow(helper).to receive(:current_company).and_return(company)
      allow(helper).to receive(:current_company_user).and_return(user)
      allow(helper).to receive(:current_user).and_return(user.user)
      allow(helper).to receive(:collection_count).and_return(100)
      allow(helper).to receive(:resource_class).and_return(Event)
    end

    subject { helper.describe_filters }

    describe 'without params' do
      it { is_expected.to eql '100 events found' }

      describe 'with just one result' do
        before { allow(helper).to receive(:collection_count).and_return(1) }
        it { is_expected.to eql '1 event found' }
      end
    end

    describe 'with one campaign selected' do
      let(:campaigns) do
        [
          create(:campaign, company: company, name: 'My Campaign 1'),
          create(:campaign, company: company, name: 'My Campaign 2')
        ]
      end
      before { allow(helper).to receive(:params).and_return(campaign: [campaigns.map(&:id)]) }

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">My Campaign 1<a class="icon icon-close" '\
            'data-filter="campaign:' + campaigns[0].id.to_s + '" href="#"></a></div>'\
            '<div class="filter-item">My Campaign 2<a class="icon icon-close" '\
            'data-filter="campaign:' + campaigns[1].id.to_s + '" href="#"></a></div>')
      end
    end

    describe 'with one campaign selected and another as a search param' do
      let(:campaign1) { create(:campaign, company: company, name: 'My Campaign 1') }
      let(:campaign2) { create(:campaign, company: company, name: 'My Campaign 2') }

      before do
        allow(helper).to receive(:params).and_return(q: "campaign,#{campaign1.id}",
                                                     campaign: [campaign2.id])
      end

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">My Campaign 1<a class="icon icon-close" '\
            'data-filter="campaign:' + campaign1.id.to_s + '" href="#"></a></div>'\
            '<div class="filter-item">My Campaign 2<a class="icon icon-close" '\
            'data-filter="campaign:' + campaign2.id.to_s + '" href="#"></a></div>')
      end
    end

    describe 'with one area selected and another as a search param' do
      let(:area1) { create(:area, company: company, name: 'My Area 1') }
      let(:area2) { create(:area, company: company, name: 'My Area 2') }

      before do
        allow(helper).to receive(:params).and_return(q: "area,#{area1.id}",
                                                     area: [area2.id])
      end

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">My Area 1<a class="icon icon-close" '\
            'data-filter="area:' + area1.id.to_s + '" href="#"></a></div>'\
            '<div class="filter-item">My Area 2<a class="icon icon-close" '\
            'data-filter="area:' + area2.id.to_s + '" href="#"></a></div>')
      end
    end

    describe 'with one brand selected and another as a search param' do
      let(:brand1) { create(:brand, company: company, name: 'My Brand 1') }
      let(:brand2) { create(:brand, company: company, name: 'My Brand 2') }

      before do
        allow(helper).to receive(:params).and_return(q: "brand,#{brand1.id}",
                                                     brand: [brand2.id])
      end

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">My Brand 1<a class="icon icon-close" '\
            'data-filter="brand:' + brand1.id.to_s + '" href="#"></a></div>'\
            '<div class="filter-item">My Brand 2<a class="icon icon-close" '\
            'data-filter="brand:' + brand2.id.to_s + '" href="#"></a></div>')
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

      before do
        allow(helper).to receive(:params).and_return(q: "user,#{user1.id}",
                                                     user: [user2.id])
      end

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">Elvis Presley<a class="icon icon-close" '\
            'data-filter="user:' + user1.id.to_s + '" href="#"></a></div>'\
            '<div class="filter-item">Michael Jackson<a class="icon icon-close" '\
            'data-filter="user:' + user2.id.to_s + '" href="#"></a></div>')
      end
    end

    describe 'with one team selected and another as a search param' do
      let(:team1) { create(:team, company: company, name: 'My Team 1') }
      let(:team2) { create(:team, company: company, name: 'My Team 2') }

      before do
        allow(helper).to receive(:params).and_return(q: "team,#{team1.id}",
                                                     team: [team2.id])
      end

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">My Team 1<a class="icon icon-close" '\
            'data-filter="team:' + team1.id.to_s + '" href="#"></a></div>'\
            '<div class="filter-item">My Team 2<a class="icon icon-close" '\
            'data-filter="team:' + team2.id.to_s + '" href="#"></a></div>')
      end
    end


    describe 'with one team selected and another as a search param' do
      before do
        allow(helper).to receive(:params).and_return(q: "city,Baltimore",
                                                     city: ['Austin'])
      end

      it do
        is_expected.to eql(
            '100 events found for: '\
            '<div class="filter-item">Austin<a class="icon icon-close" '\
            'data-filter="city:Austin" href="#"></a></div>'\
            '<div class="filter-item">Baltimore<a class="icon icon-close" '\
            'data-filter="city:Baltimore" href="#"></a></div>')
      end
    end

    describe 'for visits' do
      before { allow(helper).to receive(:resource_class).and_return(BrandAmbassadors::Visit) }

      describe 'without params' do
        it { is_expected.to eql '100 visits found' }
      end
    end

  end
end
