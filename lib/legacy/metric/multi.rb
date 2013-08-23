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
class Metric::Multi < Metric
  has_many :metric_options, :foreign_key => :metric_id, :dependent => :destroy, :order => "id ASC"
  accepts_nested_attributes_for :metric_options, :allow_destroy => false, :reject_if => proc { |attributes| attributes['name'].blank? }

  validates_presence_of :style
  validates_inclusion_of :style, :in => %w( select check_boxes )
  def style_options
    %w( select check_boxes )
  end

  def collection
    @collection ||= ActiveSupport::OrderedHash[metric_options.not_deleted.map{|o|[o.name, o.id]}]
  end
  def form_options
    super.merge({:as => style || :select, :collection => collection, :include_blank => false, :multiple => true, :wrapper_html => {:class => :multiple}})
  end
  def format_result(result)
    metric_options.find(result.value.reject(&:blank?).map(&:to_i)).map(&:name).join(', ') if result.value
  end
  def format_pdf(pdf, result)
    if result && result.print_values?
      super
    else
      pdf.font_size(10) { pdf.indent(4) { pdf.text metric_options.map(&:name).join(' / ') } }
    end
  end
  def result_hash(result)
    {name => format_result(result)}
  end
  def self.targetable?
    false
  end
  def field_type_symbol
    'XYZ'
  end
  def validate_result(result)
    result.errors.add(:values, 'Invalid data') unless cast_value(result.value).all? { |v| metric_options.exists?(v) }
  end
  def cast_value(value)
    (value || []).map(&:to_i).reject { |v| v<1 }
  end
  def store_result(value, result)
    result.vector_value = cast_value(value)
  end
  def fetch_result(result)
    cast_value result.vector_value
  end
end
