module ExportsHelper
  def each_collection_item
    p = @search_params.dup
    (1..@total_pages).each do |page|
      p[:page] = page
      search = resource_class.do_search(p)
      search.results.each do |result|
        yield result
      end
      @_export.update_column(:progress, (page*100/@total_pages).round) unless @_export.nil?
    end
  end
end