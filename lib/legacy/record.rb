module Legacy
  class Legacy::Record < ActiveRecord::Base
    self.abstract_class = true
    establish_connection 'postgres://twukngcbmkawzd:uleuENdCwU5RDwv48NOm4btNlb@ec2-54-235-194-252.compute-1.amazonaws.com:5432/d9ncqhfqis29bj'

  end
end