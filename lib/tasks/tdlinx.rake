require 'csv'
require 'td_linx'
require 'tempfile'

namespace :tdlinx do
  namespace :ftp do
    desc "Download and process file from FTP"
    task :process => :environment do |t, args|
      p "Called tdlinx:ftp:process"
      file = args.file
      TdLinxSynch::Processor.download_and_process_file(file)
    end
  end
  namespace :http do
    desc "Download and process file from an URL"
    task :process,  [:file] => :environment do |t, args|
      file = args.file
      p "Called tdlinx:http:process with #{file}"
      if file.match(/\Ahttp(s)?:\/\//)
        p "Downloading file #{file}"
        t = Tempfile.new("tdlinx_remote", nil, encoding:  'ascii-8bit')
        t.write(open(file, 'rb').read)
        file = t.path
        t.close
      end
      TdLinxSynch::Processor.download_and_process_file(file)
    end
  end

  namespace :stdin do
    desc "Download and process file from an STDIN"
    task :process => :environment do |t, args|
      p "Called tdlinx:stdin:process"
      t = Tempfile.new("tdlinx_stdin")
      $stdin.each_line do |line|
        t.write(line)
      end
      file = t.path
      t.close
      TdLinxSynch::Processor.download_and_process_file(file)
    end
  end
end