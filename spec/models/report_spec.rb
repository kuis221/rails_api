# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
#

<<<<<<< HEAD
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
=======
>>>>>>> development
#

require 'spec_helper'

describe Report do
<<<<<<< HEAD
  it { should validate_presence_of(:name) }

  describe "#activate" do
    let(:report) { FactoryGirl.build(:report, active: false) }

    it "should return the active value as true" do
      report.activate!
      report.reload
      report.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:report) { FactoryGirl.build(:report, active: false) }

    it "should return the active value as false" do
      report.deactivate!
      report.reload
      report.active.should be_false
    end
  end
=======
>>>>>>> development
end
