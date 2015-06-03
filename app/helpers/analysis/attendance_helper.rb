module Analysis
  module AttendanceHelper
    def neighborhood_tooltip(neighborhood)
      content_tag(:div, style: 'white-space: nowrap;') do
        content_tag(:b, neighborhood.name) +
        tag(:br) +
        content_tag(:span, neighborhood.attendees, style: 'font-size:15px; font-weight: bold;') +
        content_tag(:span, 'ATTENDEES', style: 'ffont-size:13px') +
        neighborhood_attended_info(neighborhood) +
        neighborhood_rsvps_info(neighborhood) +
        neighborhood_invitations_info(neighborhood)
      end
    end

    def neighborhood_attended_info(neighborhood)
      if neighborhood.try(:attended)
        tag(:br) +
        content_tag(:span, "#{neighborhood.attended} ACCOUNTS ATTENDED", style: 'font-size:12px')
      else
        ''.html_safe
      end
    end

    def neighborhood_rsvps_info(neighborhood)
      if neighborhood.try(:rsvps)
        tag(:br) +
        content_tag(:span, "#{neighborhood.rsvps} RSVPs", style: 'font-size:12px')
      else
        ''.html_safe
      end
    end

    def neighborhood_invitations_info(neighborhood)
      if neighborhood.try(:attended)
        tag(:br) +
        content_tag(:span, "#{neighborhood.invitations} INVITATIONS", style: 'font-size:12px')
      else
        ''.html_safe
      end
    end
  end
end
