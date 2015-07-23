# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default(TRUE)
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

class DataExtract::Place < DataExtract
  define_columns name: 'name',
                 venues_types: "initcap(replace(array_to_string(types, \', \'), '_', ' '))",
                 street: 'trim(street_number || \' \' || route)',
                 city: 'city',
                 state_name: 'state',
                 country_name: 'country',
                 score: 'score',
                 zipcode: 'zipcode',
                 td_linx_code: 'td_linx_code',
                 created_by: 'trim(users.first_name || \' \' || users.last_name)',
                 created_at: proc { "to_char(venues.created_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON venues.created_by_id=users.id')
    end
    s
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(venues: { events_count: filters['events_count']['min']..filters['events_count']['max']}) if filters['events_count'].present?
    s = s.where(venues: { impressions: filters['impressions']['min']..filters['impressions']['max']}) if filters['impressions'].present?
    s = s.where(venues: { interactions: filters['interactions']['min']..filters['interactions']['max']}) if filters['interactions'].present?
    s = s.where(venues: { promo_hours: filters['promo_hours']['min']..filters['promo_hours']['max']}) if filters['promo_hours'].present?
    s = s.where(venues: { sampled: filters['sampled']['min']..filters['sampled']['max']}) if filters['sampled'].present?
    s = s.where(venues: { score: filters['venue_score']['min']..filters['venue_score']['max']}) if filters['venue_score'].present?
    s = s.where(venues: { spent: filters['spent']['min']..filters['spent']['max']}) if filters['spent'].present?
    s = s.where("places.price_level IN (#{filters['event_status'].join(', ')})") if filters['event_status'].present?
    s = s.filters_between_dates(filters['start_date'].to_s, filters['end_date'].to_s) if filters['start_date'].present? && filters['end_date'].present?
    s = in_areas(s, filters['area']) if  filters['area'].present?
    location_ids = ::Place.where(id: filters['place'], is_location: true).pluck(:location_id) if filters['place'].present?
    s = s.joins('LEFT JOIN locations_places lp ON lp.place_id=places.id').uniq
          .where("(places.location_id IN (#{location_ids.join(',')}))") if filters['place'].present?
    s = in_campaigns(s, filters['campaign'].join(', ')) if filters['campaign'].present?
    s
  end

  def total_results
    ::Place.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
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

  def filters_scope
    'venues'
  end

  def in_areas(s, areas)
    subquery = ::Place.select('DISTINCT places.location_id')
               .joins(:placeables).where(placeables: { placeable_type: 'Area', placeable_id: areas }, is_location: true)
    place_query = "select DISTINCT place_id FROM locations_places INNER JOIN (#{subquery.to_sql})"\
                  ' locations on locations.location_id=locations_places.location_id'
    area_query = Placeable.select('place_id')
                 .where(placeable_type: 'Area', placeable_id: areas + [0]).to_sql
    s = s.joins("INNER JOIN (#{area_query} UNION #{place_query}) areas_places ON places.id=areas_places.place_id")
    s
  end

  def in_campaigns(s, campaigns)
    s = s.joins(:placeables)
            .where("(placeables.placeable_type='Campaign' AND placeables.placeable_id IN (#{campaigns})) OR
              (placeables.placeable_type='Area' AND placeables.placeable_id  in (
              select area_id FROM areas_campaigns where campaign_id IN (#{campaigns})))")
    s
  end
end
