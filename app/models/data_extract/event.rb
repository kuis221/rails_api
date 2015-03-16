class DataExtract::Event < DataExtract
  self.exportable_columns = [
    :campaign_name, :end_date, :end_time, :start_date, :start_time,
    :place_street, :place_city, :place_name, :place_state,
    :place_zipcode, :event_team_members, :event_status, :status]
end
