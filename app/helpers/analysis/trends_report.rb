module Analysis::TrendsReport
  def highlight_trend_words(text, trend_word)
    highlight(text, trend_word, highlighter: '<span class="highlight">\1</span>')
  end
end
