# == Schema Information
#
# Table name: campaign_form_fields
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  kpi_id      :integer
#  ordering    :integer
#  name        :string(255)
#  field_type  :string(255)
#  options     :text
#  section_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe CampaignFormField do
  it { should belong_to(:campaign) }
  it { should belong_to(:kpi) }
  it { should have_many(:fields) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:options) }
  it { should allow_mass_assignment_of(:ordering) }
  it { should allow_mass_assignment_of(:section_id) }
  it { should allow_mass_assignment_of(:field_type) }
  it { should allow_mass_assignment_of(:kpi_id) }
  it { should allow_mass_assignment_of(:fields_attributes) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:campaign_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should accept_nested_attributes_for(:fields) }

  it { should validate_numericality_of(:campaign_id) }
  it { should validate_numericality_of(:kpi_id) }
  it { should validate_numericality_of(:section_id) }
  it { should validate_numericality_of(:ordering) }
  it { should validate_presence_of(:ordering) }
end
