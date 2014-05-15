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
  it { should validate_numericality_of(:event_id) }
  it { should validate_numericality_of(:company_user_id) }

  let(:event) { FactoryGirl.create(:event) }

  context do
    before { subject.company_user_id = 1 }
    it { should_not validate_presence_of(:event_id) }
  end

  context do
    before { subject.company_user_id = nil }
    it { should validate_presence_of(:event_id) }
  end

  context do
    before { subject.event_id = 1 }
    it { should_not validate_presence_of(:company_user_id) }
  end

  context do
    before { subject.event_id = nil }
    it { should validate_presence_of(:company_user_id) }
  end

  describe "#activate" do
    let(:task) { FactoryGirl.build(:task, event_id: event.id, active: false) }

    it "should return the active value as true" do
      task.activate!
      task.reload
      task.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:task) { FactoryGirl.build(:task, event_id: event.id, active: false) }

    it "should return the active value as false" do
      task.deactivate!
      task.reload
      task.active.should be_false
    end
  end
end
