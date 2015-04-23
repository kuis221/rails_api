# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

class DataExtract::Venue < DataExtract
  define_columns name: 'name',
                 venues_types: 'array_to_string(places.types, \', \')',
                 street: 'trim(places.street_number || \' \' || places.route)',
                 city: 'places.city',
                 state_name: 'places.state',
                 country_name: 'places.country',
                 zipcode: 'places.zipcode',
                 td_linx_code: 'places.td_linx_code',
                 created_by: 'trim(users.first_name || \' \' || users.last_name)',
                 created_at: proc { "to_char(venues.created_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    if (columns & ['city', 'street', 'state_name', 'country_name', 'zipcode', 'td_linx_code']).any? || filters.present? && filters['area'].present?
      s = s.joins('LEFT JOIN places ON venues.place_id=places.id')
    end
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON venues.created_by_id=users.id')
    end
    s
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(events_count: filters['events_count']['min']..filters['events_count']['max'])if filters['events_count'].present?
    s = s.where(impressions: filters['impressions']['min']..filters['impressions']['max'])if filters['impressions'].present?
    s = s.where(interactions: filters['interactions']['min']..filters['interactions']['max'])if filters['interactions'].present?
    s = s.where(promo_hours: filters['promo_hours']['min']..filters['promo_hours']['max'])if filters['promo_hours'].present?
    s = s.where(sampled: filters['sampled']['min']..filters['sampled']['max'])if filters['sampled'].present?
    s = s.where(score: filters['venue_score']['min']..filters['venue_score']['max'])if filters['venue_score'].present?
    s = s.where(spent: filters['spent']['min']..filters['spent']['max'])if filters['spent'].present?
    s = s.filters_between_dates(filters['start_date'].to_s, filters['end_date'].to_s) if filters['start_date'].present? && filters['end_date'].present?
    s
  end

  def total_results
    Venue.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def sort_by_column(col)
    case col
    when 'created_at'
      'venues.created_at'
    else
      super
    end
  end

  def filters_include_calendar
    true
  end
end
