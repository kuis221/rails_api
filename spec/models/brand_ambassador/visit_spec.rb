require 'rails_helper'

RSpec.describe BrandAmbassadors::Visit, :type => :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:company_user) }
  it { is_expected.to have_many(:events) }

  it { is_expected.to validate_presence_of(:company_user) }
  it { is_expected.to validate_numericality_of(:campaign_id) }
  it { is_expected.to validate_presence_of(:company) }

  it { is_expected.to validate_presence_of(:start_date) }
  it { is_expected.to validate_presence_of(:end_date) }

  it { is_expected.to allow_value("12/31/2012").for(:start_date) }
  it { is_expected.not_to allow_value("12/31/12").for(:start_date).with_message('MM/DD/YYYY') }

  describe "end date validations" do
    before { subject.start_date = '12/31/2012' }
    it { is_expected.to allow_value("12/31/2012").for(:end_date) }
    it { is_expected.not_to allow_value("12/31/12").for(:end_date).with_message('MM/DD/YYYY') }
  end

end
