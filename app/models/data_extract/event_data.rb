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

class DataExtract::EventData < DataExtract
  include DataExtractEventsBase
  include DataExtractFieldableBase

  # The name of the view to use in DataExtractFieldableBase to fetch the results
  RESULTS_VIEW_NAME = 'event_data_results'

  def form_fields
    return [] unless params.present? && params['campaign_id'].present?
    @form_fields ||= FormField.for_campaigns(params['campaign_id'])
                     .where.not(type: ['FormField::UserDate', 'FormField::Photo', 'FormField::Attachment'])
  end

  def add_filter_conditions_to_scope(s)
    s = super
    s = s.where(campaign_id: params['campaign_id']) if params && params.key?('campaign_id')
    s
  end

  def add_joins_to_scope(s)
    add_form_field_joins super
  end

  def model
    ::Event
  end

  def filters_scope
    'data_extracts_event_data'
  end

  def filters_include_calendar
    true
  end
end
