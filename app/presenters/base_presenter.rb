class BasePresenter < SimpleDelegator
  STRFTIME_FORMAT = '%Y-%m-%d %H:%M:%S'.freeze
  EXPORT_FORMAT = '%F %R'.freeze

  attr_accessor :model, :view

  def initialize(model, view)
    @model, @view = model, view
    super(@model)
  end

  def h
    @view
  end

  def datetime(d)
    Timeliness.parse(d.strftime(STRFTIME_FORMAT), zone: 'UTC').strftime(EXPORT_FORMAT)
  end
end
