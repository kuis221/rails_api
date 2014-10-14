module Analysis::TrendsHelper
  def highlight_trend_words(text, trend_word)
    highlight(text, trend_word, highlighter: '<span class="highlight">\1</span>')
  end

  def trends_navigation_bar(active)
    step_navigation_bar([
      content_tag(:div, 'STEP 1:', class: 'text-large') +
        'SELECT SOURCES'.html_safe,
      content_tag(:div, 'STEP 2:', class: 'text-large') +
        'SELECT INDIVIDUAL QUESTIONS & DATA FIELDS'.html_safe,
      content_tag(:div, 'STEP 3:', class: 'text-large') +
        'RESULTS'.html_safe
    ], active)
  end

  def available_data_sources
    [['Comments', 'Comment']] +
    current_company.activity_types.active.with_trending_fields.pluck(:name, :id)
  end
end
