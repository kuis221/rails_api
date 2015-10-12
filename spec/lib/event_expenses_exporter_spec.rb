require 'rails_helper'

describe EventExpensesExporter, type: :model do
  let(:company) { campaign.company }
  let(:campaign) { create(:campaign) }
  let(:event) { create(:approved_event, campaign: campaign) }
  let(:company_user) { create(:company_user, company: campaign.company) }
  let(:params) { { campaign: [campaign.id] } }

  let(:subject) { described_class.new(company_user, params) }

  describe '#expenses_columns' do
    it 'returns only column for the total expenses have been created' do
      expect(subject.expenses_columns).to eql ['SPENT']
    end

    it 'returns the different categories' do
      create(:event_expense, event: event, category: 'Other')
      create(:event_expense, event: event, category: 'Entertainment')
      create(:event_expense, event: event, category: 'Entertainment')
      create(:event_expense, event: event, category: 'Uncategorized')
      expect(subject.expenses_columns).to eql %w(SPENT ENTERTAINMENT OTHER UNCATEGORIZED)
    end

    it 'returns the different categories only for events of the give campaigns' do
      other_event = create(:event, company: company)
      create(:event_expense, event: event, category: 'Other')
      create(:event_expense, event: event, category: 'Entertainment')
      create(:event_expense, event: other_event, category: 'Uncategorized')
      expect(subject.expenses_columns).to eql %w(SPENT ENTERTAINMENT OTHER)
    end
  end

  describe '#event_expenses' do
    it 'returns empty if no expenses have been created for given campaign' do
      expect(subject.event_expenses(event)).to eql [0]
    end

    it 'returns the value of the expense' do
      create(:event_expense, event: event, amount: 100, category: 'Other')
      expect(subject.event_expenses(event)).to eql [100, 100]
    end

    it 'returns the values of the expense grouped by category' do
      create(:event_expense, event: event, amount: 100, category: 'Other')
      create(:event_expense, event: event, amount: 30, category: 'Entertainment')
      create(:event_expense, event: event, amount: 10, category: 'Other')
      expect(subject.event_expenses(event)).to eql [140, 30, 110]
    end

    it 'returns the values of the expense grouped by category' do
      other_event = create(:event, campaign: campaign)
      create(:event_expense, event: event, amount: 100, category: 'Other')
      create(:event_expense, event: event, amount: 30, category: 'Entertainment')
      create(:event_expense, event: event, amount: 10, category: 'Other')
      create(:event_expense, event: other_event, amount: 45, category: 'Uncategorized')
      expect(subject.event_expenses(event)).to eql [140, 30, 110, nil]
      expect(subject.event_expenses(other_event)).to eql [45, nil, nil, 45]
    end
  end
end
