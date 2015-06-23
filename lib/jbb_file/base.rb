module JbbFile
  class Base
    COMPANY_ID = 2

    attr_accessor :ftp_username, :ftp_password, :ftp_server, :ftp_folder,
                  :mailer, :invalid_files

    def valid_format?(file)
      valid = false
      each_sheet(file) do |sheet|
        unless (self.class::VALID_COLUMNS - sheet.row(1)).empty?
          Rails.logger.info "Invalid columns: #{self.class::VALID_COLUMNS - sheet.row(1)}"
          return false
        end
        valid = true
      end
      valid
    end

    def download_files(dir)
      puts "Downloading files"
      files = find_files
      unless files.any?
        puts "No files found #{files}"
        file_not_fould
        return files
      end
      files.map do |file_name|
        file = get_file(dir, file_name)
        if valid_format?(file[:excel])
          file
        else
          @invalid_files.push temp_file_path(dir, file_name)
          nil
        end
      end.compact
    ensure
      p 'closing connection'
      close_connection
    end

    def archive_file(file)
      begin
        ftp_connection.mkdir('OLD') unless ftp_connection.list("*").any? { |dir| dir.match(/\sOLD$/) }
      rescue Net::FTPPermError
        p 'Archive directory already exists'
      end
      ftp_connection.rename(file, "OLD/#{file}")
    end

    def get_file(dir, file)
      path = temp_file_path(dir, file)
      ftp_connection.getbinaryfile file, path
      { path: path, file_name: file, excel: Roo::Excelx.new(path) }
    end

    def temp_file_path(dir, name)
      "#{dir}/#{name}"
    end

    def each_sheet(file, &block)
      file.instance_variable_get(:@workbook_doc).xpath("//xmlns:sheet").each do |s|
        next if s.attributes['state'].to_s == 'hidden' # Ignore hidden sheets
        file.default_sheet = s['name']
        yield file
      end
    end

    def file_not_fould
      mailer.file_missing.deliver
      false
    end

    def close_connection
      return unless @ftp_connection
      @ftp_connection.close
      @ftp_connection = nil
    end

    def invalid_format
      mailer.invalid_format(self.invalid_files, self::class::VALID_COLUMNS).deliver
      false
    end

    def ftp_connection
      @ftp_connection = nil if @ftp_connection && @ftp_connection.closed?
      @ftp_connection ||= Net::FTP.new(ftp_server).tap do |ftp|
        ftp.passive = true
        ftp.login(ftp_username, ftp_password)
        puts "Changing directory to #{self.ftp_folder}" if self.ftp_folder
        Rails.logger.info "Changing directory to #{self.ftp_folder}" if self.ftp_folder
        ftp.chdir(self.ftp_folder) if self.ftp_folder
        ftp.binary = true
        ftp
      end
    rescue Errno::ECONNRESET
      @ftp_connection = nil
      sleep 1
      retry
    end

    def find_files
      raise 'testing'
      puts "Getting list of file from #{ftp_connection.pwd}"
      Rails.logger.info "Getting list of file from #{ftp_connection.pwd}"
      ftp_connection.nlst('*xlsx')
    rescue => e
      Rails.logger.info e.message
      Rails.logger.info "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      []
    end

    def company
      @company ||= Company.find(COMPANY_ID)
    end
  end
end
