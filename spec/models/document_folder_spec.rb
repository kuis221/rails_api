# == Schema Information
#
# Table name: document_folders
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  parent_id       :integer
#  active          :boolean
#  documents_count :integer
#  company_id      :integer
#  created_at      :datetime
#  updated_at      :datetime
#

require 'rails_helper'

RSpec.describe DocumentFolder, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
