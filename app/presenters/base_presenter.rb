class BasePresenter < SimpleDelegator
  attr_accessor :model, :view
  def initialize(model, view)
    @model, @view = model, view
    super(@model)
  end

  def h
    @view
  end
end
