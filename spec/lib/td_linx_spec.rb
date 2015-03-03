require 'rails_helper'
require 'td_linx'

describe TdLinx do
  describe TdLinx::Processor do
    describe 'download_and_process_file' do
      let(:path) { 'tmp/test_sync.csv' }

      after { File.delete(path) if File.exist?(path) }

      it 'should assign the code to the two places' do

        expect(TdlinxMailer).to receive(:td_linx_process_completed).and_return(double(deliver: true))
        place1 = create(:place, name: 'Big Es Supermarket',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '01027',
          street_number: '11', route: 'Union St', country: 'US')

        place2 = create(:place, name: 'Valley Farms Store',
          city: 'Easthampton', state: 'Massachusetts', zipcode: '03027',
          street_number: '128', route: 'Northampton St', country: 'US')

        [place1, place2].each { |p| create(:venue, company_id: described_class::COMPANY_ID, place: p) }

        File.open(path, 'w') do |file|
          file.write(
            "0000071,Big Es Supermarket,11 Union St,Easthampton,MA,01027\n" \
            '0000072,Bar Valley Farms,128 Northampton St,Easthampton,MA,03027'
          )
        end

        files = described_class.download_and_process_file(path)

        expect(place1.reload.td_linx_code).to eql '0000071'
        expect(place2.reload.td_linx_code).to eql '0000072'

        # validate the found file was correctly generated
        rows = CSV.read(files[:found])
        expect(rows.count).to eql 2
        expect(rows[0][0]).to eql '0000071'
        expect(rows[0][6]).to eql 'High'
        expect(rows[1][0]).to eql '0000072'
        expect(rows[1][6]).to eql 'Medium'
      end
    end
  end
end
