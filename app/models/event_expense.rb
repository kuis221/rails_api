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
#  brand_id      :integer
#

class EventExpense < ActiveRecord::Base
  belongs_to :event
  belongs_to :brand

  # validates :event_id, presence: true, numericality: true
  validates :name, presence: true
  validates :amount, presence: true, numericality: true
  validate :valid_receipt?, if: :receipt_required?

  after_save :update_event_data

  after_destroy :update_event_data

  delegate :company_id, :campaign_id, to: :event

  has_one :receipt, class_name: 'AttachedAsset', as: :attachable, inverse_of: :attachable

  delegate :download_url, to: :receipt

  accepts_nested_attributes_for :receipt,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['direct_upload_url'].blank? && attributes['_destroy'].blank? }

  def receipt_required?
    return false unless event.present?
    event.campaign.module_setting('expenses', 'required') == 'true'
  end

  private

  def update_event_data
    return unless event.present?
    Resque.enqueue(EventDataIndexer, event.event_data.id) if event.event_data.present?
    Resque.enqueue(VenueIndexer, event.venue.id) if event.venue.present?
  end

  def valid_receipt?
    build_receipt unless receipt.present?
    receipt.errors.add(:file, :required)
  end
end
