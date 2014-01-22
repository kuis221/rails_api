# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#

class Report < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true, numericality: true
end
