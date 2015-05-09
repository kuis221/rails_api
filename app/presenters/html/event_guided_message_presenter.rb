module Html
  class EventGuidedMessagePresenter < BasePresenter
    def current_steps
      @current_steps ||= begin
        name, steps = phases[:phases].find { |name, _| name == phases[:current_phase] }
        steps.select { |s| !s[:complete] && self.respond_to?("#{name}_#{s[:id]}") } +
        [{id: 'last'}]
      end
    end

    def plan_contacts
      yes_or_skip 'Do you want to keep track of any contacts?', :contacts
    end

    def plan_tasks
      yes_or_skip 'Are there any tasks that need to be completed for your event?', :tasks
    end

    def plan_documents
      yes_or_skip 'Are there any supporting documents to add?', :documents
    end

    def plan_last
      info 'Done! You\'ve completed the planning phase of your event.', :last
    end

    def execute_per
      yes_or_skip 'Ready to fill out your Post Event Recap?', :per
    end

    def execute_activities
      yes_or_skip 'Do you have any activities to add?', :activities
    end

    def execute_attendance
      yes_or_skip 'Want to add attendees?', :attendance
    end

    def execute_photos
      yes_or_skip 'Let\'s take a look, have any event photos to upload?', :photos
    end

    def execute_comments
      yes_or_skip 'What were attendees saying? Do you have consumer comments to add?', :comments
    end

    def execute_expenses
      yes_or_skip 'Do you have any expenses to add?', :expenses
    end

    def execute_surveys
      yes_or_skip 'Do you have any surveys to add?', :surveys
    end

    def execute_last
      if @model.rejected?
        message_with_buttons 'Your post event report form has been rejected for the following reasons: <br />' +
                             @model.reject_reason +
                             '<p>Please make the necessary changes and resubmit when ready</p>', :last,
                             [submit_button]

      elsif can?(:submit) && @model.valid_results?
        message_with_buttons 'it looks like you\'ve collected all required post event info. '\
                             'Are you ready to submit your report for approval? ', :last,
                             [submit_button]
      else
        info 'Done! You\'ve completed the execute phase of your event.', :last
      end
    end

    def results_approve_per
      if can?(:approve)
        message_with_buttons 'Your post event report has been submitted for approval. '\
                            'Please review and either approve or reject.', :approve_per,
                            [approve_button, reject_button]
      else
        info 'Your post event report has been submitted for approval. Once your report has been reviewed you will be alerted in your notifications.', :approve_per
      end
    end

    def results_last
      if @model.approved?
        message_with_buttons 'Your post event report has been approved. Check out your post event results below for a recap of your event.', :last,
                            [unapprove_button]
      else
        if can?(:approve)
          message_with_buttons 'Your post event report has been submitted for approval. '\
                              'Please review and either approve or reject.', :last,
                              [approve_button, reject_button]
        else
          info 'Your post event report has been submitted for approval. Once your report has been reviewed you will be alerted in your notifications.', :last
        end
      end
    end

    def yes_or_skip(message, step)
      target = "#event-#{step}"
      next_target = next_target_after(step)
      [
        h.content_tag(:span, '', class: 'transitional-message'),
        message,
        h.link_to('Yes', target, class: 'step-yes-link smooth-scroll', data: { spytarget: target }),
        h.link_to('Skip', next_target, class: 'step-skip-link smooth-scroll', data: { spyignore: 'ignore' })
      ].join.html_safe
    end

    def info(message, step)
      [
        h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
        message
      ].join.html_safe
    end

    def message_with_buttons(message, step, buttons)
      ([
         h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
         message
       ] + buttons.compact).join.html_safe
    end

    def next_target_after(step)
      index = current_steps.index { |s| s[:id] == step }
      next_step = current_steps[index + 1] || nil
      next_step ? "#event-#{next_step[:id]}" : ''
    end

    def unapprove_button
      return unless can?(:unapprove)
      h.button_to 'Unapprove', h.unapprove_event_path(@model, return: h.return_path),
                 method: :put, class: 'btn btn-cancel'
    end

    def approve_button
      return unless can?(:unapprove)
      h.button_to 'Approve', h.approve_event_path(@model, return: h.return_path),
                 method: :put, class: 'btn btn-primary'
    end

    def reject_button
      return unless can?(:unapprove)
      h.button_to 'Reject', h.reject_event_path(@model, format: :js, return: h.return_path),
                 form: { id: 'reject-post-event' },
                 method: :put, class: 'btn btn-cancel', remote: true
    end

    def submit_button
      return unless can?(:submit)
      h.button_to 'Submit', h.submit_event_path(format: :js, return: h.return_path),
                  class: 'btn btn-cancel', method: :put,
                  remote: true, data: { disable_with: 'submitting'}
    end

  end
end
