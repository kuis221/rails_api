# == Schema Information
#
# Table name: permissions
#
#  id            :integer          not null, primary key
#  role_id       :integer
#  action        :string(255)
#  subject_class :string(255)
#  subject_id    :string(255)
#  mode          :string(255)      default("none")
#

require 'rails_helper'

describe Permission, type: :model do
  it { is_expected.to belong_to(:role) }
end
