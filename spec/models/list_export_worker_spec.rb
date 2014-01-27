require 'spec_helper'

describe ListExportWorker do
    it "should return an empty book with the correct headers" do
      woorbook_from_response do |oo|
        oo.last_row.should == 2
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should == ["", "CAMPAIGN NAME", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP", "START", "END", "PROMO HOURS", "IMPRESSIONS", "INTERACTIONS", "SAMPLED", "SPENT", "FEMALE", "MALE", "ASIAN", "BLACK/AFRICAN AMERICAN", "HISPANIC/LATINO", "NATIVE AMERICAN", "WHITE"]
        1.upto(oo.last_column).map{|col| oo.cell(2, col) }.should == ["TOTALS", "0 EVENTS", "", "", "", "", "", "", "", 0.0, 0.0, 0.0, 0.0, "$0.00", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%"]
      end
    end
end