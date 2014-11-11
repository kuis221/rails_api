require 'rails_helper'

describe EventsHelper, type: :helper do
  describe 'describe_filters' do
    let(:company){ create(:company) }
    let(:user){ create(:company_user, company: company) }
    before do
      allow(helper).to receive(:current_company).and_return(company)
      allow(helper).to receive(:current_company_user).and_return(user)
      allow(helper).to receive(:current_user).and_return(user.user)
      allow(helper).to receive(:collection_count).and_return(100)
      allow(helper).to receive(:resource_class).and_return(Event)
    end
    describe 'without params' do
      subject { helper.describe_filters }

      it { is_expected.to eql '100 events found' }

      describe 'with just one result' do
        before { allow(helper).to receive(:collection_count).and_return(1) }
        it { is_expected.to eql '1 event found' }
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
    end
  end
end
