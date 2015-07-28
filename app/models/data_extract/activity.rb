# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default(TRUE)
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

class DataExtract::Activity < DataExtract
  include DataExtractFieldableBase

  # The name of the view to use in DataExtractFieldableBase to fetch the results
  RESULTS_VIEW_NAME = 'activity_results'

  define_columns activity_type: 'activity_types.name',
                 user: 'users.first_name || \' \' || users.last_name',
                 activity_date: proc { "to_char(activity_date, 'MM/DD/YYYY HH12:MI AM')" },
                 campaign_name: 'campaigns.name',
                 event_start_date: proc { "to_char(events.start_at, 'MM/DD/YYYY')" },
                 event_start_time: proc { "to_char(events.start_at, 'HH12:MI AM')" },
                 event_end_date: proc { "to_char(events.end_at, 'MM/DD/YYYY')" },
                 event_end_time: proc { "to_char(events.end_at, 'HH12:MI AM')" },
                 place_street: 'trim(both \' \' from places.street_number || \' \' || places.route)',
                 place_city: 'places.city',
                 place_name: 'places.name',
                 place_state: 'places.state',
                 place_zipcode: 'places.zipcode',
                 event_status: 'initcap(events.aasm_state)',
                 status: 'CASE WHEN events.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END',
                 created_at: proc { "to_char(activities.created_at, 'MM/DD/YYYY')" },
                 created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE activities.created_by_id=us.id)',
                 modified_at: proc { "to_char(activities.updated_at, 'MM/DD/YYYY')" },
                 modified_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE activities.updated_by_id=us.id)'


  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(campaign_id: filters['campaign']) if filters['campaign'].present?
    s = s.where(company_user_id: filters['user']) if filters['user'].present?
    s = s.where(events: { active: filters['status'].map { |f| f.downcase == 'active' ? true : false } }) if filters['status'].present?
    s = s.where(activity_type_id: params['activity_type_id']) if params && params.key?('activity_type_id')
    s = s.joins('LEFT JOIN brands_campaigns ON brands_campaigns.campaign_id=events.campaign_id')
            .where("brands_campaigns.brand_id IN (#{filters['brand'].join(', ')})") if filters['brand'].present?
    s = s.in_areas(filters['area']) if filters['area'].present?
    s = s.in_places(filters['place']) if filters['place'].present?
    s
  end

  def add_joins_to_scope(s)
    s = s.joins(:campaign) if columns.include?('campaign_name')
    s = s.joins(:activity_type) if columns.include?('activity_type')
    s = s.joins(company_user: :user) if columns.include?('user')
    if columns.any? { |c| c.match(/^event_/) || c == 'status' } || filtered_by?(['brand', 'campaign', 'area'])
      s = s.joins('LEFT JOIN events ON events.id=activities.activitable_id AND activities.activitable_type=\'Event\'')
    end
    if columns.any? { |c| c.match(/^place_/)  }
      s = s.joins('LEFT JOIN venues ON venues.id=activities.activitable_id AND activities.activitable_type=\'Venue\'')
          .joins('LEFT JOIN places ON places.id=venues.place_id')
    end
    add_form_field_joins s
  end

  def model
    ::Activity
  end

  def form_fields
    return [] unless params.present? && params['activity_type_id'].present?
    @form_fields ||= FormField.for_activity_types(params['activity_type_id'])
                     .where.not(type: ['FormField::UserDate', 'FormField::Photo', 'FormField::Attachment'] )
  end

  def filters_scope
    'data_extract_activities'
  end

  def sort_by_column(col)
    case col
    when 'event_start_date'
      'events.start_at'
    when 'event_end_date'
      'events.end_at'
    when 'activity_date'
      'activity_date'
    else
      super
    end
  end
end
