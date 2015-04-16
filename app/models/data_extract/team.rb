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

class DataExtract::Team < DataExtract
  define_columns name: 'name',
                description: 'description',
                created_by: 'trim(users.first_name || \' \' || users.last_name)', 
                created_at: proc { "to_char(teams.created_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON teams.created_by_id=users.id')
    end
    s
  end

  def total_results
    Team.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.joins(:campaigns).where(campaigns: { id: filters[:campaign] } ) if filters.present? && filters['campaign'].present?
    s = s.where(active: filters['active_state'].map { |f| f == 'active' ? true : false }) if filters['active_state'].present?
    s
  end
end
