RSpec::Matchers.define :have_filter_section do |filter|
  match do |page|
    @errors = []

    found = false
    page.all('.form-facet-filters .accordion-group').each do |wrapper|
      title = wrapper.all('.filter-wrapper a', text: filter[:title])
      unless title.nil? || title.count == 0
        found = true
        if filter[:options].present?
          filter[:options].each do |option|
            if wrapper.all('ul>li', text:  option).count == 0
              @errors.push "Option \"#{option}\" not found in #{filter[:title]} fitler"
            end
          end
        end
      end
    end
    @errors.push "Filter #{filter[:title]} not found" unless found

    @errors.empty?
  end

  failure_message do |_actual|
    @errors.join("\n")
  end

  failure_message_when_negated do |_actual|
    @errors.join("\n")
  end

  description do
    "has filter section for #{filter[:title]}"
  end

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
