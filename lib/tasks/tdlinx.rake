require 'csv'
require 'td_linx'
require 'tempfile'

namespace :tdlinx do
  namespace :ftp do
    desc 'Download and process file from FTP'
    task process: :environment do |_t, args|
      file = args.file
      TdLinx::Processor.download_and_process_file(file)
    end

    # Because heroku doesn't give us option to run the job montly, we run it
    # daily checking for the current day. Check the job scheduled at heroku
    # by runnning:
    #   heroku addons:open scheduler -a brandscopic
    desc 'Download and process file from FTP checking the current day'
    task process_scheduled: :environment do |_t, args|
      if ENV['TDLINX_DAY_PROCESS'].to_i == Time.current.utc.day
        file = args.file
        TdLinx::Processor.download_and_process_file(file)
      else
        p 'Not today'
      end
    end
  end
  namespace :http do
    desc 'Download and process file from an URL'
    task :process,  [:file] => :environment do |t, args|
      file = args.file
      if file.match(/\Ahttp(s)?:\/\//)
        t = Tempfile.new('tdlinx_remote', nil, encoding:  'ascii-8bit')
        t.write(open(file, 'rb').read)
        file = t.path
        t.close
      end
      TdLinx::Processor.download_and_process_file(file)
    end
  end

  namespace :stdin do
    desc 'Download and process file from an STDIN'
    task process: :environment do |t, _args|
      t = Tempfile.new('tdlinx_stdin')
      $stdin.each_line do |line|
        t.write(line)
      end
      file = t.path
      t.close
      TdLinx::Processor.download_and_process_file(file)
    end
  end
end
