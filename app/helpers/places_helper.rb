module PlacesHelper
  def place_website(url)
    link_to url.gsub(/https?:\/\//,'').gsub(/\/$/,''), url
  end
end