# == Schema Information
#
# Table name: event_expenses
#
#  id                :integer          not null, primary key
#  event_id          :integer
#  name              :string(255)
#  amount            :decimal(6, 2)    default(0.0)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class EventExpense < ActiveRecord::Base
  belongs_to :event
  attr_accessible :amount, :file, :name

  has_attached_file :file, PAPERCLIP_SETTINGS

  validates :event_id, presence: true, numericality: true
  validates :name, presence: true
end
