# == Schema Information
#
# Table name: form_fields
#
#  id               :integer          not null, primary key
#  form_template_id :integer          not null
#  metric_id        :integer
#  position         :integer          default(0)
#  section_name     :string(255)
#  rows             :integer          default(1)
#  columns          :integer          default(1)
#  clear            :boolean          default(FALSE)
#  creator_id       :integer
#  updater_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class FormField < Legacy::Record
  belongs_to    :form_template
  belongs_to    :metric


  SUMMARY_FIELD = "MM / MBN Supervisor Comments"
  COMMENTS_FIELDS = ["Consumer / Trade Comments, Reactions, & Quotes", "Trade / Consumer Feedback", "BA Comments (include location if not specified above, branding, brief overview of event, areas of opportunity, etc.)", 'Bartenders Feedback/Quotes']
  CONTACTS_FIELDS = ["Field Ambassador 1", "Field Ambassador 2","Field Ambassador 3", 'Bar Manager on Duty', 'Account Manager on Duty']
  TEAM_FIELDS = ["MM/MBN Supervisor"]

  scope :custom, lambda{ not_global.joins(:metric).where('metrics.type not in (?) and metrics.name not in (?)',
    ['Metric::BarSpend', 'Metric::PromoHours'],
    [SUMMARY_FIELD] + COMMENTS_FIELDS + CONTACTS_FIELDS + TEAM_FIELDS
    )
  }
  scope :not_global, lambda{ joins(:metric).where('(metrics.program_id is not NULL OR metrics.brand_id is not NULL OR metrics.name not in (?))', ['Age', 'Gender', 'Demographic', '# Consumer Impressions', '# Consumers Sampled','# Consumer Interactions', '# Events']) }

  def has_metric?
    !metric.nil?
  end
end