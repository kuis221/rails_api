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

class DataExtract::Role < DataExtract
  define_columns name: 'name',
                 description: 'description', 
                 created_by: 'trim(users.first_name || \' \' || users.last_name)', 
                 created_at: proc { "to_char(roles.created_at, 'MM/DD/YYYY')" },
                 active_state: 'CASE WHEN roles.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON roles.created_by_id=users.id')
    end
    s
  end

  def total_results
    Role.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(active: filters['status'].map { |f| f.downcase == 'active' ? true : false }) if filters['status'].present?
    s
  end
end
