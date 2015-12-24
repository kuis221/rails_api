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
                 venue_name: 'invited_places.name',
                 venue_street: 'trim(both \' \' from invited_places.street_number || \' \' || invited_places.route)',
                 venue_city: 'invited_places.city',
                 venue_state: 'invited_places.state',
                 venue_zipcode: 'invited_places.zipcode',
                 venue_phone_number: 'invited_places.phone_number',
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
    if join_with_venues_required?
      s = s.joins('LEFT JOIN venues invited_venues ON invited_venues.id=invites.venue_id')
          .joins('LEFT JOIN places invited_places ON invited_places.id=invited_venues.place_id')
    end
    s
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

  private

  # Only join with venues->place if a column from those tables have been seleted
  # or the list is being filtered by any of them
  def join_with_venues_required?
    columns.any? { |c| c =~ /\Avenue_/  } ||
      ( filters.present?  && filters.any? { |k,_| k =~ /\Avenue_/  } )
  end
end
