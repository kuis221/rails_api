require 'active_support/concern'

module SunspotIndexing
  extend ActiveSupport::Concern

  def with_immediate_indexing
    old_session = Sunspot.session
    if Sunspot.session.is_a?(Sunspot::Queue::SessionProxy)
      Sunspot.session = Sunspot.session.session
    end
    yield
    Sunspot.commit
  ensure
    Sunspot.session = old_session
  end

  # Makes sure that the resource is immediate indexed.
  # this can be used in any controller with:
  #  after_action :force_resource_reindex, only: [:create]
  def force_resource_reindex
    with_immediate_indexing do
      Sunspot.index resource if resource.persisted? && resource.errors.empty?
    end
  end
end
