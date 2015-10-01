module Capybara
  module RSpecMatchers
    class HaveFilterSection < Matcher
      attr_reader :failure_message, :failure_message_when_negated

      def initialize(*args)
        @args = args.count > 1 ? args.last : {}
        @title = args[0].is_a?(Hash) ? args[0][:title] : args[0]
      end

      def matches?(actual)
        evaluate_condition(actual, true)
      rescue Capybara::ExpectationNotMet => e
        @failure_message = e.message
        return false
      end

      def does_not_match?(actual)
        evaluate_condition(actual, false)
      rescue Capybara::ExpectationNotMet => e
        @failure_message_when_negated = e.message
        return false
      end

      def evaluate_condition(page, expected)
        found = nil
        page.document.synchronize do
          errors = []
          found = false

          page.all('.form-facet-filters .accordion-group').each do |wrapper|
            title = wrapper.all('.filter-wrapper a', text: @title)
            unless title.nil? || title.count == 0
              found = true
              if @args[:options].present?
                title.first.trigger('click') if wrapper.all('.accordion-body.collapse').count > 0
                @args[:options].each do |option|
                  if wrapper.all('ul>li', text:  option).count == 0
                    errors.push "Option \"#{option}\" not found in #{@title} fitler: #{wrapper.text}"
                  end
                end
                options_found = wrapper.all('ul>li')
                if options_found.count != @args[:options].count
                  errors.push "Expected filter to have #{@args[:options].count} options, but it had #{options_found.count}"
                end
              end
            end
          end
          errors.push "expected #{page.inspect} to have filter section #{@title}" unless found

          if expected && (!found || errors.any?)
            raise Capybara::ExpectationNotMet, errors.join
          elsif !expected && found
            raise Capybara::ExpectationNotMet, "expected #{page.inspect} to not have filter section #{@args[:title]}"
          end
        end
        true
      end
    end

    class HaveFilterTag < Matcher
      attr_reader :failure_message, :failure_message_when_negated

      def initialize(*args)
        @args = args.count > 1 ? args.last : {}
        @title = args[0]
      end

      def matches?(actual)
        evaluate_condition(actual, true)
      rescue Capybara::ExpectationNotMet => e
        @failure_message = e.message
        return false
      end

      def does_not_match?(actual)
        evaluate_condition(actual, false)
      rescue Capybara::ExpectationNotMet => e
        @failure_message_when_negated = e.message
        return false
      end

      def evaluate_condition(page, expected)
        found = nil
        (page.respond_to?(:document) ? page.document : page).synchronize do
          found = page.all('.filter-item', text: @title).count > 0

          if expected && !found
            raise Capybara::ExpectationNotMet, "expected #{page.inspect} to have filter tag #{@title}"
          elsif !expected && found
            raise Capybara::ExpectationNotMet, "expected #{page.inspect} to not have filter tag  #{@title}"
          end
        end
        true
      end
    end
  end
end

def have_filter_section(*args)
  Capybara::RSpecMatchers::HaveFilterSection.new(*args)
end

def have_filter_tag(*args)
  Capybara::RSpecMatchers::HaveFilterTag.new(*args)
end

RSpec::Matchers.define :have_file_in_queue do |file_name|
  match do |_actual|
    @queued = page.all('.progress .upload-file-name').map(&:text)

    @queued.include? file_name
  end

  failure_message do |_actual|
    "expected queue to include '#{file_name}' but have [#{@queued.join(',')}]"
  end

  failure_message_when_negated do |_actual|
    "expected queue to NOT include '#{file_name}' but it did"
  end

  description do
    "has #{file_name} queued"
  end
end

RSpec::Matchers.define :have_photo_thumbnail do |photo|
  @errors = []
  found = false
  match do |_actual|
    src = photo.file.url(:small).gsub(/\?.*/, '')
    page.all('.photo-item').each do |thumbnail|
      img = thumbnail.find(:xpath, '//a/img')
      if img['src'] =~ /^#{src}$/
        found = true
      end
    end

    @errors.push "Image with src=\"#{src}\" not found in list" unless found

    @errors.empty?
  end

  failure_message do |_actual|
    "expected list have thumbnail for '#{photo.file_file_name}': #{@error.join('\n')}"
  end

  failure_message_when_negated do |_actual|
    "expected list to not have thumbnail for '#{photo.file_file_name}'"
  end

  description do
    "has thumbnail for '#{photo.file_file_name}'"
  end
end

RSpec::Matchers.define :have_form_field do |name, filter = {}|
  match do |page|
    @errors = []

    found = false
    # Gives time to render the field once dropped
    if have_content(name).matches?(actual)
      page.all('.field').each do |wrapper|
        label = wrapper.all('label.control-label', text: name)
        unless label.nil? || label.count == 0
          found = true
          if filter[:with_options].present?
            filter[:with_options].each do |option|
              elements = case wrapper['data-type']
              when 'Radio'
                wrapper.all(:field, option, type: 'radio')
              when 'Checkbox'
                wrapper.all(:field, option, type: 'checkbox')
              when 'Summation', 'Percentage'
                wrapper.all(:field, option)
              when 'LikertScale'
                wrapper.all('th', option)
              else
                # False because chosen hides the select and display a list instead
                wrapper.all('option', option, visible: false)
              end
              if elements.count == 0
                @errors.push "Cannot find \"#{option}\" for #{name}"
              end
            end
          end
        end
      end
    end
    @errors.push "Form Field #{name} not found" unless found

    @errors.empty?
  end

  failure_message do |_actual|
    @errors.join("\n")
  end

  failure_message_when_negated do |_actual|
    @errors.join("\n")
  end

  description do
    "has form field #{filter[:name]}"
  end

end

RSpec::Matchers.define :have_notification do |text, filter = {}|
  match do |page|
    @errors = []

    filter[:count] ||= 1

    if page.all('header li#notifications.open').count == 0
      page.find('header li#notifications a.dropdown-toggle').click
    end

    notifications  = page.all('#notifications .notifications-container li', text: text)

    if notifications.count != filter[:count]
      @errors.push "#{filter[:count]} #{filter[:count] == 1 ? 'notification' : 'notifications'} with text \"#{text}\" but have #{notifications.count}"
    end

    page.find('header li#notifications a.dropdown-toggle').trigger('click') # Close it

    @errors.empty?
  end

  failure_message do |_actual|
    'Expected to have ' + @errors.join("\n")
  end

  failure_message_when_negated do |_actual|
    "Expected to not have #{filter[:count] == 1 ? 'a notification' :  filter[:count].to_s + ' notifications'} with text \"#{text}\", but it did"
  end

  description do
    "has notification #{text}"
  end

end
