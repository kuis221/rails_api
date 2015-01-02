class KBMG
  include HTTParty

  base_uri 'https://reachv4-pnr.kbmg.com'

  def initialize
    @default_params = { apiToken: '715c281a-05c2-49d4-be26-ddecc5a9edcd' }
  end

  def events(params=nil)
    response = self.class.get("/Events/EventsGet", query_options)
    response['Data']['Events'] if response && response['Success'] == true
  end

  private

  def query_options(params={})
    { query: @default_params.merge(params),
      headers: { 'accept' => 'application/json' } }
  end
end