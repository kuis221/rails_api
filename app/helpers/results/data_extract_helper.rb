module Results
  module DataExtractHelper
    def data_extract_navigation_bar(active)
      data_extract_step_navigation_bar([
        content_tag(:div, 'SELECT SOURCES', class: 'text-large'),
        content_tag(:div, 'CONFIGURE', class: 'text-large'),
        content_tag(:div, 'PREVIEW & SAVE', class: 'text-large')
      ], active)
    end

    def data_extract_step_navigation_bar(steps, active)
      content_tag :div, class: 'steps-wizard-data-source' do
        content_tag(:div, class: 'row-fluid') do
          steps.each_with_index.map do |step, i|
            step_class = (active == (i + 1) ? 'active' : (active > i ? 'completed' : ''))
            content_tag(:div, class: 'step ' + step_class) do
              content_tag :div, class: 'step-box' do
                content_tag(:div, i + 1, class: 'circle-step ' +  (active > i + 1 ? 'icon-checked' : '')) +
                content_tag(:div, step, class: 'step-name')
              end
            end
          end.join.html_safe
        end
      end
    end

    def render_table_cols(columns)
      content_tag(:thead) do
        content_tag(:tr, class: 'data-extract-head') do
          if columns.present?
            columns.map do |col|
              content_tag(:th, class: 'data-extract-th', data:{name: col}) do
                content_tag(:div, class: 'dropdown') do
                  content_tag(:span, I18n.t("data_exports.fields.#{col.to_s}")) +
                  link_to('','', title: 'tool', class: 'icon-arrow-down pull-right dropdown-toggle', data:{ name: col, toggle: 'dropdown'}) +
                  content_tag(:ul, class: 'dropdown-menu', role: 'menu') do
                    content_tag(:li, link_to('Hide', '#', class: 'btn-remove-column', data: { column: col }))
                  end
                end
              end
            end.join.html_safe
          end
        end
      end
    end

    def render_table_rows(rows)
      return unless rows.present?
      rows.map do |row|
        content_tag(:tr, class: 'data-extract-row') do
          row.map do |field|
            content_tag(:td, field, class: 'data-extract-td')
          end.join.html_safe
        end
      end.join.html_safe
    end

    def render_available_fields(fields)
      content_tag(:ul, class: 'available-field-list') do
        if fields.present?
          fields.sort.map do |field|
            content_tag(:li, I18n.t("data_exports.fields.#{field.to_s}"), class: 'available-field', data:{name: field})
          end.join.html_safe
        end
       end
    end
  end
end