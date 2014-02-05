# == Schema Information
#
# Table name: activity_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  active      :boolean          default(TRUE)
#  company_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe ActivityType do
  it { should belong_to(:company) }
  it { should have_many(:form_fields) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:company_id) }
  it { should validate_numericality_of(:company_id) }
end
