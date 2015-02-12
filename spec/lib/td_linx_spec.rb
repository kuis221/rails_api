require 'rails_helper'
require 'td_linx'

describe TdLinx do
  describe TdLinx::Processor do
    describe 'process' do
      let(:path) { 'tmp/test_sync.csv' }

      after { File.delete(path) if File.exist?(path) }

      it 'should assign the code to the two places' do

        expect(TdlinxMailer).to receive(:td_linx_process_completed).and_return(double(deliver: true))
        place1 = create(:place, name: 'Big Es Supermarket',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '01027',
          street_number: '11', route: 'Union St', country: 'US')

        place2 = create(:place, name: 'Valley Farms Store',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '01027',
          street_number: '128', route: 'Northampton St', country: 'US')

        File.open(path, 'w') do |file|
          file.write(
          "0000071,Big Es Supermarket,11 Union St,Easthampton,MA,01027\n" \
          '0000072,Valley Farms Store,128 Northampton St,Easthampton,MA,01027'
        )
        end

        files = described_class.process(path)

        expect(place1.reload.td_linx_code).to eql '0000071'
        expect(place2.reload.td_linx_code).to eql '0000072'

        # validate the found file was correctly generated
        rows = CSV.read(files[:found])
        expect(rows.count).to eql 2
        expect(rows[0][0]).to eql '0000071'
        expect(rows[1][0]).to eql '0000072'
      end
    end

    describe 'find_place_in_td_linx_table' do
      let(:place) do
        { 'td_linx_code' => '1', 'name' => 'The Venue name',
          'street' => '11 Union St', 'city' => 'easthampton', 'state' => 'ma',
          'zipcode' => '12345' }
      end

      before :all do
        described_class.drop_tmp_table
        described_class.create_tmp_table
        ActiveRecord::Base.connection.execute "
          INSERT INTO tdlinx_codes VALUES (1, 'The Venue name','11 Union St','easthampton', 'ma', '12345')"
      end

      after :all do
        described_class.drop_tmp_table
      end

      it 'should find an existing venue with exactly the same attributes' do
        result = described_class.find_place_in_td_linx_table(
          double(Place, name: 'The Venue name', street_number: '11',  route: 'Union St', city: 'Easthampton', state_code: 'MA'))
        expect(result).to include place
      end

      it 'should find an existing venue with a equivalent street' do
        result = described_class.find_place_in_td_linx_table(
          double(Place, name: 'The Venue name', street_number: '11',  route: 'Union Street', city: 'Easthampton', state_code: 'MA', zipcode: '12345'))
        expect(result).to include place

        result = described_class.find_place_in_td_linx_table(
          double(Place, name: 'The Venue name', street_number: '11',  route: 'UNION Street.', city: 'Easthampton', state_code: 'MA', zipcode: '12345'))
        expect(result).to include place

        result = described_class.find_place_in_td_linx_table(
          double(Place, name: 'The Venue name', street_number: '11',  route: 'union st.', city: 'Easthampton', state_code: 'MA', zipcode: '12345'))
        expect(result).to include place
      end

      it "should find a place if the zip code doesn't match" do
        result = described_class.find_place_in_td_linx_table(
          double(Place, name: 'The Venue name', street_number: '11',  route: 'Union St', city: 'Easthampton', state_code: 'MA', zipcode: '12346'))
        expect(result).to include place
      end

      it 'should find a place even when the street address is slightly different' do
        result = described_class.find_place_in_td_linx_table(
          double(Place, name: 'The Venue name', street_number: '111',  route: 'Union St', city: 'Easthampton', state_code: 'MA', zipcode: '12345'))
        expect(result).to include place
      end
    end
  end
end
