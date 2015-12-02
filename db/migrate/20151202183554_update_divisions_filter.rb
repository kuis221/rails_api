class UpdateDivisionsFilter < ActiveRecord::Migration
  def up
    # American (SWS Open)
    CustomFilter.find(22).update_column :filters, "area%5B%5D=73&area%5B%5D=23&area%5B%5D=71&area%5B%5D=24&area%5B%5D=76&area%5B%5D=25&area%5B%5D=7&area%5B%5D=68&area%5B%5D=102&area%5B%5D=9&area%5B%5D=100&area%5B%5D=74&area%5B%5D=32&area%5B%5D=33&area%5B%5D=34&area%5B%5D=67&area%5B%5D=35&area%5B%5D=38&area%5B%5D=90&area%5B%5D=59&area%5B%5D=40&area%5B%5D=41&area%5B%5D=2&area%5B%5D=14&area%5B%5D=42&area%5B%5D=43&area%5B%5D=3&area%5B%5D=95&area%5B%5D=77&area%5B%5D=98&area%5B%5D=15&area%5B%5D=45&area%5B%5D=46&area%5B%5D=64&area%5B%5D=50&area%5B%5D=10&area%5B%5D=11&area%5B%5D=16&area%5B%5D=52&area%5B%5D=58&area%5B%5D=13&area%5B%5D=8&area%5B%5D=55&area%5B%5D=96&area%5B%5D=127&area%5B%5D=128&area%5B%5D=124&area%5B%5D=138&area%5B%5D=136&area%5B%5D=145&area%5B%5D=17&area%5B%5D=164&area%5B%5D=146&area%5B%5D=132&area%5B%5D=131&area%5B%5D=133&area%5B%5D=223&area%5B%5D=123&area%5B%5D=129&area%5B%5D=167"
    # Continental
    CustomFilter.find(23).update_column :filters, "area%5B%5D=20&area%5B%5D=72&area%5B%5D=21&area%5B%5D=12&area%5B%5D=22&area%5B%5D=57&area%5B%5D=5&area%5B%5D=1&area%5B%5D=70&area%5B%5D=29&area%5B%5D=30&area%5B%5D=37&area%5B%5D=85&area%5B%5D=39&area%5B%5D=84&area%5B%5D=83&area%5B%5D=66&area%5B%5D=60&area%5B%5D=61&area%5B%5D=4&area%5B%5D=44&area%5B%5D=81&area%5B%5D=62&area%5B%5D=49&area%5B%5D=51&area%5B%5D=53&area%5B%5D=79&area%5B%5D=80&area%5B%5D=174&area%5B%5D=65&area%5B%5D=142&area%5B%5D=130&area%5B%5D=162&area%5B%5D=163&area%5B%5D=125&area%5B%5D=150&area%5B%5D=172&area%5B%5D=214&area%5B%5D=147&area%5B%5D=173"
    # Liberty (Control)
    CustomFilter.find(24).update_column :filters, "area%5B%5D=19&area%5B%5D=88&area%5B%5D=26&area%5B%5D=27&area%5B%5D=28&area%5B%5D=31&area%5B%5D=18&area%5B%5D=36&area%5B%5D=105&area%5B%5D=101&area%5B%5D=6&area%5B%5D=47&area%5B%5D=48&area%5B%5D=63&area%5B%5D=54&area%5B%5D=56&area%5B%5D=82&area%5B%5D=170&area%5B%5D=134&area%5B%5D=148&area%5B%5D=166&area%5B%5D=126&area%5B%5D=165&area%5B%5D=143&area%5B%5D=171"
  end

  def down
    # American (SWS Open)
    CustomFilter.find(22).update_column :filters, "area%5B%5D=73&area%5B%5D=23&area%5B%5D=71&area%5B%5D=24&area%5B%5D=76&area%5B%5D=25&area%5B%5D=7&area%5B%5D=68&area%5B%5D=65&area%5B%5D=102&area%5B%5D=9&area%5B%5D=100&area%5B%5D=74&area%5B%5D=32&area%5B%5D=33&area%5B%5D=34&area%5B%5D=67&area%5B%5D=35&area%5B%5D=38&area%5B%5D=90&area%5B%5D=59&area%5B%5D=40&area%5B%5D=41&area%5B%5D=2&area%5B%5D=14&area%5B%5D=42&area%5B%5D=43&area%5B%5D=3&area%5B%5D=95&area%5B%5D=77&area%5B%5D=98&area%5B%5D=15&area%5B%5D=45&area%5B%5D=46&area%5B%5D=64&area%5B%5D=50&area%5B%5D=10&area%5B%5D=11&area%5B%5D=16&area%5B%5D=52&area%5B%5D=58&area%5B%5D=13&area%5B%5D=99&area%5B%5D=8&area%5B%5D=55&area%5B%5D=96"
    # Continental
    CustomFilter.find(23).update_column :filters, "area%5B%5D=20&area%5B%5D=72&area%5B%5D=21&area%5B%5D=12&area%5B%5D=22&area%5B%5D=57&area%5B%5D=5&area%5B%5D=1&area%5B%5D=70&area%5B%5D=29&area%5B%5D=30&area%5B%5D=37&area%5B%5D=85&area%5B%5D=39&area%5B%5D=84&area%5B%5D=83&area%5B%5D=66&area%5B%5D=60&area%5B%5D=61&area%5B%5D=4&area%5B%5D=44&area%5B%5D=81&area%5B%5D=62&area%5B%5D=49&area%5B%5D=51&area%5B%5D=53&area%5B%5D=79&area%5B%5D=80"
    # Liberty (Control)
    CustomFilter.find(24).update_column :filters, "area%5B%5D=19&area%5B%5D=88&area%5B%5D=26&area%5B%5D=27&area%5B%5D=28&area%5B%5D=31&area%5B%5D=18&area%5B%5D=36&area%5B%5D=105&area%5B%5D=101&area%5B%5D=6&area%5B%5D=47&area%5B%5D=48&area%5B%5D=63&area%5B%5D=54&area%5B%5D=103&area%5B%5D=56"
  end
end
