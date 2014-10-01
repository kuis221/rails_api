module Legacy
  class Legacy::Record < ActiveRecord::Base
    self.abstract_class = true
    # if ENV['LEGACY_DB']
    #   establish_connection ENV['LEGACY_DB']
    # end
  end
end
