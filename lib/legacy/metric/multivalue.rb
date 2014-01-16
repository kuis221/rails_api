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

# for storing a group of options, such as found in a pie chart
class Metric::Multivalue < Metric
  has_many :metric_options, :foreign_key => :metric_id, :dependent => :destroy,  :order => "id ASC"
  accepts_nested_attributes_for :metric_options, :allow_destroy => false, :reject_if => proc { |attributes| attributes['name'].blank? }

  def collection
    @collection ||= metric_options.not_deleted.map { |o| [o.name, o.id] }
  end
  def format_result(result)
    values = Metric.scrub_hash_keys(result.value)
    #metric_options.map { |o| o.qualified_name+': '+ values[o.id] +' %' }.join ", "
    rows=[]
    metric_options.map { |o| "<td>#{o.name}:</td><td>#{values[o.id]}%</td>"}.in_groups_of(3, '<td>&nbsp;</td>'){|slice| rows.push "<tr>#{slice.join('')}</tr>"}

    "<table style='width:100%'>#{rows.join('')}</table>".html_safe
  end
  def format_pdf(pdf, result)
    return if result.nil?

    values = Metric.scrub_hash_keys(result.value)
    x = 0
    y = 55
    metric_options.in_groups_of(3) do |slice|
      slice.each do|o|
        pdf.bounding_box([x, y], :width => 150, :height => 10) do
          pdf.text "#{o.name}: #{values[o.id]}%"  if o
        end
        x+=160
      end
      y-=15
      x=0
    end
  end
  def report_columns
    metric_options.map { |o| o.qualified_name+' %' }
  end
  def result_hash(result)
    v = cast_value(result.value)
    Hash[ v.keys.map { |f| [metric_options.find(f).qualified_name+' %', v[f]] } ]
  end

  def self.targetable?
    false
  end

  def field_type_symbol
    '&pi;'
  end

  def validate_result(result)
    values = Metric.scrub_hash_keys(result.value)
    metric_options.each do |o|
      v = values[o.id]
      if value_is_float?(v)
        result.errors.add(:values, "#{o.name} cannot be negative") if v.to_f<0
        result.errors.add(:values, "#{o.name} cannot be over 100%") if v.to_f>100
      else
        result.errors.add(:values, "#{o.name} must be a number")
      end
    end

    if result.errors.empty?
      values_sum = cast_value(result.value).values.sum
      result.errors.add(:values, "total: #{values_sum}%. Must be 100%.") unless values_sum == 0 or values_sum == 100
    end
  end
  def cast_value(value)
    v = Metric.scrub_hash_keys(value)
    metric_option_ids.inject({}) { |h, opt_id| h[opt_id] = v[opt_id].to_f; h}
  end
  def store_result(value, result)
    result.vector_value = cast_value(value)
  end
  def fetch_result(result)
    cast_value result.vector_value
  end
end
