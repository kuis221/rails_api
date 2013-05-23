# == Schema Information
#
# Table name: documents
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  documentable_id   :integer
#  documentable_type :string(255)
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

describe Document do
  it { should belong_to(:documentable) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:file) }

  it { should validate_presence_of(:name) }
end
