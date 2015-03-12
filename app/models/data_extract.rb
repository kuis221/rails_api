class DataExtract < ActiveRecord::Base
  belongs_to :company
  track_who_does_it

  serialize :columns
  serialize :filters

  cattr_accessor :exportable_columns

  def rows(page = 1)
    model.do_search((filters || {}).merge(company_id: company.id, page: page)).results.map do |e|
      (columns || self.class.exportable_columns).map { |c| e.send(c) }
    end
  end

  def model
    @model ||= "::#{self.class.name.split('::')[1]}".constantize
  end
end
