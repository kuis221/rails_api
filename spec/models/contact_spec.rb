# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  company_id   :integer
#  first_name   :string(255)
#  last_name    :string(255)
#  title        :string(255)
#  email        :string(255)
#  phone_number :string(255)
#  street1      :string(255)
#  street2      :string(255)
#  country      :string(255)
#  state        :string(255)
#  city         :string(255)
#  zip_code     :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe Contact do
  pending "add some examples to (or delete) #{__FILE__}"
end
