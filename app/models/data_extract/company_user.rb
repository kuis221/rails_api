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

class DataExtract::CompanyUser < DataExtract
  self.exportable_columns = [:first_name, :last_name, :teams_name, :email, :phone_number, :role_name,
    :street_address, :country, :state, :zip_code, :time_zone, :created_at]
end