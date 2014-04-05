# == Schema Information
#
# Table name: form_field_options
#
#  id            :integer          not null, primary key
#  form_field_id :integer
#  name          :string(255)
#  ordering      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  option_type   :string(255)
#

require 'spec_helper'

describe FormFieldOption do
  it { should belong_to(:form_field) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:ordering) }
  it { should validate_numericality_of(:ordering) }
end
