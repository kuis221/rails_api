# == Schema Information
#
# Table name: permissions
#
#  id            :integer          not null, primary key
#  role_id       :integer
#  action        :string(255)
#  subject_class :string(255)
#  subject_id    :string(255)
#

class Permission < ActiveRecord::Base
  belongs_to :role

  attr_accessible :action, :subject_class, :enabled

  validate :action, uniqueness: { scope: [:role_id, :subject_class] }

  attr_accessor :enabled

  def enabled=(value)
    mark_for_destruction if value.to_s == '0'
  end

  def enabled
    persisted?
  end
end
