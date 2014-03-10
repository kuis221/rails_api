# == Schema Information
#
# Table name: activity_results
#
#  id            :integer          not null, primary key
#  activity_id   :integer
#  form_field_id :integer
#  value         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe ActivityResult do
  it { should belong_to(:activity) }
  it { should belong_to(:form_field) }

  it { should validate_presence_of(:form_field_id) }
  it { should validate_numericality_of(:form_field_id) }
end
