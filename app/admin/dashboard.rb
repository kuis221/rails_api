ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    # div :class => "blank_slate_container", :id => "dashboard_default_message" do
    #   span :class => "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    # Here is an example of a simple dashboard with columns and panels.
    #
    columns do
      column do
        panel "Upcomming Events" do
          ul do
            Event.upcomming.limit(5).map do |event|
              li link_to(event.campaign_name, event_path(event)) + '<br />'.html_safe +
              event.start_at
            end
          end
        end
      end

      column do
        panel "Latests Events" do
          ul do
            Event.order('created_at desc').limit(5).map do |event|
              li do
                link_to(event.campaign_name, event_path(event)) + '<br />'.html_safe +
                event.start_at
              end
            end
          end
        end
      end
    end

    columns do
      column do
        panel "Active Users" do
          ul do
            CompanyUser.where('last_activity_at > ?', 30.minutes.ago).order('last_activity_at desc').limit(5).map do |user|
              li do
                link_to(user.full_name, company_user_path(user)) + '<br />'.html_safe +
                time_ago_in_words(user.last_activity_at)
              end
            end
          end
        end
      end

      column do
        panel "Last Invited Users" do
          ul do
            User.invitation_not_accepted.where('invitation_token is not null').order('invitation_sent_at desc').limit(5).map do |user|
              li do
                link_to(user.full_name, company_user_path(user)) + '<br />'.html_safe +
                time_ago_in_words(user.invitation_sent_at)
              end
            end
          end
        end
      end
    end
  end # content
end
