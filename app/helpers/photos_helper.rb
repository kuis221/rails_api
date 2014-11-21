module PhotosHelper
  include ActionView::Helpers::NumberHelper

  def photo_permissions(photo)
    @_generic_photo_permissions ||= [
      (can?(:deactivate_photo, Event) ? 'deactivate_photo' : nil),
      (can?(:download, AttachedAsset) ? 'index_photo_results' : nil),
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

  def describe_photos_date_ranges
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
