# == Schema Information
#
# Table name: event_expenses
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  name          :string(255)
#  amount        :decimal(15, 2)   default(0.0)
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
  validate :event_expenses, before: :create

  after_save :update_event_data

  after_destroy :update_event_data

  delegate :company_id, :campaign_id, to: :event

  has_one :receipt, class_name: 'AttachedAsset', as: :attachable, inverse_of: :attachable

  delegate :download_url, to: :receipt

  accepts_nested_attributes_for :receipt,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['direct_upload_url'].blank? && attributes['_destroy'].blank? }

  scope :for_user_accessible_events, ->(company_user) { joins('INNER JOIN events ec ON ec.id=event_id AND ec.id in (' + Event.select('events.id').where(company_id: company_user.company_id).accessible_by_user(company_user).to_sql + ')') }

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

  def event_expenses
    return true unless event.campaign.range_module_settings?('expenses')
    max = event.campaign.module_setting('expenses', 'range_max')
    errors.add(:base, I18n.translate('instructive_messages.execute.expense.add_exceeded.create', expenses_max: max)) if event.event_expenses.count >= max.to_i
  end
end
