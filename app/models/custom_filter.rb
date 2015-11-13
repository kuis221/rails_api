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

  def remove_invalid_dates_filters
    url_query_string = Rack::Utils.parse_nested_query(filters)
    if (url_query_string['start_date'].blank? || url_query_string['end_date'].blank?) ||
       (url_query_string['start_date'].present? && url_query_string['end_date'].present? &&
        url_query_string['start_date'].length != url_query_string['end_date'].length)
      url_query_string.delete('start_date')
      url_query_string.delete('end_date')
    end
    url_query_string.to_query
  end
end
