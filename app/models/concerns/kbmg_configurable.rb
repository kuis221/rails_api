module KbmgConfigurable
  extend ActiveSupport::Concern

  included do
    store_accessor :settings, :kbmg_enabled
  end

  def kbmg_enabled
    (super == 'true' || false) # Force it return a boolean
  end
  alias_method :kbmg_enabled?, :kbmg_enabled
end
