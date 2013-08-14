class EventDataController < FilteredController

  defaults :resource_class => Event
  respond_to :xlsx, only: :index

  helper_method :data_totals

  private
    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:user) && !@search_params[:user].empty?
          @search_params[:with_event_data_only] = true
        end
        @search_params
      end
    end

    def data_totals
      @data_totals ||= Hash.new.tap do |totals|
        search_params[:per_page] = 2000
        search = resource_class.do_search(search_params)
        event_ids = search.hits.map{|h| h.stored(:id)}

        data = EventData.select('sum(impressions) AS total_impressions,
                                 sum(interactions) AS total_interactions,
                                 sum(samples) AS total_samples,
                                 sum(cost) AS total_cost,
                                 avg(gender_female) AS average_gender_female,
                                 avg(gender_male) AS average_gender_male,
                                 avg(ethnicity_asian) AS average_ethnicity_asian,
                                 avg(ethnicity_black) AS average_ethnicity_black,
                                 avg(ethnicity_hispanic) AS average_ethnicity_hispanic,
                                 avg(ethnicity_native_american) AS average_ethnicity_native_american,
                                 avg(ethnicity_white) AS average_ethnicity_white')
                        .where(["event_id IN (?)", event_ids]).all.first

        promo_hours = Event.select('avg(promo_hours) AS average_promo_hours')
                           .where(["id IN (?)", event_ids]).all.first

        totals['events_count'] = event_ids.count
        totals['promo_hours'] = promo_hours.average_promo_hours || 0
        totals['impressions'] = data.total_impressions || 0
        totals['interactions'] = data.total_interactions || 0
        totals['samples'] = data.total_samples || 0
        totals['cost'] = data.total_cost || 0
        totals['gender_female'] = data.average_gender_female || 0
        totals['gender_male'] = data.average_gender_male || 0
        totals['ethnicity_asian'] = data.average_ethnicity_asian || 0
        totals['ethnicity_black'] = data.average_ethnicity_black || 0
        totals['ethnicity_hispanic'] = data.average_ethnicity_hispanic || 0
        totals['ethnicity_native_american'] = data.average_ethnicity_native_american || 0
        totals['ethnicity_white'] = data.average_ethnicity_white || 0
      end
      @data_totals
    end
end
