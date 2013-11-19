require 'spec_helper'

describe Goal do

  it { should validate_presence_of(:goalable_id) }
  it { should validate_presence_of(:goalable_type) }

  it { should validate_numericality_of(:goalable_id) }
  it { should validate_numericality_of(:kpis_segment_id) }
  it { should validate_numericality_of(:value) }

  it { should belong_to(:goalable) }
  it { should belong_to(:parent) }
  it { should belong_to(:kpi) }
  it { should belong_to(:kpis_segment) }
end
