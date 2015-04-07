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

class DataExtract::Brand < DataExtract
  define_columns name: 'brands.name', 
                 marques_list: 'array_to_string(array_agg(marques.name), \', \')', 
                 created_by: 'trim(users.first_name || \' \' || users.last_name)', 
                 created_at: proc { "to_char(brands.created_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON brands.created_by_id=users.id')
    end
    if columns.include?('marques_list')
      s = s.joins('LEFT JOIN marques ON brands.id=marques.brand_id')
           .group(group_by_columns)
    end
    s
  end

  def total_results
    Brand.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def group_by_columns
    (
      ['brands.id'] + columns.each_with_index.map { |c, i| i + 1 } -
      [columns.index('marques_list') + 1]     # Do not group by marques
    ).join(',')
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.joins(:campaigns).where(campaigns: { id: filters[:campaign] } ) if filters.present? && filters['campaign'].present?
    s = s.where(active: filters['active_state'].map { |f| f == 'active' ? true : false }) if filters['active_state'].present?
    s
  end
end
