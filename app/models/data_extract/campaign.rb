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

class DataExtract::Campaign < DataExtract
  define_columns name: 'campaigns.name',
                 description: 'campaigns.description',
                 brands_list: 'array_to_string(ARRAY(SELECT brands.name FROM brands
                              LEFT JOIN brands_campaigns ON campaigns.id=brands_campaigns.campaign_id
                              WHERE brands.id=brands_campaigns.brand_id ),\', \') AS brands_list',
                 campaign_brand_portfolios: 'array_to_string(ARRAY(SELECT brand_portfolios.name FROM brand_portfolios
                              LEFT JOIN brand_portfolios_campaigns ON campaigns.id=brand_portfolios_campaigns.campaign_id
                              WHERE brand_portfolios.id=brand_portfolios_campaigns.brand_portfolio_id ),\', \') AS campaign_brand_portfolios',
                 start_date: proc { "to_char(campaigns.start_date, 'MM/DD/YYYY')" },
                 end_date: proc { "to_char(campaigns.end_date, 'MM/DD/YYYY')" },
                 color: 'color',
                 created_by: 'trim(users.first_name || \' \' || users.last_name)',
                 created_at: proc { "to_char(campaigns.created_at, 'MM/DD/YYYY')" },
                 active_state: 'CASE WHEN campaigns.aasm_state=\'active\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    s = s.joins('LEFT JOIN places ON places.id=events.place_id') if columns.any? { |c| c.match(/^place_/)  }
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON campaigns.created_by_id=users.id')
    end
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.joins('LEFT JOIN brands_campaigns AS brands ON brands.campaign_id = campaigns.id')
          .where("brands.brand_id IN (#{filters['brand'].join(', ')})") if filters['brand'].present?
    s = s.joins('LEFT JOIN brand_portfolios_campaigns AS portfolios ON portfolios.campaign_id = campaigns.id')
          .where("portfolios.brand_portfolio_id IN (#{filters['brand_portfolio'].join(', ')})") if filters['brand_portfolio'].present?
    s = s.joins('LEFT JOIN company_users ON company_users.user_id = users.id')
          .where("company_users.user_id IN (#{filters['user'].join(', ')})") if filters['user'].present?
    s = s.where(aasm_state: filters['status'].map { |f| f.downcase == 'active' ? 'active' : 'inactive' }) if filters['status'].present?
    s
  end

  def sort_by_column(col)
    case col
    when 'start_date'
      'campaigns.start_date'
    when 'end_date'
      'campaigns.end_date'
    when 'created_at'
      'campaigns.created_at'
    else
      super
    end
  end
end
