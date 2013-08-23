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

# For storing boolean flags.
class Metric::Boolean < Metric
  def form_options
    super.merge({:as => :radio, :collection => {:yes => 1, :no => 0}})
  end
  def format_result(result)
    cast_value(result.scalar_value)==1 ? 'Yes' : 'No'
  end
  def format_pdf(pdf, result)
    if result && result.print_values?
      super
    else
      pdf.font_size(10) { pdf.text "YES / NO", :align => :left, :valign => :center }
    end
  end
  def self.targetable?
    false
  end
  def field_type_symbol
    'T/F'
  end
  def cast_value(value)
    value.to_i
  end
end
