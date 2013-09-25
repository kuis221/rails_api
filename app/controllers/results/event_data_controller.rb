class Results::EventDataController < FilteredController

  defaults :resource_class => ::Event
  # respond_to :xlsx, only: :index

  skip_load_and_authorize_resource only: [:download, :new_download, :download_status]

  helper_method :data_totals

  # def index
  #   if request.format.xlsx?
  #     collection
  #     ids = @solr_search.hits.map{|hit| hit.primary_key}
  #     @data_scope = EventData.joins(event: :campaign).select('campaigns.name as campaign_name, events.promo_hours, event_data.*').where(events: {id: ids})
  #   else
  #     super
  #   end
  # end

  def download
    @download = ListExport.find_by_id(params[:download_id])
  end

  def new_download
    @download = ListExport.create(list_class: resource_class.to_s, params: search_params, export_format: 'xls')
    if @download.new?
      @download.queue!
    end
  end

  def download_status
    url = nil
    download = ListExport.find_by_id(params[:download_id])
    url = download.download_url if download.completed?
    respond_to do |format|
      format.json { render json:  {status: download.aasm_state, url: url} }
    end
  end

  private
    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:user) && !@search_params[:user].empty?
          @search_params[:with_event_data_only] = true
        end
        @search_params[:event_data_stats] = true
        @search_params
      end
    end

    def data_totals
      @data_totals ||= Hash.new.tap do |totals|
        totals['events_count'] = @solr_search.total
        totals['promo_hours'] = @solr_search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
        totals['impressions'] = @solr_search.stat_response['stats_fields']["impressions_es"]['sum'] rescue 0
        totals['interactions'] = @solr_search.stat_response['stats_fields']["interactions_es"]['sum'] rescue 0
        totals['samples'] = @solr_search.stat_response['stats_fields']["samples_es"]['sum'] rescue 0
        totals['spent'] = @solr_search.stat_response['stats_fields']["spent_es"]['sum'] rescue 0
        totals['gender_female'] = @solr_search.stat_response['stats_fields']["gender_female_es"]['mean'] rescue 0
        totals['gender_male'] = @solr_search.stat_response['stats_fields']["gender_male_es"]['mean'] rescue 0
        totals['ethnicity_asian'] = @solr_search.stat_response['stats_fields']["ethnicity_asian_es"]['mean'] rescue 0
        totals['ethnicity_black'] = @solr_search.stat_response['stats_fields']["ethnicity_black_es"]['mean'] rescue 0
        totals['ethnicity_hispanic'] = @solr_search.stat_response['stats_fields']["ethnicity_hispanic_es"]['mean'] rescue 0
        totals['ethnicity_native_american'] = @solr_search.stat_response['stats_fields']["ethnicity_native_american_es"]['mean'] rescue 0
        totals['ethnicity_white'] = @solr_search.stat_response['stats_fields']["ethnicity_white_es"]['mean'] rescue 0
      end
      @data_totals
    end
end
