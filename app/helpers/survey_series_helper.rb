module SurveySeriesHelper
  def series_question_1(brands, stats)
    [{
      name: 'UNAWARE',
      color: '#1F8EBC',
      legendIndex: 3,
      data: brands.map { |b| stats['unaware'][b.name][:avg].round rescue 0 }
    }, {
      name: 'AWARE',
      color: '#6DBCE7',
      legendIndex: 2,
      data: brands.map { |b| stats['aware'][b.name][:avg].round rescue 0 }
    }, {
      name: 'PURCHASED',
      color: '#A8DDEF',
      legendIndex: 1,
      data: brands.map { |b| stats['purchased'][b.name][:avg].round rescue 0 }
    }]
  end

  def series_question_2(stats)
    [{
      name: 'average',
      categories: stats.map { |b, _s| b },
      data: stats.map { |_b, s| s[:avg].round },
      dataLabels: {
        enabled: true,
        format: '${y}',
        color: '#3E9CCF',
        align: 'right',
        x: 0,
        y: 0,
        style: { color: '#3E9CCF' }
      }
    }]
  end

  def series_question_3(brands, stats)
    ids = { 2 => 'UNLIKELY', 3 => 'NEUTRAL', 5 => 'LIKELY' }
    (1..5).map do |i|
      {
        name: i,
        legendIndex: i,
        color: (i < 3 ? '#A8DDEF' : (i < 4 ? '#6DBCE7' : '#1F8EBC')),
        data: brands.map { |b| stats[i.to_s][b.name][:avg].round rescue 0 }
      }.merge(ids.key?(i) ?  { id: ids[i] } : { linkedTo: ':previous' })
    end.reverse
  end

  def series_question_4(brands, stats)
    ids = { 6 => 'UNLIKELY', 8 => 'NEUTRAL', 10 => 'LIKELY' }
    (1..10).map do |i|
      {
        name: i,
        legendIndex: i,
        color: (i < 7 ? '#A8DDEF' : (i < 9 ? '#6DBCE7' : '#1F8EBC')),
        data: brands.map { |b| stats[i.to_s][b.name][:avg].round rescue 0 }
      }.merge(ids.key?(i) ?  { id: ids[i] } : { linkedTo: ':previous' })
    end.reverse
  end
end
