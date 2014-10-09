module PhotosHelper
  include ActionView::Helpers::NumberHelper

  def photo_permissions(photo)
    @_generic_photo_permissions ||= [
      (can?(:deactivate_photo, Event) ? 'deactivate_photo' : nil),
      (can?(:index_photo_results, AttachedAsset) ? 'index_photo_results' : nil),
      (can?(:remove, Tag) ? 'deactivate_tag' : nil),
      (can?(:create, Tag) ? 'create_tag' : nil),
      (can?(:index, Tag) ? 'view_tag' : nil),
      (can?(:activate, Tag) ? 'add_tag' : nil)
    ].compact
    @_generic_photo_permissions + [
      (can?(:rate, photo) ? 'rate' : nil),
      (can?(:view_rate, photo) ? 'view_rate' : nil)
    ].compact
  end

  protected

  def describe_filters
    first_part  = "#{describe_date_ranges}  #{describe_brands} #{describe_campaigns} #{describe_locations}".strip
    first_part = nil if first_part.empty?
    "#{view_context.pluralize(number_with_delimiter(collection_count), "#{describe_status} photo")} #{first_part}"
  end

  def describe_date_ranges
    description = ''
    start_date = params.key?(:start_date) &&  params[:start_date] != '' ? params[:start_date] : false
    end_date = params.key?(:end_date) &&  params[:end_date] != '' ? params[:end_date] : false
    start_date_d = end_date_d = nil
    start_date_d = Timeliness.parse(start_date).to_date if start_date
    end_date_d = Timeliness.parse(end_date).to_date if end_date
    unless start_date.nil? || end_date.nil?
      today = Date.today
      yesterday = Date.yesterday
      tomorrow = Date.tomorrow
      start_date_label = (start_date_d == today ?  'today' : (start_date_d == yesterday ? 'yesterday' : (start_date_d == tomorrow ? 'tomorrow' : Timeliness.parse(start_date).strftime('%B %d')))) if start_date
      end_date_label = (end_date_d == today ? 'today' : (end_date == yesterday.to_s(:slashes) ? 'yesterday' : (end_date == tomorrow.to_s(:slashes) ? 'tomorrow' : Timeliness.parse(end_date).strftime('%B %d')))) if end_date

      if start_date && end_date && (start_date != end_date)
        description = "from #{start_date_label} - #{end_date_label}"
      elsif start_date
        description = "from #{start_date_label}"
      end
    end

    description
  end

  def describe_brands
    brands = brand_params
    names = []
    if brands.size > 0
      names = Brand.select('name').where(id: brands).map(&:name)
      "for #{names.to_sentence(last_word_connector: ' and ')}"
    else
      ''
    end
  end

  def brand_params
    brands = params[:brand]
    brands = [brands] unless brands.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^brand,/
      brands.push params[:q].gsub('brand,', '')
    end
    brands.compact
  end

  def describe_campaigns
    campaigns = campaign_params
    if campaigns.size > 0
      names = current_company.campaigns.select('name').where(id: campaigns).map(&:name).to_sentence(last_word_connector: ' and ')
      "as part of #{names}"
    else
      ''
    end
  end

  def campaign_params
    campaigns = params[:campaign]
    campaigns = [campaigns] unless campaigns.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^campaign,/
      campaigns.push params[:q].gsub('campaign,', '')
    end
    campaigns.compact
  end

  def describe_locations
    places = location_params
    place_ids = places.select { |p| p =~  /^[0-9]+$/ }
    encoded_locations = places - place_ids
    names = []
    if place_ids.size > 0
      names = Place.select('name').where(id: place_ids).map(&:name)
    end

    if encoded_locations.size > 0
      names += encoded_locations.map { |l| (id, name) =  Base64.decode64(l).split('||'); name }
    end

    if names.size > 0
      "in #{names.to_sentence(last_word_connector: ' or ')}"
    else
      ''
    end
  end

  def location_params
    locations = params[:place]
    locations = [locations] unless locations.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^place,/
      locations.push params[:q].gsub('place,', '')
    end
    locations.compact
  end

  def describe_status
    status = params[:status]
    status = [status] unless status.is_a?(Array)
    unless status.empty? || status.nil?
      status.to_sentence(last_word_connector: ' and ')
    end
  end

  def company_tags(assigned_tags)
    result = []
    tags = Tag.where(company_id: current_company).order('name ASC')
    tags = tags - assigned_tags
    tags.each { |t| result << { 'id' => t.id, 'text' => t.name } }
    result
  end

  def to_select2_tag_format(obj)
    result = []
    obj.each { |o| result << { 'id' => o.id, 'text' => o.name } }
    result
  end
end
