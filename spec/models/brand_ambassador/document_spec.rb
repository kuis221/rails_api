require 'rails_helper'

RSpec.describe BrandAmbassadors::Document, :type => :model do
  it { is_expected.to belong_to(:attachable) }
  it { is_expected.to belong_to(:folder) }

  it { is_expected.to validate_presence_of(:file_file_name) }
  it { is_expected.to validate_presence_of(:attachable) }
  it { is_expected.to validate_presence_of(:direct_upload_url) }

  it { is_expected.to ensure_length_of(:file_file_name).is_at_most(255) }
end
