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
                content_tag(:div, ((i + 1) >= active ? i + 1 : content_tag(:i, '', class: 'icon-checked')), class: 'circle-step ') +
                if (i + 1) < active
                  content_tag(:a, step, href: form_action(params.merge(step: (i + 1))) , class: 'step-name')
                else
                  content_tag(:div, step, class: 'step-name')
                end
              end
            end
          end.join.html_safe
        end
      end
    end

    def render_table_cols(columns, step, sort_by, sort_dir, &block)
      content_tag(:thead) do
        content_tag(:tr, class: 'data-extract-head') do
          if columns.present?
            columns.map do |col|
              block_content = capture(col[0], &block) if block_given?
              content_tag(:th, class: 'data-extract-th', data: { name: col[0] }) do
                content_tag(:div, class: 'dropdown') do
                  icon = sort_by == col[0] ? content_tag(:i, '', class: 'icon-checked') : ''
                  content_tag(:span, col[1]) +
                  (if step < 3
                     link_to('', '', title: 'tool', class: 'icon-arrow-down-small dropdown-toggle', data: { name: col[0], toggle: 'dropdown' }) +
                     content_tag(:ul, class: 'dropdown-menu', role: 'menu') do
                       content_tag(:li, icon_sort_asc + link_to(('Sort Ascending' + (sort_dir == 'asc' ? icon : '')).html_safe, '#', class: 'btn-sort-asc btn-sort-table', data: { column: col[0], dir: 'asc' })) +
                       content_tag(:li, icon_sort_desc + link_to(('Sort Descending' + (sort_dir == 'desc' ? icon : '')).html_safe, '#', class: 'btn-sort-desc btn-sort-table', data: { column: col[0], dir: 'desc' })) +
                       content_tag(:li, nil, class: 'divider') +
                       content_tag(:li, icon_visibility_off + link_to('Hide', '#', class: 'btn-remove-column', data: { column: col[0] }))
                     end
                   end)
                end + (block_given? ? block_content : '').html_safe
              end
            end.join.html_safe
          end
        end
      end
    end

    def icon_sort_asc
      content_tag(:i, '', class: 'icon-sort-asc')
    end

    def icon_sort_desc
      content_tag(:i, '', class: 'icon-sort-desc')
    end

    def icon_visibility_off
      content_tag(:i, '', class: 'icon-visibility-off')
    end

    def render_table_rows(rows)
      return unless rows.present?
      rows.map do |row|
        content_tag(:tr) do
          Array(row).map do |field|
            content_tag(:td, field)
          end.join.html_safe
        end
      end.join.html_safe
    end

    def render_available_fields(fields, source)
      content_tag(:ul, class: 'available-field-list', id: 'available-field-list') do
        if fields.present?
          fields.sort.map do |field|
            content_tag(:li, field[1], class: 'available-field', data: { name: field[0], title: render_descripcion_available_field(field[0], source)})
          end.join.html_safe
        end
      end
    end

    def render_descripcion_available_field(field, source)
      desc = "<p class=\"name\">#{I18n.t("data_exports.fields.#{field}")}</p>"
      desc << "<p class=\"description\">#{I18n.t("data_exports.descriptions.#{source}.#{field}")}</p>"
    end
  end
end