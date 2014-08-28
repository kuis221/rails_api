require 'csv'
require 'td_linx'

namespace :tdlinx do
  namespace :ftp do
    desc "Download and process file from FTP"
    task :process,  [:file] => :environment do |t, args|
      file = args.file
      unless file || $stdin.tty?
        require 'tempfile'
        t = Tempfile.new("tdlinx_stdin")
        $stdin.each_line do |line|
          t.write(line)
        end
        file = t.path
        t.close
      end
      TdLinxSynch::Processor.download_and_process_file(file)
    end
  end
end