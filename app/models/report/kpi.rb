# == Schema Information
#
# Table name: reports
#
#  id                :integer          not null, primary key
#  type              :string(255)
#  company_user_id   :integer
#  params            :text
#  aasm_state        :string(255)
#  progress          :integer
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'report'

class Report::Kpi < Report
  def report_output
    CSV.generate do |csv|
      csv << ['TD Linx','Brand','Date', 'Cm # Consumer Impressions', 'Cm # Consumers Sampled', 'Cm Total Consumers',
              'Cm Promo Hours', 'Cm # Events', 'Cm Bar Spend', 'Fytd # Consumer Impressions',
              'Fytd # Consumers Sampled', 'Fytd Total Consumers', 'Fytd Promo Hours Fytd',
              '# Events Fytd', 'Bar Spend', 'Area', 'Venue', 'Program']

      i = 0
      total = campaigns.count
      start_year = the_month.year-1
      start_year += 1 unless the_month.month < 7
      fytd_start = Date.new(start_year, Date::MONTHNAMES.index('July')).beginning_of_month
      fytd_end = Date.new(start_year+1, Date::MONTHNAMES.index('June')).end_of_month.end_of_day

      campaigns.find_each(batch_size: 10) do |campaign|
        impressions_field = campaign.form_field_for_kpi(::Kpi.impressions)
        sampled_field = campaign.form_field_for_kpi(::Kpi.samples)
        show_progress(i+=1, total)
        brands = campaign.brands.map(&:name).to_sentence
        scoped_events = Event.scoped_by_campaign_id(campaign.id).active.approved
        places = Place.where(id: scoped_events.select('DISTINCT(place_id) as place_id'))
        places.each do |place|
          place_events = scoped_events.scoped_by_place_id(place)
          place_events_fytd = place_events.between_dates(fytd_start, fytd_end)
          place_events_cm = place_events.between_dates(the_month.beginning_of_month, the_month.end_of_month)
          csv << [
            place.td_linx_code, #TD Linx
            brands,         # Brand
            nil,            # Date
            impressions = sum_results(place_events_cm, impressions_field),     # Cm # Consumer Impressions
            samples = sum_results(place_events_cm, sampled_field),             # Cm # Consumers Sampled
            impressions + samples,                                             # Cm Total Consumers
            place_events_cm.sum(:promo_hours),                                 # Cm Promo Hours
            place_events_cm.count,                                             # Cm # Events
            sum_expenses(place_events_cm),                                     # Cm Bar Spend
            impressions = sum_results(place_events_fytd, impressions_field),   # Cm # Consumer Impressions
            samples = sum_results(place_events_fytd, sampled_field),           # Cm # Consumers Sampled
            impressions + samples,                                             # Cm Total Consumers
            place_events_fytd.sum(:promo_hours),                               # Fytd Promo Hours Fytd
            place_events_fytd.count,                                           # Events Fytd
            sum_expenses(place_events_fytd),                                   # Bar Spend
            campaign.areas.select{|a| a.place_in_scope?(place)}.map(&:name).to_sentence,  # Areas
            place.name,     # Venue
            campaign.name   # Campaign
          ]
        end
      end
    end
  end

  def campaigns
    @campaigns ||= begin
      campaigns = Campaign.accessible_by_user(company_user)
      campaigns = campaigns.where(id: params[:campaign_id]) if params[:campaign_id].present? && params[:campaign_id].map(&:to_i).select{|id| id > 0 }.any?
      campaigns
    end
  end

  def the_month
    p params[:month].to_i
    @month ||= Date.new(params[:year].to_i, params[:month].to_i)
  end

  def sum_expenses(s)
    s.joins(:event_expenses).sum('event_expenses.amount')
  end

  def sum_results(s, field)
    field.nil? ? 0 : s.joins(:results).where(event_results: {form_field_id: field}).sum(:scalar_value).to_f || 0
  end
end
