module Html
  class EventGuidedMessagePresenter < BasePresenter

    def plan_info
    end

    def plan_contacts
      message_route =  'instructive_messages.plan.contact.'
      if @model.contacts.count > 0
        can?(:create_contact) ?
          I18n.t("#{message_route}added_more", contacts_count: @model.contacts.count) :
          I18n.t("#{message_route}details")
      else
        can?(:create_contact) ? I18n.t("#{message_route}add") : I18n.t("#{message_route}empty")
      end
    end

    def plan_tasks
      message_route =  'instructive_messages.plan.task.'
      if @model.tasks.count > 0
        user_tasks = @model.tasks.active.assigned_to(h.current_company_user).count
        if user_tasks > 0
          if @model.tasks.active.count > 0
            I18n.t("#{message_route}assigned_user_team", tasks_count: user_tasks)
          else
            I18n.t("#{message_route}assigned_user", tasks_count: user_tasks)
          end
        else
          I18n.t("#{message_route}assigned_team", tasks_count: @model.tasks.active.count)
        end
      else
        can?(:tasks) ? I18n.t("#{message_route}add") : I18n.t("#{message_route}empty")
      end
    end

    def plan_documents
      message_route =  'instructive_messages.plan.document.'
      if @model.documents.count > 0
        can?(:create_document) ? I18n.t("#{message_route}manage") : I18n.t("#{message_route}view")
      else
        can?(:create_document) ? I18n.t("#{message_route}add") : I18n.t("#{message_route}empty")
      end
    end

    def execute_per
      message_route =  'instructive_messages.execute.per.'
      if event_data?
        can?(:view_data) ? I18n.t("#{message_route}saved") : I18n.t("#{message_route}view")
      else
        can?(:edit_data) ? I18n.t("#{message_route}add") : I18n.t("#{message_route}pending")
      end
    end

    def execute_activities
      message_route =  'instructive_messages.execute.activity.'
      if @model.activities.active.count > 0
        h.can?(:create, Activity) || can?(:create_invite) ?
                                                          I18n.t("#{message_route}added_more", activities_count: @model.activities.active.count) :
                                                          I18n.t("#{message_route}view")
      else
        h.can?(:create, Activity) || can?(:create_invite) ? I18n.t("#{message_route}add") : I18n.t("#{message_route}empty")
      end
    end

    def execute_attendance
    end

    def execute_photos
      message_route =  'instructive_messages.execute.photo.'
      if can?(:create_photo)
        min = module_range_val('photos', 'range_min')
        max = module_range_val('photos', 'range_max')

        if !min.empty? && !max.empty?
          I18n.t("#{message_route}add_min_max", photos_min: min, photos_max: max)
        elsif min.empty? && @model.photos.active.count < max.to_i
          I18n.t("#{message_route}add_max", photos_max: max)
        elsif max.empty? && @model.photos.active.count < min.to_i
          I18n.t("#{message_route}add_min", photos_min: min)
        else
          I18n.t("#{message_route}add")
        end
      else
        @model.photos.active.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def execute_comments
      message_route =  'instructive_messages.execute.comment.'
      if can?(:create_photo)
        min = module_range_val('comments', 'range_min')
        max = module_range_val('comments', 'range_max')
        if !min.empty? && !max.empty?
          I18n.t("#{message_route}add_min_max", comments_min: min, comments_max: max)
        elsif min.empty? && @model.comments.count < max.to_i
          I18n.t("#{message_route}add_max", comments_max: max)
        elsif max.empty? && @model.comments.count < min.to_i
          I18n.t("#{message_route}add_min", comments_min: min)
        else
          I18n.t("#{message_route}add")
        end
      else
        @model.comments.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def execute_expenses
    end

    def execute_surveys
    end

    def module_range_val(module_name, range_name)
      return '' unless @model.campaign.range_module_settings?(module_name)
      @model.campaign.module_setting(module_name, range_name)
    end

    #OLD DEF'S

    def current_steps
      @current_steps ||= begin
        if @model.rejected?
          [{ id: 'rejected' }]
        else
          name, steps = phases[:phases].find { |name, _| name == phases[:current_phase] }
          steps.select { |s| !s[:complete] && self.respond_to?("#{name}_#{s[:id]}") } +
          [{ id: :last }]
        end
      end
    end

    def incomplete_steps
      @incomplete_steps ||= begin
        name, steps = phases[:phases].find { |name, _| name == phases[:current_phase] }
        steps.select { |s| !s[:complete] && s[:required] }
      end
    end

    def execute_last
      if can?(:submit) && @model.valid_results?
        message_with_buttons 'It looks like you\'ve collected all required post event info. '\
                             'Are you ready to submit your report for approval? ', :last,
                             [submit_button]
      else
        if incomplete_steps.empty?
          info 'Done! You\'ve completed the execute phase of your event.', :last
        else
          info "You must #{incomplete_messages} before the execute phase is complete.", :last
        end
      end
    end

    def execute_rejected
      message_with_buttons "Your post event report form was rejected #{rejected_at} for the following reasons: <i>" +
                           (@model.reject_reason.present? ? @model.reject_reason : '') +
                           '</i>. Please make the necessary changes and resubmit when ready ', :last,
                           [submit_button]
    end

    def results_approve_per
      return complete_message_step(:approve_per) unless is_current_phase
      if can?(:approve)
        rejection_message = if @model.reject_reason.to_s.present?
          "It was previously rejected #{rejected_at} for the following reason: <i>#{@model.reject_reason}.</i> "
        end
        message_with_buttons "Your post event report has been submitted for approval #{submitted_at}. #{rejection_message}" +
                            'Please review and either approve or reject.', :approve_per,
                            [approve_button, reject_button]
      else
        info "Your post event report has been submitted for approval #{submitted_at}. Once your report has been reviewed you will be alerted in your notifications.", :approve_per
      end
    end

    def results_last
      return '' unless @model.approved?
      return complete_message_step(:last) unless is_current_phase
      message_with_buttons 'Your post event report has been approved. Check out your post event results below for a recap of your event.', :last,
                           [unapprove_button]
    end

    def module_range_message(module_name)
      return unless @model.campaign.range_module_settings?(module_name)
      min = @model.campaign.module_setting(module_name, 'range_min')
      max = @model.campaign.module_setting(module_name, 'range_max')
      if min.present? && max.present?
        I18n.translate("campaign_module_ranges.#{module_name}.min_max", range_min: min, range_max: max)
      elsif min.present?
        I18n.translate("campaign_module_ranges.#{module_name}.min", range_min: min)
      elsif max.present?
        I18n.translate("campaign_module_ranges.#{module_name}.max", range_max: max)
      else
        ''
      end.html_safe
    end

    def incomplete_messages
      incomplete_steps.map do |incomplete|
        I18n.translate("incomplete_execute_steps.#{incomplete[:id]}")
      end.to_sentence(last_word_connector: ' and ')
    end

    def yes_or_skip_or_back(message, step)
      return complete_message_step(step) unless is_current_phase
      target = "#event-#{step}"
      next_target = next_target_after(step)
      prev_target = prev_target_before(step)
      first_step = current_steps.first[:id] == step
      [
        h.content_tag(:span, '', class: 'transitional-message'),
        message,
        h.link_to(first_step ? '(Yes)' : '', step_link(target), class: 'step-yes-link smooth-scroll', data: { spytarget: target }),
        prev_target.present? ? h.link_to('(Back)', prev_target, class: 'step-back-link smooth-scroll', data: { spyignore: 'ignore' }) : '',
        h.link_to('(Skip)', next_target, class: 'step-skip-link smooth-scroll', data: { spyignore: 'ignore' })
        
      ].join.html_safe
    end

    def info(message, step)
      return complete_message_step(step) unless is_current_phase
      prev_target = prev_target_before(step)
      [
        h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
        message,
        prev_target.present? ? h.link_to('(Back)', prev_target, class: 'step-back-link smooth-scroll', data: { spyignore: 'ignore' }) : ''
      ].join.html_safe
    end

    def message_with_buttons(message, step, buttons)
      ([
         h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
         message
       ] + [h.content_tag(:div, buttons.compact.join.html_safe, class: 'step-buttons')]).join.html_safe
    end

    def complete_message_step(step)
      message = h.present(@model).current_phase == :plan ? "You've completed the planning phase of your event." : "You've completed the execute phase of your event."
      [
        h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
        message,
      ].join.html_safe
    end
      
    def next_target_after(step)
     # index = current_steps.index { |s| s[:id] == step }
      #next_step = current_steps[index + 1] || nil
      #next_step ? "#event-#{next_step[:id]}" : ''
    end

    def prev_target_before(step)
      #index = current_steps.index { |s| s[:id] == step }
      #prev_step = index > 0 ? current_steps[index - 1] : nil
      #prev_step ? "#event-#{prev_step[:id]}" : ''
    end

    def unapprove_button
      return unless can?(:unapprove) && is_current_phase
      h.button_to 'Unapprove', h.unapprove_event_path(@model, return: h.return_path),
                  method: :put, class: 'btn btn-cancel'
    end

    def approve_button
      return unless can?(:approve) && is_current_phase
      h.button_to 'Approve', h.approve_event_path(@model, return: h.return_path),
                  method: :put, class: 'btn btn-primary'
    end

    def reject_button
      return unless can?(:reject) && is_current_phase
      h.button_to 'Reject', h.reject_event_path(@model, format: :js, return: h.return_path),
                  form: { id: 'reject-post-event' },
                  method: :put, class: 'btn btn-cancel', remote: true
    end

    def submit_button
      return unless can?(:submit) && is_current_phase
      h.button_to 'Submit', h.submit_event_path(@model, format: :js, return: h.return_path),
                  class: 'btn btn-cancel submit-event-data-link', method: :put,
                  remote: true, data: { disable_with: 'submitting' }
    end

    def rejected_at
      date = @model.rejected_at || @model.updated_at
      timeago_tag(date)
    end

    def submitted_at
      date = @model.submitted_at || @model.updated_at
      timeago_tag(date)
    end

    def step_link(target)
      if h.present(@model).current_phase != phases[:current_phase]
        h.phase_event_path(@model, phase: phases[:current_phase]) + target
      else
        target
      end
    end

    def is_current_phase
      h.present(@model).current_phase == phases[:current_phase]
    end
  end
end
