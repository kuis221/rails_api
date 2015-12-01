# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

class DataExtract::Invite < DataExtract
  include DataExtractEventsBase

  define_columns campaign_name: 'campaigns.name',
                 end_date: proc { "to_char(#{date_field_prefix}end_at, 'MM/DD/YYYY')" },
                 end_time: proc { "to_char(#{date_field_prefix}end_at, 'HH12:MI AM')" },
                 start_date: proc { "to_char(#{date_field_prefix}start_at, 'MM/DD/YYYY')" },
                 start_time: proc { "to_char(#{date_field_prefix}start_at, 'HH12:MI AM')" },
                 event_status: 'initcap(events.aasm_state)',
                 place_name: 'places.name',
                 place_street: 'trim(both \' \' from places.street_number || \' \' || places.route)',
                 place_city: 'places.city',
                 place_state: 'places.state',
                 place_zipcode: 'places.zipcode',
                 attendees: 'invites.attendees',
                 invitees: 'invites.invitees',
                 rsvps: 'invites.rsvps_count',
                 created_at: proc { "to_char(invites.created_at, 'MM/DD/YYYY')" },
                 created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE invites.created_by_id=us.id)',
                 modified_at: proc { "to_char(invites.updated_at, 'MM/DD/YYYY')" },
                 modified_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE invites.updated_by_id=us.id)',
                 active_state: 'CASE WHEN invites.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    s = super.joins(:invites)
  end

  def total_results
    Invite.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def sort_by_column(col)
    case col
    when 'created_at'
      'invites.created_at'
    else
      super
    end
  end
end

