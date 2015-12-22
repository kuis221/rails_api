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
      message_route =  'instructive_messages.execute.attendance.'
      if @model.invites.active.count > 0
        can?(:index_invites) ?
                              I18n.t("#{message_route}added_more", attendances_count: @model.invites.active.count) :
                              I18n.t("#{message_route}view")
      else
        can?(:index_invites) ? I18n.t("#{message_route}add") : I18n.t("#{message_route}empty")
      end
    end

    def execute_photos
      message_route =  'instructive_messages.execute.photo.'
      if can?(:create_photo)
        min = module_range_val('photos', 'range_min')
        max = module_range_val('photos', 'range_max')
        range_conditional_message message_route, min, max
      else
        @model.photos.active.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def execute_comments
      message_route =  'instructive_messages.execute.comment.'
      if can?(:create_comment)
        min = module_range_val('comments', 'range_min')
        max = module_range_val('comments', 'range_max')
        range_conditional_message message_route, min, max
      else
        @model.comments.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def execute_expenses
      message_route =  'instructive_messages.execute.expense.'
      if can?(:create_expense)
        min = module_range_val('expenses', 'range_min')
        max = module_range_val('expenses', 'range_max')
        range_conditional_message message_route, min, max
      else
        @model.event_expenses.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def range_conditional_message(scope, min, max)
      if !min.blank? && !max.blank? && min.to_i > 0 && max.to_i > 0
        I18n.t("#{scope}add_min_max", min: min, max: max)
      elsif !min.blank? && min.to_i > 0
        I18n.t("#{scope}add_min", count: min.to_i)
      elsif !max.blank? && max.to_i > 0
        I18n.t("#{scope}add_max", count: max.to_i)
      else
        I18n.t("#{scope}add")
      end
    end

    def locked_in_phase_plan_message
      actions = phases[:phases][:execute].map do |s|
        next if s.key?(:if) && !h.instance_exec(@model, &s[:if])
        send("locked_#{s[:id]}_message")
      end.compact
      h.t('instructive_messages.plan.still', date: start_at.strftime('%b %d'),
                                             actions: actions.to_sentence(last_word_connector: ' and '))
    end

    def locked_attendance_message
      if can?(:edit_data)
        h.t('incomplete_execute_steps.attendance.edit')
      else
        h.t('incomplete_execute_steps.attendance.read_only')
      end
    end

    def locked_per_message
      if can?(:edit_data)
        h.t('incomplete_execute_steps.per.edit')
      else
        h.t('incomplete_execute_steps.per.read_only')
      end
    end

    def locked_activities_message
      if h.can?(:create, Activity) || can?(:create_invite)
        h.t('incomplete_execute_steps.activities.edit')
      else
        h.t('incomplete_execute_steps.activities.read_only')
      end
    end

    def locked_photos_message
      if can?(:edit_data)
        h.t('incomplete_execute_steps.photos.edit')
      else
        h.t('incomplete_execute_steps.photos.read_only')
      end
    end

    def locked_expenses_message
      if can?(:create_expense)
        h.t('incomplete_execute_steps.expenses.edit')
      else
        h.t('incomplete_execute_steps.expenses.read_only')
      end
    end

    def locked_comments_message
      if can?(:create_comment)
        h.t('incomplete_execute_steps.comments.edit')
      else
        h.t('incomplete_execute_steps.comments.read_only')
      end
    end

    def execute_surveys
    end

    def module_range_val(module_name, range_name)
      return '' unless @model.campaign.range_module_settings?(module_name)
      @model.campaign.module_setting(module_name, range_name)
    end

    def initial_message
      if h.flash[:event_message_success].present?
        [h.flash[:event_message_success], 'green', false]
      elsif h.flash[:event_message_fail].present?
        [h.flash[:event_message_fail], 'red', false]
      elsif approved?
        [h.t('instructive_messages.results.approved'), 'green', true]
      elsif rejected?
        [h.t('instructive_messages.results.rejected_info', rejected_at: rejected_at, reject_reason: reject_reason).html_safe, 'red', true]
      end
    end

    def results_approve_per
      message, color, close = initial_message
      message = h.flash[:event_message] if h.flash[:event_message].present?
      message
    end

    def rejected_at
      date = @model.rejected_at || @model.updated_at
      h.time_ago_in_words(date)
    end
  end
end
