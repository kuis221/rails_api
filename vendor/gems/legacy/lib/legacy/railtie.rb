module Legacy
  class Railtie < ::Rails::Railtie

    initializer "legacy_railtie.configure_rails_initialization" do
      Paperclip.interpolates :dashed_style do |_attachment, style|
        if style.to_sym == :original
          ''
        else
          "_#{style}"
        end
      end
    end

    rake_tasks do
      load 'legacy/tasks.rb'
    end
  end
end
