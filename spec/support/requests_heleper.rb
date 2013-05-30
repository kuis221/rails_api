
module RequestsHelper
  def assert_table_sorting(table)
    within table do
      count = all('tbody tr').count
      ids = all('tbody tr').map {|row| row['id']}
      all('thead th[data-sort]').each do |th|
        page.execute_script("$('#{table} tbody').empty()")
        all('tbody tr').count.should == 0
        th.click
        find('tbody tr:first-child') # Wait until the rows have been loaded
        all('tbody tr').count.should == count
        new_ids = all('tbody tr').map {|row| row['id']}
        new_ids.should =~ ids
      end
    end
  end

end