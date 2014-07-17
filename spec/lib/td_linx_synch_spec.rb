require 'spec_helper'
require 'td_linx'

describe TdLinxSynch do
  describe TdLinxSynch::Processor do
    describe "process" do
      let(:path){ 'tmp/test_sync.csv' }

      after{ File.delete(path) if File.exists?(path) }

      it "should assign the code to the two places" do

        TdlinxMailer.should_receive(:td_linx_process_completed).and_return(double(deliver: true))
        place1 = FactoryGirl.create(:place, name: 'Big Es Supermarket',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '01027',
          street_number: '11', route: 'Union St', country: 'US')

        place2 = FactoryGirl.create(:place, name: 'Valley Farms Store',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '01027',
          street_number: '128', route: 'Northampton St', country: 'US')

        File.open(path, 'w') { |file| file.write(
          "0000071,Big Es Supermarket,11 Union St,Easthampton,MA,01027\n" +
          "0000072,Valley Farms Store,128 Northampton St,Easthampton,MA,01027"
        ) }

        files = TdLinxSynch::Processor.process(path)

        expect(place1.reload.td_linx_code).to eql '0000071'
        expect(place2.reload.td_linx_code).to eql '0000072'

        # validate the found file was correctly generated
        rows = CSV.read(files[:found])
        expect(rows.count).to eql 2
        expect(rows[0][0]).to eql '0000071'
        expect(rows[1][0]).to eql '0000072'
      end
    end
    describe "find_place_for_row" do
      let(:place) { FactoryGirl.create(:place, name: 'The Venue name',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '12345',
          street_number: '11', route: 'Union St', country: 'US') }

      before { place.save }

      it "should find an existing venue with exactly the same attributes" do
        result = TdLinxSynch::Processor.find_place_for_row(
          ['1', 'The Venue name', '11 Union St', 'Easthampton' ,'MA', '12345'])
        expect(result).to eql place.id
      end

      it "should find an existing venue with a equivalent street" do
        result = TdLinxSynch::Processor.find_place_for_row(
          ['1', 'The Venue name', '11 Union Street', 'Easthampton' ,'MA', '12345'])
        expect(result).to eql place.id

        result = TdLinxSynch::Processor.find_place_for_row(
          ['1', 'The Venue name', '11 UNION Street.', 'Easthampton' ,'MA', '12345'])
        expect(result).to eql place.id

        result = TdLinxSynch::Processor.find_place_for_row(
          ['1', 'The Venue name', '11 union st.', 'Easthampton' ,'MA', '12345'])
        expect(result).to eql place.id
      end

      it "should not find a place if the zip code doesn't match" do
        result = TdLinxSynch::Processor.find_place_for_row(
          ['1', 'The Venue name', '11 Union St', 'Easthampton' ,'MA', '12346'])
        expect(result).to be_nil
      end

      it "should not find a place if the street doesn't match" do
        result = TdLinxSynch::Processor.find_place_for_row(
          ['1', 'The Venue name', '111 Union St', 'Easthampton' ,'MA', '12345'])
        expect(result).to be_nil
      end
    end
  end
end