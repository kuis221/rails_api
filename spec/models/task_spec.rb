# == Schema Information
#
# Table name: tasks
#
#  id              :integer          not null, primary key
#  event_id        :integer
#  title           :string(255)
#  due_at          :datetime
#  completed       :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :integer
#  updated_by_id   :integer
#  active          :boolean          default(TRUE)
#  company_user_id :integer
#

require 'spec_helper'

describe Task do
  it { should belong_to(:event) }
  it { should belong_to(:company_user) }

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:event_id) }
  it { should validate_numericality_of(:event_id) }
  it { should validate_numericality_of(:company_user_id) }

  describe "#activate" do
    let(:task) { FactoryGirl.build(:task, active: false) }

    it "should return the active value as true" do
      task.activate!
      task.reload
      task.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:task) { FactoryGirl.build(:task, active: false) }

    it "should return the active value as false" do
      task.deactivate!
      task.reload
      task.active.should be_false
    end
  end
end
