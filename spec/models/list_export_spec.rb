# == Schema Information
#
# Table name: list_exports
#
#  id                :integer          not null, primary key
#  list_class        :string(255)
#  params            :string(255)
#  export_format     :string(255)
#  aasm_state        :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  user_id           :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

describe ListExport do
  pending "add some examples to (or delete) #{__FILE__}"
end
