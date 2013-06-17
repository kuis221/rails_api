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

  it { should allow_mass_assignment_of(:completed) }
  it { should allow_mass_assignment_of(:due_at) }
  it { should allow_mass_assignment_of(:title) }
  it { should allow_mass_assignment_of(:company_user_id) }
  it { should allow_mass_assignment_of(:event_id) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:event_id) }
  it { should validate_numericality_of(:event_id) }
  it { should validate_numericality_of(:company_user_id) }
end
