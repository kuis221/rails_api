# == Schema Information
#
# Table name: event_expenses
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  amount        :decimal(15, 2)   default("0")
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  brand_id      :integer
#  category      :string(255)
#  expense_date  :date
#  reimbursable  :boolean
#  billable      :boolean
#  merchant      :string(255)
#  description   :text
#

class EventExpense < ActiveRecord::Base
  belongs_to :event
  belongs_to :brand
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  track_who_does_it

  has_paper_trail

  # validates :event_id, presence: true, numericality: true
  validates :category, presence: true
  validates :expense_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :valid_receipt?, if: :receipt_required?
  validate :max_event_expenses, on: :create

  after_commit :update_event_data
  #after_save :update_event_data
  #after_destroy :update_event_data

  delegate :company_id, :campaign_id, to: :event

  has_one :receipt, class_name: 'AttachedAsset', as: :attachable, inverse_of: :attachable, dependent: :destroy

  delegate :download_url, to: :receipt

  accepts_nested_attributes_for :receipt,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['direct_upload_url'].blank? && attributes['_destroy'].blank? }

  scope :for_user_accessible_events, ->(company_user) { joins('INNER JOIN events ec ON ec.id=event_id AND ec.id in (' + Event.select('events.id').where(company_id: company_user.company_id).accessible_by_user(company_user).to_sql + ')') }

  scope :order_by_id_asc, -> { order('id ASC') }

  after_initialize do
    if event.present? && event.start_at.present? && new_record?
      self.expense_date ||= event.start_at.to_date
    end
  end

  def receipt_required?
    return false unless event.present?
    event.campaign.module_setting('expenses', 'required') == 'true'
  end

  private

  def update_event_data
    return unless event.present?
    EventDataIndexer.perform_async(event.event_data.id) if event.event_data.present?
    VenueIndexer.perform_async(event.venue.id) if event.venue.present?
  end

  def valid_receipt?
    build_receipt unless receipt.present?
    receipt.errors.add(:file, :required)
  end

  def max_event_expenses
    return true unless event.present? && event.campaign.range_module_settings?('expenses')
    max = event.campaign.module_setting('expenses', 'range_max')
    return true if max.blank? || event.event_expenses.count < max.to_i
    errors.add(:base, I18n.translate('instructive_messages.execute.expense.add_exceeded.create', count: max))
  end
end
