module Remote
  class Kpi < Remote::Record
    belongs_to :campaign, class_name: 'Remote::Campaign'
  end
end
