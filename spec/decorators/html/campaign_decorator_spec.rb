require 'rails_helper'

describe Html::CampaignPresenter, type: :presenter do

  describe '#gender_total' do
    it 'formats the gender_total' do
      presenter = present(build(:campaign))
      expect(presenter.gender_total([])).to eq({ male: 0, female: 0 })

      presenter = present(build(:campaign))
      expect(presenter.gender_total([30,40])).to eq({ male: 0, female: 0 })

      presenter = present(build(:campaign))
      expect(presenter.gender_total([['Male'],['Female', 40.0]])).to eq({ male: 0, female: 100 })

      presenter = present(build(:campaign))
      expect(presenter.gender_total([['Female', 230.0], ['Male', 270.0]])).to eq({ male: 54, female: 46 })
    end
  end
end