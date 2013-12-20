# == Schema Information
#
# Table name: reports
#
#  id                :integer          not null, primary key
#  type              :string(255)
#  company_user_id   :integer
#  params            :text
#  aasm_state        :string(255)
#  progress          :integer
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

describe Report do
  pending "add some examples to (or delete) #{__FILE__}"
end
