# == Schema Information
#
# Table name: event_expenses
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  name          :string(255)
#  amount        :decimal(9, 2)    default(0.0)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class EventExpense < ActiveRecord::Base
  belongs_to :event

  #validates :event_id, presence: true, numericality: true
  validates :name, presence: true

  after_save :update_event_data

  after_destroy :update_event_data

  delegate :company_id, to: :event

  has_one :receipt, class_name: 'AttachedAsset', as: :attachable

  delegate :download_url, to: :receipt

  accepts_nested_attributes_for :receipt

  private
    def update_event_data
      Resque.enqueue(EventDataIndexer, event.event_data.id) if event.event_data.present?
      Resque.enqueue(VenueIndexer, event.venue.id) if event.venue.present?
    end
end
