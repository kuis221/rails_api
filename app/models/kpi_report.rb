# == Schema Information
#
# Table name: kpi_reports
#
#  id                :integer          not null
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

class KpiReport < ActiveRecord::Base
  include AASM

  has_attached_file :file, PAPERCLIP_SETTINGS

  do_not_validate_attachment_file_type :file

  belongs_to :company_user

  serialize :params

  aasm do
    state :new, :initial => true
    state :queued, :enter => :queue_report
    state :processing
    state :complete, :enter => :progress_complete
    state :failed

    event :queue do
      transitions :from => :new, :to => :queued
    end

    event :process do
      transitions :from => :queued, :to => :processing
    end

    event :succeed do
      transitions :from => :processing, :to => :complete
    end

    event :fail do
      transitions :from => [:queued, :processing, :complete, :failed], :to => :failed
    end

    event :regenerate do
      transitions :from => [:queued, :processing, :complete, :failed], :to => :queued, :before => :destroy_report
    end
  end

  def download_url(style_name=:original)
    file.s3_bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  def generate_report
    return unless queued?
    self.process!
    self.file = StringIO.new(report_output)
    self.file_file_name = object_name
    self.file_content_type = 'text/csv'
    self.save
    self.succeed!
    rescue Exception => e
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.join("\n")
      self.fail!
      raise e
  end

  def report_output
    CSV.generate do |csv|
      csv << ['TD Linx','Brand','Date', 'Cm # Consumer Impressions', 'Cm # Consumers Sampled', 'Cm Total Consumers',
              'Cm Promo Hours', 'Cm # Events', 'Cm Bar Spend', 'Fytd # Consumer Impressions',
              'Fytd # Consumers Sampled', 'Fytd Total Consumers', 'Fytd Promo Hours',
              'Fytd # Events', 'Bar Spend', 'Area', 'Venue', 'Program']

      i = 0
      total = campaigns.count
      start_year = the_month.year-1
      start_year += 1 unless the_month.month < 7
      fytd_start = Date.new(start_year, Date::MONTHNAMES.index('July')).beginning_of_month.beginning_of_day
      fytd_end = the_month.end_of_month.end_of_day

      campaigns.find_each(batch_size: 10) do |campaign|
        impressions_field = campaign.form_field_for_kpi(::Kpi.impressions)
        sampled_field = campaign.form_field_for_kpi(::Kpi.samples)
        show_progress(i+=1, total)
        brands = campaign.brands.map(&:name).to_sentence
        scoped_events = ::Event.where(campaign_id: campaign.id).active.approved
        places = Place.where(id: scoped_events.select('DISTINCT(place_id) as place_id'))
        places.each do |place|
          place_events = scoped_events.where(place_id: place)
          place_events_fytd = place_events.between_dates(fytd_start, fytd_end)
          place_events_cm = place_events.between_dates(the_month.beginning_of_month.beginning_of_day, the_month.end_of_month.end_of_day)
          csv << [
            place.td_linx_code, #TD Linx
            brands,         # Brand
            the_month.to_formatted_s(:year_month),            # Date
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
      campaigns = Campaign.active.accessible_by_user(company_user)
      campaigns = campaigns.where(id: params[:campaign_id]) if params[:campaign_id].present? && params[:campaign_id].map(&:to_i).select{|id| id > 0 }.any?
      campaigns
    end
  end

  def the_month
    @month ||= Date.new(params[:year].to_i, params[:month].to_i)
  end

  def the_month_name
    @month_name ||= Date.new(params[:year].to_i, params[:month].to_i).strftime("%B")
  end


  def sum_expenses(s)
    s.joins(:event_expenses).sum('event_expenses.amount')
  end

  def sum_results(s, field)
    field.nil? ? 0 : s.joins(:results).where(form_field_results: {form_field_id: field}).sum(:scalar_value).to_f || 0
  end

  def object_name
    "kpi-report-#{company_user.full_name.parameterize}-#{created_at.to_s.parameterize}.csv"
  end

  private

    def queue_report
      set_progress(0)
      Resque.enqueue KpiReportWorker, self.id
    end

    def progress_complete
      set_progress(100)
    end

    def set_progress(progress)
      unless progress.nil?
        progress = [[progress, 100].min, 0].max unless progress.nil?
        self.update_column(:progress, progress)
      end
    end

    def show_progress(completed, total)
      progress = completed*100/total rescue 0         # rescue from divide by zero
      set_progress(progress)
    end
end
