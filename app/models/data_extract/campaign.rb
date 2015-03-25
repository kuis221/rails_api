# == Schema Information
#
# Table name: data_extracts
#
#  id            :integer          not null, primary key
#  type          :string(255)
#  company_id    :integer
#  active        :boolean
#  sharing       :string(255)
#  name          :string(255)
#  description   :text
#  filters       :text
#  columns       :text
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class DataExtract::Campaign < DataExtract
  self.exportable_columns = [:name, :description, :brands_list, :campaign_brand_portfolios,
    :start_date, :end_date, :color, :campaign_created_by, :created_at]
end