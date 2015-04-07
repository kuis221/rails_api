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

class DataExtract::Campaign < DataExtract
  define_columns name: 'campaigns.name', 
                 description: 'campaigns.description', 
                 brands_list: 'array_to_string(array_agg(brands.name), \', \')', 
                 campaign_brand_portfolios: 'array_to_string(array_agg(brand_portfolios.name), \', \')',
                 start_date: proc { "to_char(campaigns.start_date, 'MM/DD/YYYY')" }, 
                 end_date: proc { "to_char(campaigns.end_date, 'MM/DD/YYYY')" }, 
                 color: 'color', 
                 created_by: 'trim(users.first_name || \' \' || users.last_name)', 
                 created_at: proc { "to_char(campaigns.created_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    s = s.joins('LEFT JOIN places ON places.id=events.place_id') if columns.any? { |c| c.match(/^place_/)  }
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON brands.created_by_id=users.id')
    end
    if columns.include?('brands_list')
      s = s.joins('LEFT JOIN brands_campaigns ON campaigns.id=brands_campaigns.campaign_id')
           .joins('LEFT JOIN brands ON brands.id=brands_campaigns.brand_id')
    end
    if columns.include?('campaign_brand_portfolios')
      s = s.joins('LEFT JOIN brand_portfolios_campaigns ON campaigns.id=brand_portfolios_campaigns.campaign_id')
           .joins('LEFT JOIN brand_portfolios ON brand_portfolios.id=brand_portfolios_campaigns.brand_portfolio_id')
    end
    s.group('campaigns.id')
  end

  def group_by_columns(column_name)
    (
      ['campaigns.id'] + columns.each_with_index.map { |c, i| i + 1 } -
      [columns.index(column_name) + 1]
    ).join(',')
  end
end
