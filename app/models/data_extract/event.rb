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

class DataExtract::Event < DataExtract
  self.exportable_columns = [
    :campaign_name, :end_date, :end_time, :start_date, :start_time,
    :place_street, :place_city, :place_name, :place_state,
    :place_zipcode, :event_team_members, :event_status, :status]
end
