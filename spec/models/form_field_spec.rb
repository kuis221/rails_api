# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

describe FormField do
  it { should belong_to(:fieldable) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:ordering) }
  it { should validate_numericality_of(:ordering) }
end
