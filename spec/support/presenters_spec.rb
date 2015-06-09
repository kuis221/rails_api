module Brandscopic
  module SimpleDelegator
    module RSpec
      @@view_context = nil
      def self.enable(example)
        example.extend self

        controller = Class.new(ApplicationController).new
        controller.request = ActionController::TestRequest.new
        @@view_context = controller.view_context
        self
      end

      def present(obj, stubs={})
        @@view_context.present(obj)
        stubs.each do |k, v|
          allow(@@view_context).to receive(k).and_return(v)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.before :each, type: :presenter do
    Brandscopic::SimpleDelegator::RSpec.enable(self)
  end
end
