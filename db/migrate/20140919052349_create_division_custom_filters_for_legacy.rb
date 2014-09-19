class CreateDivisionCustomFiltersForLegacy < ActiveRecord::Migration
  def up
    CustomFilter.create({
      name:  "American (SWS Open)",
      apply_to:  "visits",
      group: 'Divisions',
      filters:  "area%5B%5D=73&area%5B%5D=23&area%5B%5D=71&area%5B%5D=24&area%5B%5D=76&area%5B%5D=25&area%5B%5D=7&area%5B%5D=68&area%5B%5D=65&area%5B%5D=102&area%5B%5D=9&area%5B%5D=100&area%5B%5D=74&area%5B%5D=32&area%5B%5D=33&area%5B%5D=34&area%5B%5D=67&area%5B%5D=35&area%5B%5D=38&area%5B%5D=90&area%5B%5D=59&area%5B%5D=40&area%5B%5D=41&area%5B%5D=2&area%5B%5D=14&area%5B%5D=42&area%5B%5D=43&area%5B%5D=3&area%5B%5D=95&area%5B%5D=77&area%5B%5D=98&area%5B%5D=15&area%5B%5D=45&area%5B%5D=46&area%5B%5D=64&area%5B%5D=50&area%5B%5D=10&area%5B%5D=11&area%5B%5D=16&area%5B%5D=52&area%5B%5D=58&area%5B%5D=13&area%5B%5D=99&area%5B%5D=8&area%5B%5D=55&area%5B%5D=96",
      owner_id:  2,
      owner_type:  "Company"
    })
    CustomFilter.create({
      name:  "Continental",
      apply_to:  "visits",
      group: 'Divisions',
      filters:  "area%5B%5D=20&area%5B%5D=72&area%5B%5D=21&area%5B%5D=12&area%5B%5D=22&area%5B%5D=57&area%5B%5D=5&area%5B%5D=1&area%5B%5D=70&area%5B%5D=29&area%5B%5D=30&area%5B%5D=37&area%5B%5D=85&area%5B%5D=39&area%5B%5D=84&area%5B%5D=83&area%5B%5D=66&area%5B%5D=60&area%5B%5D=61&area%5B%5D=4&area%5B%5D=44&area%5B%5D=81&area%5B%5D=62&area%5B%5D=49&area%5B%5D=51&area%5B%5D=53&area%5B%5D=79&area%5B%5D=80",
      owner_id:  2,
      owner_type:  "Company"
    })
    CustomFilter.create({
      name:  "Liberty (Control)",
      apply_to:  "visits",
      group: 'Divisions',
      filters:  "area%5B%5D=19&area%5B%5D=88&area%5B%5D=26&area%5B%5D=27&area%5B%5D=28&area%5B%5D=31&area%5B%5D=18&area%5B%5D=36&area%5B%5D=105&area%5B%5D=101&area%5B%5D=6&area%5B%5D=47&area%5B%5D=48&area%5B%5D=63&area%5B%5D=54&area%5B%5D=103&area%5B%5D=56",
      owner_id:  2,
      owner_type:  "Company"
    })
  end
end
