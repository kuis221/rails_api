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

class Permission < ActiveRecord::Base
  belongs_to :role

  validate :action, uniqueness: { scope: [:role_id, :subject_class] }

  after_save { role.clear_cached_permissions }
end
