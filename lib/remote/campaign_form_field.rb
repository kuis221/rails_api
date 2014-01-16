class Remote::CampaignFormField < Remote::Record
  belongs_to :kpi, class_name: 'Remote::Kpi'
end