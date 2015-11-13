# == Schema Information
#
# Table name: custom_filters
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  apply_to     :string(255)
#  filters      :text
#  created_at   :datetime
#  updated_at   :datetime
#  owner_id     :integer
#  owner_type   :string(255)
#  default_view :boolean          default(FALSE)
#  category_id  :integer
#

class CustomFilter < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  belongs_to :category, class_name: 'CustomFiltersCategory'

  # TODO: Make this list be loaded form the the filters.yml file
  APPLY_TO_OPTIONS = %w(events venues tasks visits company_users teams roles campaigns brands
                        activity_types areas brand_portfolios date_ranges day_parts event_data activities results_comments
                        results_expenses results_photos surveys)

  # Required fields
  validates :owner, presence: true
  validates :name, presence: true

  validates :apply_to, presence: true, inclusion: { in: APPLY_TO_OPTIONS }
  validates :filters, presence: true

  attr_accessor :start_date, :end_date, :criteria

  scope :by_type, ->(type) { order('id ASC').where(apply_to: type) }
  scope :user_saved_filters, -> { where(category: nil) }
  scope :not_user_saved_filters, -> { where.not(category: nil) }

  scope :for_company_user, ->(company_user) {
    where(
      '(owner_type=? AND owner_id=?) OR (owner_type=? AND owner_id=?)',
      'Company', company_user.company_id, 'CompanyUser', company_user.id
    )
  }

  def to_params
    remove_invalid_dates Rack::Utils.parse_nested_query(filters)
  end

  private

  def remove_invalid_dates(values)
    if (values['start_date'].blank? || values['end_date'].blank?) ||
       (values['start_date'].present? && values['end_date'].present? &&
        values['start_date'].kind_of?(Array) && values['end_date'].kind_of?(Array) &&
        values['start_date'].length != values['end_date'].length)
      values.delete('start_date')
      values.delete('end_date')
    end
    values
  end
end
