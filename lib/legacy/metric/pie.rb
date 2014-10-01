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

include OpenURI
class Metric::Pie < Metric
  has_many :metric_options, foreign_key: :metric_id, dependent: :destroy
  accepts_nested_attributes_for :metric_options, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? }

  def collection
    @collection ||= metric_options.map { |o| [o.name, o.id] }
  end

  def format_result(result)
    ActionController::Base.helpers.tag(:img, src: chart_url(result.value)) if result.value
  end

  def format_pdf(pdf, result)
    w = pdf.bounds.width.to_i
    h = pdf.cursor.to_i
    if result && result.print_values?
      pdf.image open(chart_url(result.value, "#{w}x#{h}")), width: w, height: h
    else
      table_data = metric_options.map { |o| [o.name, '%'] } << %w(TOTAL 100%)
      pdf.table table_data, width: w, column_widths: { 1 => w / 4 }, cell_style: { height: h / (metric_options.count + 1) } do
        cells.overflow = :shrink_to_fit
        cells.valign = :center
        cells.borders = []
        columns(1).align = :right
        row(-1).align = :right
        row(-1).column(-1).borders = [:top]
      end
    end
  rescue
    pdf.text $ERROR_INFO.to_s
  end

  def report_columns
    metric_options.map { |o| o.qualified_name + ' %' }
  end

  def result_hash(result)
    v = cast_value(result.value)
    Hash[v.keys.map { |f| [metric_options.find(f).qualified_name + ' %', v[f]] }]
  end

  def self.targetable?
    false
  end

  def field_type_symbol
    '&pi;'
  end

  def chart_url(values, size = '480x100') # basic_chart[:chs] = '240x150' if @columnar_view
    colors = %w(FF9900 324C8E ff0000 FF69B4 1E90FF 9ACD32 DAA520 40E0D0)
    basic_chart = { chs: size, cht: 'p3', chco: colors.join('|') }
    chart_params = basic_chart.merge(chd: 't:' + values.values.join(','), chdl: values.keys.map { |f| "#{metric_options.find(f).name} (#{values[f]})" }.join('|')) # , :chtt => name)

    "http://chart.apis.google.com/chart?#{chart_params.to_query}"
  end

  def validate_result(result)
    values = Metric.scrub_hash_keys(result.value)
    metric_options.each do |o|
      v = values[o.id]
      if value_is_float?(v)
        result.errors.add(:values, "#{o.name} cannot be negative") if v.to_f < 0
        result.errors.add(:values, "#{o.name} cannot be over 100%") if v.to_f > 100
      else
        result.errors.add(:values, "#{o.name} must be a number")
      end
    end

    if result.errors.empty?
      values_sum = cast_value(result.value).values.sum
      result.errors.add(:values, "total: #{values_sum}%. Must be 100%.") unless values_sum == 0 || values_sum == 100
    end
  end

  def cast_value(value)
    v = Metric.scrub_hash_keys(value)
    metric_option_ids.reduce({}) { |h, opt_id| h[opt_id] = v[opt_id].to_f; h }
  end

  def store_result(value, result)
    result.vector_value = cast_value(value)
  end

  def fetch_result(result)
    cast_value result.vector_value
  end
end
