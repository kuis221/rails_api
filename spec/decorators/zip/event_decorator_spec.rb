require 'rails_helper'

describe Zip::EventPresenter, type: :presenter do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01', modules: { 'expenses' => {} }) }
  let(:place) { create(:place, name: 'Place Test') }
  let(:event) { create(:due_event, company: company, campaign: campaign, place: place) }

  describe 'receipts_for_zip_export' do
    it 'return array with filenames and paths' do
      receipt1 = build(:attached_asset, created_at: Time.zone.local(2013, 8, 22, 11, 59),
                                        file: File.open(Rails.root.join('spec','fixtures','file.pdf')))
      expense1 = create(:event_expense, amount: 99.99, category: 'Entertainment', reimbursable: true,
                                         receipt: receipt1, event: event, created_by: create(:user, first_name: 'Sara', last_name: 'Smith'))
      expense2 = create(:event_expense, amount: 159.15, category: 'Fuel', event: event)

      presenter = Zip::EventPresenter.new(event, nil)
      expect(presenter.receipts_for_zip_export.count).to eql 1
    end

    it 'return array blank' do
      expense1 = create(:event_expense, amount: 99.99, category: 'Entertainment', event: event)
      expense2 = create(:event_expense, amount: 159.15, category: 'Fuel', event: event)

      presenter = Zip::EventPresenter.new(event, nil)
      expect(presenter.receipts_for_zip_export.count).to eql 0
    end
  end

  describe 'generate_filename' do
    it 'return filename' do
      receipt1 = build(:attached_asset, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      expense1 = create(:event_expense, amount: 99.99, category: 'Entertainment', reimbursable: true,
                                        receipt: receipt1, event: event, created_by: create(:user, first_name: 'Sara', last_name: 'Smith'))

      presenter = Zip::EventPresenter.new(event, nil)
      expect(presenter.generate_filename(expense1, 1)).to eql "20150101-PlaceTest-Entertainment-SSmith-1-#{expense1.id}.jpg"
    end
  end

  describe 'remove_all_spaces' do
    it 'return string without spaces' do
      presenter = Zip::EventPresenter.new(build(:event), nil)
      expect(presenter.remove_all_spaces('Test Test ')).to eql 'TestTest'
      expect(presenter.remove_all_spaces('')).to eql nil
      expect(presenter.remove_all_spaces('TestTest')).to eql 'TestTest'
    end
  end

  describe 'sanitize_filename' do
    it 'return string sanitize filename' do
      presenter = Zip::EventPresenter.new(build(:event), nil)
      expect(presenter.sanitize_filename("20130810-McGillyCuddy'sBar&Grill-BarSpend-JTets-0.JPG")).to eql '20130810-McGillyCuddy_sBar_Grill-BarSpend-JTets-0.JPG'
      expect(presenter.sanitize_filename('')).to eql ''
      expect(presenter.sanitize_filename('20130810 BarSpend-JTets-0.JPG')).to eql '20130810_BarSpend-JTets-0.JPG'
      expect(presenter.sanitize_filename('20130810&%$&/test.JPG')).to eql '20130810_test.JPG'
    end
  end
end