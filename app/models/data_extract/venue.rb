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
#

class DataExtract::Venue < DataExtract
  define_columns name: 'name', 
                 venues_types: 'array_to_string(places.types, \', \')',
                 address1: 'places.street_number',
                 address2: 'places.route',
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

  def total_results
    Venue.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end
end
