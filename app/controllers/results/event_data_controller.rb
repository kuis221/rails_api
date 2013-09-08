class Results::EventDataController < FilteredController

  defaults :resource_class => ::Event
  respond_to :xlsx, only: :index

  helper_method :data_totals

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
