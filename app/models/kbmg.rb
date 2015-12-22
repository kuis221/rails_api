class KBMG
  include HTTParty

  base_uri 'https://reachv4-pnr.kbmg.com'
  attr_accessor :api_token

  def initialize(api_token)
    @api_token = api_token
  end

  def events(params = nil)
    self.class.get('/Events/EventsGet', query_options(params))
  end

  def event(event_id, params = {})
    params.merge!(search_string: "EventId==#{event_id}")
    response = self.class.get('/Events/EventsGet', query_options(params))
    return unless response && response['Success'] == true
    Rails.logger.info "expected response to return 1 event but returned #{response['Data']['Events'].count}" if response['Data']['Events'].count != 1
    return unless response['Data']['Events'].any?
    response['Data']['Events'][0]
  end

  def event_registrations(event_id)
    params = { search_string: "EventId==#{event_id}" }
    self.class.get('/Registrations/EventRegistrationsGetAll', query_options(params))
  end

  def person(person_id)
    params = { search_string: "PersonId==#{person_id}" }
    response = self.class.get('/People/PeopleGet', query_options(params))
    return unless response && response['Success'] == true
    Rails.logger.info "expected response to return 1 person but returned #{response['Data']['People'].count}" if response['Data']['People'].count != 1
    return unless response['Data']['People'].any?
    response['Data']['People'][0]
  end

  def place(place_id)
    params = { search_string: "PlaceId==#{place_id}" }
    response = self.class.get('/Places/PlacesGet', query_options(params))
    return unless response && response['Success'] == true
    Rails.logger.info "expected response to return 1 place but returned #{response['Data']['Places'].count}" if response['Data']['Places'].count != 1
    return unless response['Data']['Places'].any?
    response['Data']['Places'][0]
  end

  private

  def query_options(params = {})
    {
      query: { apiToken: api_token }.merge(build_request(params)),
      headers: {
        'content-type'     => 'application/x-www-form-urlencoded',
        'accept'           => 'application/json',
        'content-encoding' => 'utf-8'
      }
    }
  end

  def build_request(params)
    options = []
    options << "PageNumber:#{params[:page] || 0}"
    options << "PageSize:#{params[:limit] || 1000}"
    options << "Include:[\"#{Array(params[:include]).join('","')}\"]" if params.key?(:include)
    options << "SearchString:\"#{params[:search_string]}\"" if params.key?(:search_string)
    if options.any?
      { request: "{#{options.join(',')}}" } if options.any?
    else
      {}
    end
  end
end
