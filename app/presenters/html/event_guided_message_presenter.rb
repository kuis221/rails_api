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

        if !min.present? && !max.present?
          I18n.t("#{message_route}add_min_max", photos_min: min, photos_max: max)
        elsif min.present? && @model.photos.active.count < max.to_i
          I18n.t("#{message_route}add_max", photos_max: max)
        elsif max.present? && @model.photos.active.count < min.to_i
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
      if can?(:create_comment)
        min = module_range_val('comments', 'range_min')
        max = module_range_val('comments', 'range_max')
        if !min.present? && !max.present?
          I18n.t("#{message_route}add_min_max", comments_min: min, comments_max: max)
        elsif min.present?
          I18n.t("#{message_route}add_max", comments_max: max)
        elsif max.present?
          I18n.t("#{message_route}add_min", comments_min: min)
        else
          I18n.t("#{message_route}add")
        end
      else
        @model.comments.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def execute_expenses
      message_route =  'instructive_messages.execute.expense.'
      if can?(:create_expense)
        min = module_range_val('expenses', 'range_min')
        max = module_range_val('expenses', 'range_max')

        if !min.present? && !max.present? && @model.event_expenses.count < max.to_i
          I18n.t("#{message_route}add_min_max", expenses_min: min, expenses_max: max)
        elsif min.present? && @model.event_expenses.count < min.to_i
          I18n.t("#{message_route}add_min", expenses_min: min)
        elsif max.present? && @model.event_expenses.count < max.to_i
          I18n.t("#{message_route}add_max", expenses_max: max)
        else
          I18n.t("#{message_route}add")
        end
      else
        @model.event_expenses.count > 0 ? I18n.t("#{message_route}view") : I18n.t("#{message_route}empty")
      end
    end

    def execute_surveys
    end

    def module_range_val(module_name, range_name)
      return '' unless @model.campaign.range_module_settings?(module_name)
      @model.campaign.module_setting(module_name, range_name)
    end

    def initial_message
      if approved?
        [h.t('instructive_messages.results.approve'), 'green']
      elsif rejected?
        [h.t('instructive_messages.results.rejected', reject_reason: reject_reason), 'red']
      end
    end
    
    def results_approve_per
    end
  end
end