# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

class DataExtract::BrandAmbassadorsVisit < DataExtract
  define_columns employee: 'users.first_name || \' \' || users.last_name',
                 campaign_name: 'campaigns.name',
                 area_name: 'areas.name',
                 city: 'city',
                 visit_type: 'visit_type',
                 description: 'description',
                 start_date: proc { "to_char(brand_ambassadors_visits.start_date, 'MM/DD/YYYY')" },
                 end_date: proc { "to_char(brand_ambassadors_visits.end_date, 'MM/DD/YYYY')" },
                 created_at: proc { "to_char(brand_ambassadors_visits.created_at, 'MM/DD/YYYY')" },
                 modified_at: proc { "to_char(brand_ambassadors_visits.updated_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    s = s.joins('LEFT JOIN company_users '\
                'ON company_users.id = brand_ambassadors_visits.company_user_id '\
                'LEFT JOIN users '\
                'ON users.id = company_users.user_id') if columns.include?('employee')
    s = s.joins('LEFT JOIN campaigns '\
                'ON campaigns.id = brand_ambassadors_visits.campaign_id') if columns.include?('campaign_name')
    s = s.joins('LEFT JOIN areas '\
                'ON areas.id = brand_ambassadors_visits.area_id') if columns.include?('area_name')
    s
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(campaign_id: filters['campaign']) if filters['campaign'].present?
    s = s.where(company_user_id: filters['user']) if filters['user'].present?
    s = s.where(area_id: filters['area']) if filters['area'].present?
    s = s.where(city: filters['city']) if filters['city'].present?
    s = s.filters_between_dates(filters['start_date'].to_s, filters['end_date'].to_s) if filters['start_date'].present? && filters['end_date'].present?
    s
  end

  def self.model
    ::BrandAmbassadors::Visit
  end

  def sort_by_column(col)
    case col
    when 'start_date'
      'brand_ambassadors_visits.start_date'
    when 'end_date'
      'brand_ambassadors_visits.end_date'
    when 'created_at'
      'brand_ambassadors_visits.created_at'
    when 'modified_at'
      'brand_ambassadors_visits.updated_at'
    else
      super
    end
  end

  def filters_scope
    'visits'
  end

  def filters_include_calendar
    true
  end
end
