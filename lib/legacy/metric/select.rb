# == Schema Information
#
# Table name: metrics
#
#  id          :integer          not null, primary key
#  type        :string(32)
#  brand_id    :integer
#  program_id  :integer
#  name        :string(255)
#  style       :string(255)
#  optional_id :integer
#  active      :boolean          default(TRUE)
#  creator_id  :integer
#  updater_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

# for storing a pulldown menu choice
class Metric::Select < Metric
  has_many :metric_options, :foreign_key => :metric_id, :dependent => :destroy, :order => "id ASC"
  accepts_nested_attributes_for :metric_options, :allow_destroy => false, :reject_if => proc { |attributes| attributes['name'].blank? }

  validates_presence_of :style
  validates_inclusion_of :style, :in => %w( select radio )
  def style_options
    %w( select radio )
  end

  def collection
    @collection ||= metric_options.not_deleted.map { |o| [o.name, o.id] }
  end
  def form_options
    super.merge({:as => style || :select, :collection => collection, :include_blank => 'Select one'})
  end
  def format_result(result)
    metric_options.find(result.value).name
  end
  def format_pdf(pdf, result)
    if result && result.print_values?
      super
    else
      pdf.font_size(10) { pdf.indent(5) { pdf.text metric_options.map(&:name).join(' / ') } }
    end
  end
  def result_hash(result)
    {name => format_result(result)}
  end
  def self.targetable?
    false
  end
  def field_type_symbol
    'ABC'
  end
  def validate_result(result)
    result.errors.add(:value, 'Pick one') unless metric_options.exists?(cast_value(result.value))
  end
  def cast_value(value)
    value.to_i
  end
end
