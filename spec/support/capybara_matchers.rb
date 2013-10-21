RSpec::Matchers.define :have_filter_section do |filter|
  match do |page|
    @errors = []

    found = false
    page.all('.form-facet-filters .filter-wrapper').each do |wrapper|
      title = wrapper.all('h3', :text => filter[:title])
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


  failure_message_for_should do |actual|
    message = @errors.join("\n")
    message
  end

  failure_message_for_should_not do |actual|
    message = @errors.join("\n")
    message
  end

  description do
    message = "has filter section for #{filter[:title]}"
  end

end