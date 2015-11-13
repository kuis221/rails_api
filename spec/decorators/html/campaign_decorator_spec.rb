require 'rails_helper'

describe Html::CampaignPresenter, type: :presenter do

  describe '#gender_percentage' do
    it 'formats the gender_percentage' do
      presenter = present(build(:campaign))
      expect(presenter.gender_percentage([])).to eq({ male: 0, female: 0 })

      expect(presenter.gender_percentage([30,40])).to eq({ male: 0, female: 0 })

      expect(presenter.gender_percentage([['Male'],['Female', 40.0]])).to eq({ male: 0, female: 100 })

      expect(presenter.gender_percentage([['Female', 230.0], ['Male', 270.0]])).to eq({ male: 54, female: 46 })
    end
  end
end