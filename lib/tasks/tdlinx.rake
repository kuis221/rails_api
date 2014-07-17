require 'csv'
require 'td_linx'

namespace :tdlinx do
  namespace :ftp do
    desc "Download and process file from FTP"
    task :process => :environment do
      TdLinxSynch::Processor.download_and_process_file
    end
  end
end