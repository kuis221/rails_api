require 'rails_helper'

describe ApplicationHelper, type: :helper do
  after do
    Timecop.return
  end

  describe '#place_address' do
    it 'should add the name to the address' do
      place = double(Place, name: 'Some Place Name', street: nil, state: nil, zipcode: nil, city: nil, formatted_address: nil)
      assert_dom_equal "<address><span class=\"address-name\">Some Place Name</span></address>", helper.place_address(place)
    end

    it 'should add the street to the address' do
      place = double(Place, name: 'Some Place Name', street: 'Street Name', state: nil, zipcode: nil, city: nil, formatted_address: nil)
      assert_dom_equal "<address><span class=\"address-name\">Some Place Name</span><br/>Street Name</address>", helper.place_address(place)
    end

    it "should not add the street to the address if it's the same as the place name" do
      place = double(Place, name: 'Some Place Name', street: 'Some Place Name', state: nil, zipcode: nil, city: nil, formatted_address: nil)
      assert_dom_equal "<address><span class=\"address-name\">Some Place Name</span></address>", helper.place_address(place)
    end

    it 'should not add the street if it has an empty string or with spaces' do
      place = double(Place, name: 'Some Place Name', street: ' ', state: nil, zipcode: nil, city: nil, formatted_address: nil)
      assert_dom_equal "<address><span class=\"address-name\">Some Place Name</span></address>", helper.place_address(place)
    end

    it 'should add the city to the address' do
      place = double(Place, name: nil, street: nil, state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil)
      assert_dom_equal '<address>Curridabat</address>', helper.place_address(place)
    end

    it 'should add the name and city to the address is separated lines' do
      place = double(Place, name: 'Place name', street: nil, state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil)
      assert_dom_equal "<address><span class=\"address-name\">Place name</span><br />Curridabat</address>", helper.place_address(place)
    end

    it 'should add the name, street and city to the address is separated lines' do
      place = double(Place, name: 'Place name', street: '123 uno dos tres', state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil)
      assert_dom_equal "<address><span class=\"address-name\">Place name</span><br />123 uno dos tres<br />Curridabat</address>", helper.place_address(place)
    end

    it 'should add the state to the address' do
      place = double(Place, name: nil, street: nil, state: 'California', zipcode: nil, city: 'Los Angeles', formatted_address: nil)
      assert_dom_equal '<address>Los Angeles, California</address>', helper.place_address(place)
    end

    it 'should add the state and the zipcode to the address separated by a commma' do
      place = double(Place, name: nil, street: nil, state: 'California', zipcode: '90210', city: 'Los Angeles', formatted_address: nil)
      assert_dom_equal '<address>Los Angeles, California, 90210</address>', helper.place_address(place)
    end

    it 'should add the city, state and the zipcode to the address separated by a commma' do
      place = double(Place, name: nil, street: nil, state: 'California', zipcode: '90210', city: 'Beverly Hills', formatted_address: nil)
      assert_dom_equal '<address>Beverly Hills, California, 90210</address>', helper.place_address(place)
    end
  end

  describe '#comment_date' do
    it "should return the full date when it's older than 4 days" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
        comment = double(Comment, created_at: Time.zone.local(2013, 07, 22, 11, 59))
        expect(helper.comment_date(comment)).to eq('Jul 22 @ 11:59 AM')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 19, 11, 59))
        expect(helper.comment_date(comment)).to eq('Jul 19 @ 11:59 AM')

        comment = double(Comment, created_at: Time.zone.local(2013, 06, 19, 11, 59))
        expect(helper.comment_date(comment)).to eq('Jun 19 @ 11:59 AM')
      end
    end

    it 'should return the day of the week if the comment is older than yesterday but newer than 4 days' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
        comment = double(Comment, created_at: Time.zone.local(2013, 07, 23, 00, 00))
        expect(helper.comment_date(comment)).to eq('Tuesday @ 12:00 AM')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 24, 16, 40))
        expect(helper.comment_date(comment)).to eq('Wednesday @  4:40 PM')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 24, 23, 59))
        expect(helper.comment_date(comment)).to eq('Wednesday @ 11:59 PM')
      end
    end

    it "should return 'Yesterday' plus the time if the date is older than 24 horus" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
        comment = double(Comment, created_at: Time.zone.local(2013, 07, 25, 11, 59))
        expect(helper.comment_date(comment)).to eq('Yesterday @ 11:59 AM')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 25, 00, 0))
        expect(helper.comment_date(comment)).to eq('Yesterday @ 12:00 AM')
      end
    end

    it 'should return the number of hours rounded to the lower number' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
        comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 10, 59))
        expect(helper.comment_date(comment)).to eq('about an hour ago')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 10, 22))
        expect(helper.comment_date(comment)).to eq('about an hour ago')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 9, 0))
        expect(helper.comment_date(comment)).to eq('3 hours ago')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 25, 12, 01))
        expect(helper.comment_date(comment)).to eq('23 hours ago')
      end
    end

    it 'should return the number of minutes' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
        comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 11, 59))
        expect(helper.comment_date(comment)).to eq('about 1 minute ago')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 11, 30))
        expect(helper.comment_date(comment)).to eq('about 30 minutes ago')

        comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 11, 01))
        expect(helper.comment_date(comment)).to eq('about 59 minutes ago')
      end
    end
  end

  describe '#format_date' do
    it 'should return nil if date is nil' do
      expect(helper.format_date(nil)).to be_nil
    end

    it 'should return the formatted date without the year if the event is in the same year' do
      Timecop.freeze(Time.zone.local(2013, 9, 1, 12, 0)) do
        assert_dom_equal 'FRI <b>Jul 26</b>', helper.format_date(Time.zone.local(2013, 07, 26, 3, 0))
      end
    end

    it 'should return the formatted date with the year if the event is in other year' do
      Timecop.freeze(Time.zone.local(2012, 9, 1, 12, 0)) do
        assert_dom_equal 'FRI <b>Jul 26, 2013</b>', helper.format_date(Time.zone.local(2013, 07, 26, 3, 0))
      end
    end
  end

  describe '#format_date_range' do
    it 'should return both dates' do
      Timecop.freeze(Time.zone.local(2013, 9, 1, 12, 0)) do
        assert_dom_equal 'FRI <b>Jul 26</b> at 10:59 AM<br />SAT <b>Jul 27</b> at  3:00 AM', helper.format_date_range(Time.zone.local(2013, 07, 26, 10, 59), Time.zone.local(2013, 07, 27, 3, 0))
      end
    end

    it 'should one date and both hours if the end day is the same as the start day' do
      Timecop.freeze(Time.zone.local(2013, 9, 1, 12, 0)) do
        assert_dom_equal 'FRI <b>Jul 26</b><br />3:00 AM - 9:00 AM', helper.format_date_range(Time.zone.local(2013, 07, 26, 3, 0), Time.zone.local(2013, 07, 26, 9, 0))
      end
    end
  end
end
