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

require 'rails_helper'

describe Task, type: :model do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to belong_to(:company_user) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_numericality_of(:event_id) }
  it { is_expected.to validate_numericality_of(:company_user_id) }

  let(:event) { create(:event) }

  context do
    before { subject.company_user_id = 1 }
    it { is_expected.not_to validate_presence_of(:event_id) }
  end

  context do
    before { subject.company_user_id = nil }
    it { is_expected.to validate_presence_of(:event_id) }
  end

  context do
    before { subject.event_id = 1 }
    it { is_expected.not_to validate_presence_of(:company_user_id) }
  end

  context do
    before { subject.event_id = nil }
    it { is_expected.to validate_presence_of(:company_user_id) }
  end

  describe '#activate' do
    let(:task) { build(:task, event_id: event.id, active: false) }

    it 'should return the active value as true' do
      task.activate!
      task.reload
      expect(task.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:task) { build(:task, event_id: event.id, active: false) }

    it 'should return the active value as false' do
      task.deactivate!
      task.reload
      expect(task.active).to be_falsey
    end
  end
end
