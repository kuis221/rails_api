# == Schema Information
#
# Table name: event_expenses
#
#  id                :integer          not null, primary key
#  event_id          :integer
#  name              :string(255)
#  amount            :decimal(9, 2)    default(0.0)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

describe EventExpense do
  it { should belong_to(:event) }

  it { should allow_mass_assignment_of(:amount) }
  it { should allow_mass_assignment_of(:file) }
  it { should allow_mass_assignment_of(:name) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:event_id) }
  it { should_not allow_mass_assignment_of(:file_file_name) }
  it { should_not allow_mass_assignment_of(:file_content_type) }
  it { should_not allow_mass_assignment_of(:file_file_size) }
  it { should_not allow_mass_assignment_of(:file_updated_at) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should validate_presence_of(:name) }
end
