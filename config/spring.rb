module Spring
  module Commands
    class RSpec
      def env(*)
        'test'
      end

      def exec_name
        'rspec'
      end
    end

    Spring.register_command 'rspec', RSpec.new
    Spring::Commands::Rake.environment_matchers[/^spec($|:)/] = 'test'
  end
end

Spring.after_fork do
  Sunspot.session = Sunspot::Rails.build_session if defined?(Sunspot::Queue) && Sunspot.session.is_a?(Sunspot::Queue::SessionProxy)
end
