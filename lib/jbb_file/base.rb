module JbbFile
  class Base
    attr_accessor :ftp_username, :ftp_password, :ftp_server, :ftp_folder,
                  :mailer, :invalid_files

    def valid_format?(file)
      valid = false
      each_sheet(file) do |sheet|
        unless (self.class::VALID_COLUMNS - sheet.row(1)).empty?
          return false
        end
        valid = true
      end
      valid
    end

    def download_files(dir)
      files = find_files
      return file_not_fould unless files.any?
      Hash[files.map do |file_name|
        p "Downloading #{file_name}"
        file = get_file(dir, file_name)
        if valid_format?(file)
          [file_name, file]
        else
          @invalid_files.push temp_file_path(dir, file_name)
          nil
        end
      end.compact]
    end

    def archive_file(file)
      ftp_connecion.rename(file, "OLD/#{file}")
    end

    def get_file(dir, file)
      path = temp_file_path(dir, file)
      ftp_connecion.getbinaryfile file, path
      Roo::Excelx.new(path)
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
      return unless @ftp_connecion
      @ftp_connecion.close
      @ftp_connecion = nil
    end

    def invalid_format
      mailer.invalid_format(self.invalid_files).deliver
      false
    end

    def ftp_connecion
      @ftp_connecion ||= Net::FTP.new(ftp_server).tap do |ftp|
        ftp.passive = true
        ftp.login(ftp_username, ftp_password)
        ftp.chdir(ftp_folder) if ftp_folder
        ftp.binary = true
        ftp
      end
    end

    def find_files
      file = ftp_connecion.list('*xlsx').map do |l|
        l.split(/\s+/, 4)
      end.map{ |f| f[3] }
    end
  end
end
