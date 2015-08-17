require 'rails_helper'

RSpec.describe HoursField, :type => :model do
  it { is_expected.to belong_to(:venue) }
end
