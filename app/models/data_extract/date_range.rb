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

class DataExtract::DateRange < DataExtract
  define_columns name: 'name',
                 description: 'description',
                 created_at: proc { "to_char(date_ranges.created_at, 'MM/DD/YYYY')" },
                 created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE date_ranges.created_by_id=us.id)',
                 modified_at: proc { "to_char(date_ranges.updated_at, 'MM/DD/YYYY')" },
                 modified_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE date_ranges.updated_by_id=us.id)',
                 active_state: 'CASE WHEN date_ranges.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON date_ranges.created_by_id=users.id')
    end
    s
  end

  def total_results
    DateRange.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(active: filters['status'].map { |f| f.downcase == 'active' ? true : false }) if filters['status'].present?
    s
  end

  def sort_by_column(col)
    case col
    when 'created_at'
      'date_ranges.created_at'
    else
      super
    end
  end
end
