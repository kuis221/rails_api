module Remote
  class Remote::Record < ActiveRecord::Base
    self.abstract_class = true
    if ENV['REMOTE_DB']
      establish_connection ENV['REMOTE_DB']
    end
  end
end
