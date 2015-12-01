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

class DataExtract::InviteIndividual < DataExtract
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
                 rsvpd: "CASE invite_individuals.rsvpd WHEN 't' THEN 'Yes' ELSE 'No' END",
                 attended: "CASE invite_individuals.attended WHEN 't' THEN 'Yes' ELSE 'No' END",
                 first_name: 'invite_individuals.first_name',
                 last_name: 'invite_individuals.last_name',
                 email: 'invite_individuals.email',
                 mobile_phone: 'invite_individuals.mobile_phone',
                 mobile_signup: 'invite_individuals.mobile_signup',
                 attended_previous_bartender_ball: "CASE invite_individuals.attended_previous_bartender_ball WHEN 't' THEN 'Yes' ELSE 'No' END",
                 opt_in_to_future_communication: "CASE invite_individuals.opt_in_to_future_communication WHEN 't' THEN 'Yes' ELSE 'No' END",
                 primary_registrant_id: 'invite_individuals.primary_registrant_id',
                 bartender_how_long: 'invite_individuals.bartender_how_long',
                 date_of_birth: 'invite_individuals.date_of_birth',
                 zip_code: 'invite_individuals.zip_code',
                 created_at: proc { "to_char(invite_individuals.created_at, 'MM/DD/YYYY')" },
                 created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE invite_individuals.created_by_id=us.id)',
                 modified_at: proc { "to_char(invite_individuals.updated_at, 'MM/DD/YYYY')" },
                 modified_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE invite_individuals.updated_by_id=us.id)',
                 active_state: 'CASE WHEN invite_individuals.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    s = super.joins(:invite_individuals)
  end

  def total_results
    InviteIndividual.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def sort_by_column(col)
    case col
    when 'created_at'
      'invite_individuals.created_at'
    when 'updated_at'
      'invite_individuals.updated_at'
    else
      super
    end
  end
end

