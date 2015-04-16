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

class DataExtract::Event < DataExtract
  include DataExtractEventsBase
  define_columns campaign_name: 'campaigns.name',
                   end_date: proc { "to_char(#{date_field_prefix}end_at, 'MM/DD/YYYY')" },
                   end_time: proc { "to_char(#{date_field_prefix}end_at, 'HH12:MI AM')" },
                   start_date: proc { "to_char(#{date_field_prefix}start_at, 'MM/DD/YYYY')" },
                   start_time: proc { "to_char(#{date_field_prefix}start_at, 'HH12:MI AM')" },
                   place_address1: 'places.street_number',
                   place_address2: 'places.route',
                   place_city: 'places.city',
                   place_name: 'places.name',
                   place_state: 'places.state',
                   place_zipcode: 'places.zipcode',
                   event_team_members: 'array_to_string(event_team_members.names, \', \')',
                   event_status: 'initcap(events.aasm_state)',
                   created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE events.created_by_id=us.id)',
                   created_at: proc { "to_char(events.created_at, 'MM/DD/YYYY')" },
                   status: 'CASE WHEN events.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'               
end
