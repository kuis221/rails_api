namespace :brandscopic do
  desc 'Merge duplicated venues'
  task merge_duplicated_venues: :environment do
    count = 0
    processed_ids = []
    Place.find_each do |place|
      next if processed_ids.include?(place.id)
      Place.where.not(id: place.id).where(name: place.name, city: place.city, state: place.state, route: place.route).each do |copy|
        puts "Copy found:\n"
        puts "   ORIGINAL: #{place.inspect}\n"
        puts "   COPY:     #{copy.inspect}\n"
        processed_ids.concat [place.id, copy.id]
        place.merge(copy)
        count += 1;
      end
    end

    puts "Found #{count} duplicates\n"
  end

  desc 'Fix places place_id'
  task fix_place_id: :environment do
    Place.where.not(place_id: nil).where.not(place_id: '').find_each do |place|
      spot = place.send(:spot)
      next unless spot.present?
      place.place_id = spot.place_id
      sleep Random.rand(3)
    end
  end

  desc 'generage recovery script'
  task generate_recovery: :environment do
    list = [
      ["James Hoban's Irish Bar & Restaurant", "1 dup"],
      ["James Hoban's Irish Bar & Restaurant", "1 dup"],
      ["Ferry Plaza Farmers Market", "1 fer"],
      ["Ferry Building Marketplace", "1 fer"],
      ["Sweet & Vicious", "5 spr"],
      ["Sweet & Vicious", "5 spr"],
      ["Apotheke", "9 doy"],
      ["Apothéke", "9 doy"],
      ["Kelly's Irish Times", "14 f "],
      ["Kelly's Irish Times", "14 f "],
      ["Clarke's at Faneuil Hall", "21 me"],
      ["Clarke's at Faneuil Hall", "21 me"],
      ["Alma Nove", "22 sh"],
      ["Alma Nove", "22 sh"],
      ["M J O'Connor's", "27 co"],
      ["M J O'Connor's", "27 co"],
      ["The Draft Bar and Grille", "34 ha"],
      ["The Draft", "34 ha"],
      ["McLadden's Irish Publick House", "37 la"],
      ["McLadden's Irish Publick House", "37 la"],
      ["Quality Italian", "57 we"],
      ["Quality Meats", "57 we"],
      ["Mr. Dooley's Boston", "77 br"],
      ["Mr. Dooley's Boston", "77 br"],
      ["Jig and Reel", "101 s"],
      ["Jig and Reel", "101 s"],
      ["Cooper's Union", "104 h"],
      ["Cooper's Union", "104 h"],
      ["Cole's", "118 e"],
      ["Cole's", "118 e"],
      ["Kirby's Steakhouse", "123 l"],
      ["Kirby's Steakhouse", "123 l"],
      ["Binion's Gambling Hall & Hotel", "128 f"],
      ["Binion's", "128 f"],
      ["King Eddy Saloon", "131 e"],
      ["King Eddy Saloon", "131 e"],
      ["3 Sheets Saloon", "134 w"],
      ["3 Sheets Saloon", "134 w"],
      ["Dick O'Dow's", "160 w"],
      ["Dick O'Dow's", "160 w"],
      ["O'Hara's Downtown Sports Bar & Grill", "172 1"],
      ["O'Hara's Downtown Sports Bar & Grill", "172 1"],
      ["Eight Seconds", "201 w"],
      ["Eight Seconds", "201 w"],
      ["P T O'Malley's", "210 a"],
      ["P T O'Malley's", "210 a"],
      ["Fado Irish Pub Austin", "214 w"],
      ["Fado Irish Pub Austin", "214 w"],
      ["Professor Thom's", "219 2"],
      ["Professor Thom's", "219 2"],
      ["Cafe Tallulah", "240 c"],
      ["Cafe Tallulah", "240 c"],
      ["The Stag's Head", "252 e"],
      ["The Stag's Head", "252 e"],
      ["Fadó Irish Pub Atlanta", "273 b"],
      ["Fadó Irish Pub Atlanta", "273 b"],
      ["Louie and Chan", "303 b"],
      ["Louie and Chan", "303 b"],
      ["Duddley's Draw", "311 u"],
      ["Duddley's Draw", "311 u"],
      ["Sol Venue", "313 e"],
      ["SOL Venue", "313 e"],
      ["Third Floor Café", "315 5"],
      ["Third Floor Café", "315 5"],
      ["Swift's Attic", "315 c"],
      ["Swift's Attic", "315 c"],
      ["O'Connor's Public House", "324 s"],
      ["O'Connor's Public House", "324 s"],
      ["Félix", "340 w"],
      ["Félix", "340 w"],
      ["Bull McCabe's", "366 s"],
      ["Bull McCabe's", "366 s"],
      ["Lavaca Street Bar", "405 l"],
      ["Lavaca", "405 l"],
      ["Moose Knuckle Pub", "406 e"],
      ["Moose Knuckle Pub", "406 e"],
      ["Frank Restaurant", "407 c"],
      ["Frank Restaurant", "407 c"],
      ["Burritt Room + Tavern", "417 s"],
      ["Burritt Tavern at the Mystic Hotel", "417 s"],
      ["This is it", "418 e"],
      ["This is it", "418 e"],
      ["Jake's Dilemma", "430 a"],
      ["Jake's Dilemma", "430 a"],
      ["The Los Angeles Athletic Club", "431 w"],
      ["The Los Angeles Athletic Club", "431 w"],
      ["Whiskey Richards (5511038)", "435 s"],
      ["Whiskey Richards", "435 s"],
      ["Wolfgang's Steakhouse", "445 n"],
      ["Wolfgang's Steakhouse", "445 n"],
      ["Ullr's Sports Bar & Grill", "505 s"],
      ["Ullr's Sports Bar & Grill", "505 s"],
      ["Joshua Tree", "513 3"],
      ["Joshua Tree", "513 3"],
      ["Seven Grand", "515 w"],
      ["Seven Grand", "515 w"],
      ["O'Malley's", "523 s"],
      ["O'Malleys Bar", "523 s"],
      ["Tasty N Alder", "580 s"],
      ["Tasty N Alder", "580 s"],
      ["Dargans Irish Pub & Restaurant", "593 e"],
      ["Dargans - SB/Ven", "593 e"],
      ["Beelman's Pub", "600 s"],
      ["Beelman's Pub", "600 s"],
      ["Original Joe's", "601 u"],
      ["Original Joe's", "601 u"],
      ["Wando's", "602 u"],
      ["Wando's", "602 u"],
      ["Rick's American Cafe", "611 c"],
      ["Rick's American Cafe", "611 c"],
      ["John & Pete's Fine Wine and Spirits", "621 n"],
      ["John & Pete's Fine Wine & Spirits", "621 n"],
      ["The Abbey Food & Bar", "692 n"],
      ["The Abbey", "692 n"],
      ["Hardware", "697 1"],
      ["Hardware", "697 1"],
      ["Mission Wine & Spirits 4", "708 s"],
      ["Mission Wine & Spirits 4", "708 s"],
      ["J. BLACK'S Feel Good Kitchen & Lounge", "710 b"],
      ["J. BLACK'S Feel Good Kitchen & Lounge", "710 b"],
      ["Caña Rum Bar", "714 w"],
      ["Caña Rum Bar", "714 w"],
      ["Buffalo Bar & Grill", "717 h"],
      ["Buffalo Pub & Grill (5260751)", "717 h"],
      ["Caffrey's Pub", "717 n"],
      ["Caffrey's Pub", "717 n"],
      ["The Dawson", "730 w"],
      ["The Dawson", "730 w"],
      ["Polo Grounds", "747 3"],
      ["Polo Grounds Pub & Grill", "747 3"],
      ["The Wishing Well", "767 s"],
      ["The Wishing Well", "767 s"],
      ["Oya Restaurant & Lounge", "777 9"],
      ["Oya Restaurant & Lounge", "777 9"],
      ["Pippin's Tavern", "806 n"],
      ["Pippin's Tavern", "806 n"],
      ["Tree House", "820 c"],
      ["Tree House", "820 c"],
      ["Nellcôte", "833 w"],
      ["Nellcôte", "833 w"],
      ["Tom Bergin's", "840 s"],
      ["Tom Bergin's", "840 s"],
      ["Casey Moore's (duplicate)", "850 s"],
      ["Casey Moore's Oyster House", "850 s"],
      ["Whiskey's Smokehouse", "885 b"],
      ["Whiskey's Smokehouse", "885 b"],
      ["Brother Jimmy's BBQ Brickell", "900 s"],
      ["Brother Jimmy's Barbeque.", "900 s"],
      ["Brooklyn's At the Pepsi Center", "901 a"],
      ["Brooklyn's At the Pepsi Center", "901 a"],
      ["Morrissey's Irish Pub", "913 w"],
      ["Morrissey's Irish Pub", "913 w"],
      ["Plan B", "924 w"],
      ["Plan B", "924 w"],
      ["canon: whiskey and bitters emporium", "928 1"],
      ["canon: whiskey and bitters emporium", "928 1"],
      ["The News Room", "990 n"],
      ["The News Room", "990 n"],
      ["Ace's", "998 s"],
      ["Ace's", "998 s"],
      ["Republic National Distributing Company", "1010 "],
      ["Republic National Distributing Company", "1010 "],
      ["The London West Hollywood", "1020 "],
      ["The London West Hollywood", "1020 "],
      ["Hugo's Frog Bar & Fish House", "1024 "],
      ["Hugo's Frog Bar & Fish House", "1024 "],
      ["Artiface", "1025 "],
      ["Artifice", "1025 "],
      ["Carmine's", "1043 "],
      ["Carmine's", "1043 "],
      ["Cabo Cantina", "1050 "],
      ["Cabo Cantina", "1050 "],
      ["Eats Restaurant and Bar", "1055 "],
      ["Eats on Lex", "1055 "],
      ["Maddy's Taproom", "1100 "],
      ["Maddy's Taproom", "1100 "],
      ["Black Sheep", "1117 "],
      ["Black Sheep Bar & Grill (5515687)", "1117 "],
      ["Mike's Daiquiris & Grill", "1121 "],
      ["Mike's in Tigerland", "1121 "],
      ["Three Clubs", "1123 "],
      ["Three Clubs", "1123 "],
      ["La Descarga", "1159 "],
      ["La Descarga", "1159 "],
      ["R Bar", "1176 "],
      ["R Bar", "1176 "],
      ["Bank & Bourbon", "1200 "],
      ["Bank & Bourbon", "1200 "],
      ["The Up and Under Pub", "1216 "],
      ["The Up and Under Pub", "1216 "],
      ["Liq O Rama", "1228 "],
      ["Liq O Rama", "1228 "],
      ["Grafton Street", "1230 "],
      ["Grafton St", "1230 "],
      ["Sassafras Saloon", "1233 "],
      ["Sassafras", "1233 "],
      ["Bob's Steak & Chop House", "1255 "],
      ["Bob's Steak & Chop House", "1255 "],
      ["Jo-Cat's Pub", "1311 "],
      ["Jo-Cat's Pub", "1311 "],
      ["Semilla Eatery & Bar", "1330 "],
      ["Semilla Eatery & Bar", "1330 "],
      ["H Street Country Club", "1335 "],
      ["H Street Country Club", "1335 "],
      ["Tupelo", "1337 "],
      ["Tupelo", "1337 "],
      ["Villains Tavern", "1356 "],
      ["Villains Tavern", "1356 "],
      ["Grant & Green Saloon", "1371 "],
      ["Grant & Green Saloon", "1371 "],
      ["Hock Farm Craft & Provisions", "1415 "],
      ["Hock Farm Craft & Provisions", "1415 "],
      ["Sak's Sports Bar", "1460 "],
      ["Sak's Sports Bar", "1460 "],
      ["Lucky's Stout House", "1475 "],
      ["Luckys Stout House", "1475 "],
      ["The Violet Hour", "1520 "],
      ["The Violet Hour", "1520 "],
      ["The Woods", "1533 "],
      ["The Woods", "1533 "],
      ["Crocodile", "1540 "],
      ["Crocodile", "1540 "],
      ["1714 Highland Ave", "1714 "],
      ["1714 N Highland Ave", "1714 "],
      ["Surfcomber", "1717 "],
      ["Surfcomber Hotel South Beach, a Kimpton Hotel", "1717 "],
      ["Binny's Beverage Depot", "1720 "],
      ["Binny's Beverage Depot", "1720 "],
      ["The Brick Yard", "1787 "],
      ["The Brick Yard", "1787 "],
      ["Whisler's", "1814 "],
      ["Whisler's", "1814 "],
      ["School Yard Bar & Grill", "1815 "],
      ["School Yard Bar & Grill", "1815 "],
      ["Viceroy Santa Monica", "1819 "],
      ["Viceroy Santa Monica", "1819 "],
      ["Coventry Panini's Grill", "1825 "],
      ["Coventry Panini's Grill", "1825 "],
      ["Bus Stop", "1901 "],
      ["Bus Stop", "1901 "],
      ["Pour House", "1910 "],
      ["Pour House", "1910 "],
      ["Mickey Byrne's Irish Pub & Restaurant", "1921 "],
      ["Mickey Byrne's Irish Pub & Restaurant", "1921 "],
      ["Solly's", "1942 "],
      ["Solly's U St Tavern", "1942 "],
      ["Stanley's Kitchen & Tap", "1970 "],
      ["Stanley's Kitchen & Tap", "1970 "],
      ["Christian's Tailgate", "2000 "],
      ["Christian's Tailgate Bar & Grill", "2000 "],
      ["1 Tippling Place", "2006 "],
      ["1 Tippling Place", "2006 "],
      ["Q Street Bar & Grill", "2013 "],
      ["Q Street Bar & Grill", "2013 "],
      ["Liquor Lyle's", "2021 "],
      ["Liquor Lyle's", "2021 "],
      ["Stock in Trade", "2036 "],
      ["Stock in Trade", "2036 "],
      ["Black Sheep Lodge", "2108 "],
      ["Black Sheep Lodge", "2108 "],
      ["Fearing's Restaurant", "2121 "],
      ["Fearing's Restaurant", "2121 "],
      ["Little Dom's", "2128 "],
      ["Little Dom's", "2128 "],
      ["Halligan Bar", "2274 "],
      ["Halligan Bar", "2274 "],
      ["Hendoc's Pub", "2375 "],
      ["Hendoc's Pub", "2375 "],
      ["J. BLACK'S Feel Good Kitchen & Lounge", "2409 "],
      ["J. BLACK'S Feel Good Kitchen & Lounge", "2409 "],
      ["Madam's Organ", "2461 "],
      ["Madam's Organ", "2461 "],
      ["Nickel And Rye", "2523 "],
      ["Nickel And Rye", "2523 "],
      ["C C Club", "2600 "],
      ["C C Club", "2600 "],
      ["Campuzano Mexican Food", "2618 "],
      ["Campusanos", "2618 "],
      ["The Broken Shaker / Freehand", "2727 "],
      ["The Broken Shaker", "2727 "],
      ["The Lyndale Tap House", "2937 "],
      ["The Lyndale Tap House", "2937 "],
      ["6th Street Bar", "3005 "],
      ["6th Street Bar", "3005 "],
      ["Nick & Sam's", "3008 "],
      ["Nick & Sam's", "3008 "],
      ["Sapphire Gentlemen's Club", "3025 "],
      ["Sapphire Pool Parties", "3025 "],
      ["Sandbar Sports Grill", "3064 "],
      ["Sandbar Sports Grill", "3064 "],
      ["Encore At Wynn Las Vegas", "3121 "],
      ["Encore Beach Club", "3121 "],
      ["Brookland's Finest Bar and Kitchen", "3126 "],
      ["Brookland's Finest Bar and Kitchen", "3126 "],
      ["Kramer's", "3167 "],
      ["Kramer's", "3167 "],
      ["BARÚ Urbano Midtown", "3252 "],
      ["BARÚ Urbano", "3252 "],
      ["Remedy's Tavern", "3265 "],
      ["Remedy's Tavern", "3265 "],
      ["So & So's", "3309 "],
      ["So & So's", "3309 "],
      ["B&B Ristorante", "3355 "],
      ["B&B Ristorante", "3355 "],
      ["Pat's Tap", "3510 "],
      ["Pat's Tap", "3510 "],
      ["Taurus Beer and Whisk(e)y House", "3540 "],
      ["Taurus Another Round", "3540 "],
      ["Herbs and Rye", "3713 "],
      ["Herbs and Rye", "3713 "],
      ["ARIA Resort & Casino Las Vegas", "3730 "],
      ["ARIA Resort & Casino Las Vegas", "3730 "],
      ["RnR Restaurant and Bar", "3737 "],
      ["RnR Restaurant and Bar", "3737 "],
      ["Mandarin Oriental, Las Vegas", "3752 "],
      ["Mandarin Bar (inside Mandarin Oriental)", "3752 "],
      ["Ireland's 32", "3920 "],
      ["Ireland's 32", "3920 "],
      ["Rí Rá", "3930 "],
      ["Rí Rá Irish Pub", "3930 "],
      ["Delano Las Vegas", "3940 "],
      ["Delano Las Vegas", "3940 "],
      ["Interurban", "4057 "],
      ["Interurban", "4057 "],
      ["Tommy Rocker's", "4275 "],
      ["Tommy Rocker's", "4275 "],
      ["Liquor Barn", "4301 "],
      ["Liquor Barn", "4301 "],
      ["Monty Gaels", "4356 "],
      ["Monty Gaels", "4356 "],
      ["Kildare's Manayunk", "4417 "],
      ["Kildare's Manayunk", "4417 "],
      ["Sullivan's Steakhouse", "4608 "],
      ["Sullivan's Steakhouse", "4608 "],
      ["Total Wine-920 Millenia", "4625 "],
      ["Total Wine & More - Orlando (Millenia), FL", "4625 "],
      ["Sunshine Saloon", "5028 "],
      ["Sunshine Saloon", "5028 "],
      ["Gallagher's Irish Pub", "5046 "],
      ["Gallagher's Irish Pub", "5046 "],
      ["Dipiazza's", "5205 "],
      ["Dipiazza's", "5205 "],
      ["The Promontory", "5311 "],
      ["The Promontory", "5311 "],
      ["Effin's Pub & Grill", "6164 "],
      ["Effin's Pub & Grill", "6164 "],
      ["W Hollywood", "6250 "],
      ["W Hollywood", "6250 "],
      ["Felix's Pizza Pub", "6335 "],
      ["Felix's Dogtown", "6335 "],
      ["Writer's Room", "6685 "],
      ["Writer's Room", "6685 "],
      ["Rocky's 7440 Club", "7440 "],
      ["Rocky's 7440 Club", "7440 "],
      ["Looney's- Maple Lawn", "8180 "],
      ["Looney's Pub South @ Maple Lawn", "8180 "],
      ["Mel and Rose", "8344 "],
      ["Mel and Rose", "8344 "],
      ["A.O.C.", "8700 "],
      ["A.O.C.", "8700 "],
      ["Dominick's", "8715 "],
      ["Dominick's", "8715 "],
      ["Petit Ermitage", "8822 "],
      ["Petit Ermitage", "8822 "],
      ["Rock and Reilly's Irish Pub", "8911 "],
      ["Rock and Reilly's Irish Pub", "8911 "],
      ["Dan Tana's", "9071 "],
      ["Dan Tana's", "9071 "],
      ["University of California San Diego", "9500 "],
      ["University of California San Diego", "9500 "],
      ["Chulas Sport Cantina", "9501 "],
      ["Chula's SW", "9501 "],
      ["Third Base South Park Meadows", "9600 "],
      ["Third Base South Park Meadows", "9600 "],
      ["Khoury's Fine Wine & Spirits", "9915 "],
      ["Khoury's Fine Wine & Spirits", "9915 "],
      ["Timmy Nolan's Tavern and Grill", "10111"],
      ["Timmy Nolan's Tavern and Grill", "10111"],
      ["Chula's Sports Cantina (West)", "10516"],
      ["Chula's Sports Cantina", "10516"],
      ["Brion's Grille", "10621"],
      ["Brion's Grille", "10621"],
      ["Costco Vision Center", "11000"],
      ["Costco", "11000"],
      ["Lock & Key", "11033"],
      ["Lock & Key Social Drinkery", "11033"],
      ["Barú Urbano", "11402"],
      ["Barú Urbano", "11402"],
      ["Rocco's Tavern", "12514"],
      ["Rocco's Tavern", "12514"],
      ["Mahall's", "13200"],
      ["Mahall's", "13200"],
      ["Third Base", "13301"],
      ["Third Base", "13301"],
      ["Murph's", "14649"],
      ["Murph's", "14649"],
      ["Billiard Club", "15532"],
      ["Billiard Club", "15532"],
      ["Maguire's Restaurant", "17552"],
      ["Maguire's Restaurant", "17552"],
      ["Frank & Tony's Place", "38107"],
      ["Frank & Tony's Place", "38107"],
      ["Daytona", "dayto"],
      ["Daytona Beach", "dayto"],
      ["Downing Student Union", "downi"],
      ["Downing Student Union", "downi"],
      ["West Park Station", "west "],
      ["West Park Station", "west "],
    ]

    ActiveRecord::Base.logger = nil
    (0..list.count-1).step(2) do |n|
      place1 = Place.where('(substr(trim(leading \' \' from lower(street_number || \' \' || route)), 1, 5)=? OR substr(lower(formatted_address), 1, 5)=?) AND name ilike \'%'+list[n][0].gsub("'","''")+'%\'', list[n][1], list[n][1]).first
      place2 = Place.where.not(id: place1).where('(substr(trim(leading \' \' from lower(street_number || \' \' || route)), 1, 5)=? OR substr(lower(formatted_address), 1, 5)=?) AND name ilike \'%'+list[n+1][0].gsub("'","''")+'%\'', list[n+1][1], list[n+1][1]).first
      if place1 && place2
        place1, place2 = place2, place1 if place1.reference.nil? && place2.reference.present?
        place1, place2 = place2, place1 if place1.name.include?('INCORRECT') && !place2.name.include?('INCORRECT')

        unless place2.place_id.blank?
          puts "puts \"\\n\\n\\n--------------------\\n- Recreating #{place2.name}: [#{place2.id}]\""
          puts "if Place.where(id: #{place1.id}).any?"
          puts "  place = Place.find_by(id: #{place2.id})"
          puts "  place ||= Place.find_by(place_id: '#{place2.place_id}')"
          puts "  if place.present?"
          puts "    Place.find(#{place1.id}).merge(place)"
          puts "  else"
          puts "    place = Place.create!(#{place2.attributes.merge(do_not_connect_to_api: true, merged_with_place_id: place1.id).to_json.gsub!(':null',':nil')})"
          puts "  end"
          puts "elsif Place.where(id: #{place2.id}).any?"
          puts "  place = Place.find_by(id: #{place1.id})"
          puts "  place ||= Place.find_by(place_id: '#{place1.place_id}')"
          puts "  if place.present?"
          puts "    Place.find(#{place2.id}).merge(place)"
          puts "  else"
          puts "    place = Place.create!(#{place1.attributes.merge(do_not_connect_to_api: true, merged_with_place_id: place2.id).to_json.gsub!(':null',':nil')})"
          puts "  end"
          puts "end"
        end
      end
    end

  end

  desc 'Restore merged place'
  task restore_merged: :environment do
puts "\n\n\n--------------------\n- Recreating James Hoban's Irish Bar & Restaurant: [11885]"
if Place.where(id: 9993).any?
  place = Place.find_by(id: 11885)
  place ||= Place.find_by(place_id: 'ChIJ88R62se3t4kRNth8jnel2PQ')
  if place.present?
    Place.find(9993).merge(place)
  else
    place = Place.create!({"id":11885,"name":"James Hoban's Irish Bar \u0026 Restaurant","reference":"CpQBhgAAALOWCdqUBJPJk643sGH0JNA0JUNPJMfplFQcGC92VjVfNKBmic_mDCk3_u2wyghCyko5fCRv94i4IM0jD-lm5lIQYaoEsdPkniG1eV8lOaYqm4RBrb5a1JcW1jX5-XmY2zd4c3OibU59_5qvixqK0KV2s4WvQi2YeGIRrz-w8j_I7tpdmI_AzEVJWDVKXfLXyhIQjwHdO_YwE1SoPpZ8I4NndxoUGtrW32ffO8znVPBpOpWCcA16JFA","place_id":"ChIJ88R62se3t4kRNth8jnel2PQ","types":["bar","restaurant","food","establishment"],"formatted_address":"1 Dupont Circle Northwest, Washington, DC 20036, United States","street_number":"1","route":"Dupont Circle Northwest","zipcode":"20036","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-01-31T16:09:33.312-08:00","updated_at":"2015-01-31T16:09:33.312-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"1753623","location_id":538,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.044328 38.908983)","do_not_connect_to_api":true,"merged_with_place_id":9993})
  end
elsif Place.where(id: 11885).any?
  place = Place.find_by(id: 9993)
  place ||= Place.find_by(place_id: '09d34abb01800e42b1845586ce51c6d597051ae9')
  if place.present?
    Place.find(11885).merge(place)
  else
    place = Place.create!({"id":9993,"name":"James Hoban's Irish Bar \u0026 Restaurant","reference":"CpQBhwAAAL6bTZJoMdAFU5eYpJg07vyb6wMlYPLUutYZOZU7Jz23hz-9Eqv8WTzL5_pxQT7LO3gmCcmfVkR4cOH29LUb0NeieRO0whQjpAzyHCaiqTkzq_3-Wzbz5yvgvKPfs2hg3hUHF_IfnWNFpDI8TFQkI2EVGHolgRQxWnnots1fc5aYPhgGunaVXTs60ggCDziQiRIQ7OWWJNEU8nWinjpbbMNhsRoUhRMGAcqwtSsOfuKE58GJHSm6Ris","place_id":"09d34abb01800e42b1845586ce51c6d597051ae9","types":["bar","restaurant","food","establishment"],"formatted_address":"1 Dupont Cir NW, Washington, DC 20036, United States","street_number":"1","route":"Dupont Cir NW","zipcode":"20036","city":"Washington","state":"District of Columbia","country":"US","created_at":"2014-11-19T14:54:44.630-08:00","updated_at":"2014-11-19T14:54:44.630-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"1753623","location_id":1120,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.044328 38.908983)","do_not_connect_to_api":true,"merged_with_place_id":11885})
  end
end
puts "\n\n\n--------------------\n- Recreating Ferry Building Marketplace: [12087]"
if Place.where(id: 6716).any?
  place = Place.find_by(id: 12087)
  place ||= Place.find_by(place_id: 'ChIJWTGPjmaAhYARxz6l1hOj92w')
  if place.present?
    Place.find(6716).merge(place)
  else
    place = Place.create!({"id":12087,"name":"Ferry Building Marketplace","reference":"CoQBewAAAP5AP81PHHvvd-TZOR1-dv31ahdGc9Wz9sMHGWSb5yevPaG60Z1z7LIflQji1QWIj1kUCxzaUAtkMxcl2tG3C14MZPqkwVvmu4-cbNxhFfAq-B4dmU69pcLk1LzrguhHVYnPrMySvr9DTMuS9FkkMIjhW7lU7DDKhREAuoG8BtF4EhB1pB5kLp2d70CpW2pgMvniGhR5996YEO16Zn-MYIa_imlpYDqj5w","place_id":"ChIJWTGPjmaAhYARxz6l1hOj92w","types":["grocery_or_supermarket","food","store","establishment"],"formatted_address":"1 Ferry building, San Francisco, CA 94111, United States","street_number":"1","route":"Ferry building","zipcode":"94111","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-05T11:51:44.310-08:00","updated_at":"2015-02-18T11:01:33.580-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":35,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.393532 37.795555)","do_not_connect_to_api":true,"merged_with_place_id":6716})
  end
elsif Place.where(id: 12087).any?
  place = Place.find_by(id: 6716)
  place ||= Place.find_by(place_id: 'be85473026d6a963c2ed0fc9b82a92440eb2f25f')
  if place.present?
    Place.find(12087).merge(place)
  else
    place = Place.create!({"id":6716,"name":"Ferry Plaza Farmers Market","reference":"CoQBfQAAAErvFqHuhoVgJjRmJjlvOulGYvqTtxPTTZrbb9Y98-R2nZ98YdWMM6KSz0KSPKAMSQRhlrrj4f-kE7c5q5MXu4qGo0POAHXk3nlcNwD3JzXrRxYLFdt7tX6spbXzwR7babNVAMD_RBnDJiCVoV4pcD4_4UI8_y-sXUQzSFOqZKvTEhC2b-R8uLrkZYciOrtuJWiyGhTKP_fzXNGwG4aEgCJ54DfRrbmUAw","place_id":"be85473026d6a963c2ed0fc9b82a92440eb2f25f","types":["food","establishment"],"formatted_address":"1 Ferry Bldg Marketplace, San Francisco, CA, United States","street_number":"1","route":"Ferry Bldg Marketplace","zipcode":"94111","city":"San Francisco","state":"California","country":"US","created_at":"2014-05-23T02:15:25.381-07:00","updated_at":"2014-05-23T02:15:25.381-07:00","administrative_level_1":"CA","administrative_level_2":"San Francisco County","td_linx_code":nil,"location_id":878,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.393018 37.795197)","do_not_connect_to_api":true,"merged_with_place_id":12087})
  end
end
puts "\n\n\n--------------------\n- Recreating Sweet & Vicious: [12238]"
if Place.where(id: 1448).any?
  place = Place.find_by(id: 12238)
  place ||= Place.find_by(place_id: 'ChIJheD6G4ZZwokRDNlOOCNk810')
  if place.present?
    Place.find(1448).merge(place)
  else
    place = Place.create!({"id":12238,"name":"Sweet \u0026 Vicious","reference":"CoQBcQAAAD8UsyUybH-gFvEJtBI0xaBnqGx-ffltAtr-aU8lS6fEiBn2QlToRSA0_9J4lwGvInJB1PwrAlBvfD5vPyibL1Uflo2ZEBytdO4mI_X7hplKuNsNDI1d9_QOsHJZZkmqd4YJi1zSTYzRvVlO9S314-YZfUG7lULM1Iw0aUUysItlEhAKIfW7pGQyJvo5uNyvTGwdGhTluW-AB-CsyrMV8d3jkCTMKej-1A","place_id":"ChIJheD6G4ZZwokRDNlOOCNk810","types":["night_club","bar","establishment"],"formatted_address":"5 Spring Street, New York, NY 10012, United States","street_number":"5","route":"Spring Street","zipcode":"10012","city":"New York","state":"New York","country":"US","created_at":"2015-02-09T19:59:46.419-08:00","updated_at":"2015-02-18T10:58:00.736-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5096825","location_id":101,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.994278 40.721347)","do_not_connect_to_api":true,"merged_with_place_id":1448})
  end
elsif Place.where(id: 12238).any?
  place = Place.find_by(id: 1448)
  place ||= Place.find_by(place_id: '96187e2d9a14f73b7f0d32d71c7e67dbf4de14f3')
  if place.present?
    Place.find(12238).merge(place)
  else
    place = Place.create!({"id":1448,"name":"Sweet \u0026 Vicious","reference":"CoQBcQAAAIjzLexRbqNjxHX7YAPBx69-RGppVyT2Hj6AaOHq3wkWp__2Vaew46-T-g_01wH3YOvtjaWXO9PsWbQKkxpTC3WKorkchIP_9tcr-rgCUh_yHwKqAnQJhdSizNPKHSKqmqMHWkyR8NRBRXPOV_tAh2gkV34ddSTWIul1MwMUDE2dEhCtUDrZZWk9F9m6yaiIYGQYGhT6dl9WeMMJoCglz8tOimY5iyPleg","place_id":"96187e2d9a14f73b7f0d32d71c7e67dbf4de14f3","types":["night_club","bar","establishment"],"formatted_address":"5 Spring Street, New York, NY, United States","street_number":"5","route":"Spring Street","zipcode":"10012","city":"New York","state":"New York","country":"US","created_at":"2013-11-07T22:39:19.134-08:00","updated_at":"2015-02-01T22:03:08.349-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5096825","location_id":101,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.99434 40.721231)","do_not_connect_to_api":true,"merged_with_place_id":12238})
  end
end
puts "\n\n\n--------------------\n- Recreating Apothéke: [1893]"
if Place.where(id: 11898).any?
  place = Place.find_by(id: 1893)
  place ||= Place.find_by(place_id: '57102c0d98895f871799cce0d3c3cc70b5928167')
  if place.present?
    Place.find(11898).merge(place)
  else
    place = Place.create!({"id":1893,"name":"Apothéke","reference":"CnRqAAAAcW0TYpY4vh5P0olGc3dHvPTxR_FZ8wuPZiuTKLYh4jr7ZMF7XoiKGFTSn2NJNPiE4c5tRZvk5iQeqz4yOGEBm8if14FE5EKgaUh2aiH8JynvhGvDrRm-xw74zxU-k_VXvvkfFL9ncXa4cgbsTxISMxIQJMXJw2JfUfGemUuA6rk6HRoUArBno9aJwxo0ocNCmAy6WvXwP70","place_id":"57102c0d98895f871799cce0d3c3cc70b5928167","types":["night_club","bar","establishment"],"formatted_address":"9 Doyers Street #1, New York, NY, United States","street_number":"9","route":"Doyers Street","zipcode":"10013","city":"New York","state":"New York","country":"US","created_at":"2013-11-11T00:49:31.744-08:00","updated_at":"2014-02-17T20:12:57.288-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"2943593","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.998128 40.714375)","do_not_connect_to_api":true,"merged_with_place_id":11898})
  end
elsif Place.where(id: 1893).any?
  place = Place.find_by(id: 11898)
  place ||= Place.find_by(place_id: 'ChIJNxEu8SZawokRARkMLjXhyBY')
  if place.present?
    Place.find(1893).merge(place)
  else
    place = Place.create!({"id":11898,"name":"Apotheke","reference":"CnRqAAAAgNO158zGTQFt2_k-apT3yQMZzLWQWRqSbxn1iaQMHAWG15c4KvO2zjkOhvCs42EVAESTaZ6nBYX4l9snACyz2Pl9dMYSdEdkX1DvRwjsUts3FS0U_kiHVwTG_HBQI7AC7IZ4gobA3oGnq52nkh63kBIQ_xPPdxE7anpwFCrsbmJxNxoUarHhAcvTqr3DM11PZwqDqq8oKSE","place_id":"ChIJNxEu8SZawokRARkMLjXhyBY","types":["night_club","bar","establishment"],"formatted_address":"9 Doyers Street #1, New York, NY 10013, United States","street_number":"9","route":"Doyers Street","zipcode":"10013","city":"New York","state":"New York","country":"US","created_at":"2015-02-01T08:13:14.112-08:00","updated_at":"2015-02-01T08:13:14.112-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"2943593","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.998217 40.714368)","do_not_connect_to_api":true,"merged_with_place_id":1893})
  end
end
puts "\n\n\n--------------------\n- Recreating Kelly's Irish Times: [11886]"
if Place.where(id: 3918).any?
  place = Place.find_by(id: 11886)
  place ||= Place.find_by(place_id: 'ChIJs519Wye4t4kRVOtqWihWh64')
  if place.present?
    Place.find(3918).merge(place)
  else
    place = Place.create!({"id":11886,"name":"Kelly's Irish Times","reference":"CoQBdQAAAGZccXcVbMjD5bcrsBbll44Y6cXuGhnXczCFkUPK24ytaDWad5x1pJCpQvsM7fnFL94SzX9fGj7tPZzSGYvno3plY3F_co5ZczGBMsI8xuQFTUhXpCTfIgFjLcn88jaAXN-dd9nSORCTcFdJni57u3YbPb1b15MI7ucqnS9JBvxaEhCOV_2pES0lTApjAZQbtTjBGhQDcXbpteICdlt4FLAk0SajByo2pA","place_id":"ChIJs519Wye4t4kRVOtqWihWh64","types":["bar","restaurant","food","establishment"],"formatted_address":"14 F Street Northwest, Washington, DC 20001, United States","street_number":"14","route":"F Street Northwest","zipcode":"20001","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-01-31T16:17:37.643-08:00","updated_at":"2015-02-02T14:20:11.651-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"5139485","location_id":538,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.009794 38.897145)","do_not_connect_to_api":true,"merged_with_place_id":3918})
  end
elsif Place.where(id: 11886).any?
  place = Place.find_by(id: 3918)
  place ||= Place.find_by(place_id: '43736e7a955be289b5fb0079b86a2c0e24d4fa5d')
  if place.present?
    Place.find(11886).merge(place)
  else
    place = Place.create!({"id":3918,"name":"Kelly's Irish Times","reference":"CoQBdQAAADqqWkt7qiDWzgsqoxnuOH3gn4Hh35nilOiabzMzNAfMpSZ54KoLqOVhCUi1cuLHeJ8s91Sra2lZqq94KPk0aaWdpl8MQAy0qCE-PKhuJo2FMBJpMFO-nWvMOwfXMsFa3XKTSCp5JW9HReGElCvIPY1x69uakodQpd5Wdk-xhsVWEhC70n8FuOq0d8-dd4jdvbYvGhS_tMylUVVrgKVvij3QSlaNzTi8sg","place_id":"43736e7a955be289b5fb0079b86a2c0e24d4fa5d","types":["bar","restaurant","food","establishment"],"formatted_address":"14 F Street Northwest, Washington, DC, United States","street_number":"14","route":"F Street Northwest","zipcode":"20001","city":"Washington","state":"District of Columbia","country":"US","created_at":"2014-01-06T08:59:16.508-08:00","updated_at":"2015-01-26T11:12:27.445-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"5139485","location_id":538,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.009741 38.897199)","do_not_connect_to_api":true,"merged_with_place_id":11886})
  end
end
puts "\n\n\n--------------------\n- Recreating Clarke's at Faneuil Hall: [12165]"
if Place.where(id: 4238).any?
  place = Place.find_by(id: 12165)
  place ||= Place.find_by(place_id: 'ChIJjTbKeYZw44kRHxgOJhTfGPk')
  if place.present?
    Place.find(4238).merge(place)
  else
    place = Place.create!({"id":12165,"name":"Clarke's at Faneuil Hall","reference":"CoQBegAAADrHdq8EKQHJqhpKb5m8Je5ujSuUajvE3HnC2-hXanOqandX3bCpvPoeXh8ztSSItQLbSO6q9xXqM0UkXE9CcB4YTtqHWNwhg1g8-_vcDCz2OU-Q-8oD4q-n2NehuZ_W5KH6x1FI90hWRcPCgtdCSsBvOswVGUauWpNLyjilKGcgEhAnSTwK8pHccy9x7l_0ZCBsGhQRVmTtBh7bTsZU5jfPUQ05MiYjiQ","place_id":"ChIJjTbKeYZw44kRHxgOJhTfGPk","types":["bar","restaurant","food","establishment"],"formatted_address":"21 Merchants Row, Boston, MA 02109, United States","street_number":"21","route":"Merchants Row","zipcode":"02109","city":"Boston","state":"Massachusetts","country":"US","created_at":"2015-02-08T15:33:40.014-08:00","updated_at":"2015-02-18T11:01:17.443-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":nil,"location_id":93,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.055383 42.359434)","do_not_connect_to_api":true,"merged_with_place_id":4238})
  end
elsif Place.where(id: 12165).any?
  place = Place.find_by(id: 4238)
  place ||= Place.find_by(place_id: 'fcfbe98c955fe4229c52bd16d59e922a2c16b95b')
  if place.present?
    Place.find(12165).merge(place)
  else
    place = Place.create!({"id":4238,"name":"Clarke's at Faneuil Hall","reference":"CoQBewAAAOU_6AQxHwznq2Eh5JEWUnfoYem46R34DZsSaXpcpJ-irGjC5B7p0_GOPDEQEGz-BGWJHum1uS3cQmvZtF69wr9O6q6hg6-v6N82BOokwcbKWnFXGWjsLDDsiz_K0O096rVT2U9uRU4jGBZRlMQHH5luzFGPZ0mrueKHzStOgTuhEhAYsGv6FKLI50d5pLTQfS4DGhTt5EEfCwmKalqXaMXeEjRnPtLS2w","place_id":"fcfbe98c955fe4229c52bd16d59e922a2c16b95b","types":["bar","restaurant","food","establishment"],"formatted_address":"21 Merchants Row, Boston, MA, United States","street_number":"21","route":"Merchants Row","zipcode":"02109","city":"Boston","state":"Massachusetts","country":"US","created_at":"2014-01-27T11:17:57.526-08:00","updated_at":"2014-02-17T20:26:07.100-08:00","administrative_level_1":"MA","administrative_level_2":"Suffolk County","td_linx_code":"5068249","location_id":93,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.055515 42.359496)","do_not_connect_to_api":true,"merged_with_place_id":12165})
  end
end
puts "\n\n\n--------------------\n- Recreating Alma Nove: [11834]"
if Place.where(id: 9109).any?
  place = Place.find_by(id: 11834)
  place ||= Place.find_by(place_id: 'ChIJgSiZ5_Zj44kRHDybJV_Yau4')
  if place.present?
    Place.find(9109).merge(place)
  else
    place = Place.create!({"id":11834,"name":"Alma Nove","reference":"CnRrAAAAPbGrLfmIlOBdYDVK7gxrqMSNOhSY7IPbcmP4DBO4zx-_XCOqETDUruoAeAu2PfMkVeQ1-CG-9ud6jnsEzPLEwiK6gw85KxgJbqBvs_SgpS7qu5dGgKVTfRYoW9vACxs7UlMsePTvC-6vi0PNzCgCdRIQob5xaebfVqL3-qYlUg7zHxoUV6mBZOn5k8ziAKTzmtbU7Iaf6jc","place_id":"ChIJgSiZ5_Zj44kRHDybJV_Yau4","types":["bar","restaurant","food","establishment"],"formatted_address":"22 Shipyard Drive, Hingham, MA 02043, United States","street_number":"22","route":"Shipyard Drive","zipcode":"02043","city":"Hingham","state":"Massachusetts","country":"US","created_at":"2015-01-30T11:07:17.181-08:00","updated_at":"2015-01-30T11:07:17.181-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":"3767562","location_id":167,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-70.922024 42.25241)","do_not_connect_to_api":true,"merged_with_place_id":9109})
  end
elsif Place.where(id: 11834).any?
  place = Place.find_by(id: 9109)
  place ||= Place.find_by(place_id: '7fbdf91988caf91fa425931626fff6d910bf0c94')
  if place.present?
    Place.find(11834).merge(place)
  else
    place = Place.create!({"id":9109,"name":"Alma Nove","reference":"CnRrAAAAE6ZsAh2mC6AkLnQb5xRkCiz4_VJIokayhqS8uaWjlSUL-jMJKLaxLpj1TO-UU0_J5V6qlm0MxvToJr2wXjYY2DYmTAgNazCXd0rPPyaQRAYwYOJXxsg7-pUofNUWUZrioWlEs-R0sopLBltGmabJIRIQgH9UY_Myh1WU1dlv1ZYaLBoUIqg0llfRkWT8c0cUTGYdP0hMApM","place_id":"7fbdf91988caf91fa425931626fff6d910bf0c94","types":["bar","restaurant","food","establishment"],"formatted_address":"22 Shipyard Dr, Hingham, MA 02043, United States","street_number":"22","route":"Shipyard Dr","zipcode":"02043","city":"Hingham","state":"Massachusetts","country":"US","created_at":"2014-10-21T17:12:55.245-07:00","updated_at":"2014-10-21T17:12:55.245-07:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":"3767562","location_id":167,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-70.922024 42.25241)","do_not_connect_to_api":true,"merged_with_place_id":11834})
  end
end
puts "\n\n\n--------------------\n- Recreating M J O'Connor's: [12166]"
if Place.where(id: 1185).any?
  place = Place.find_by(id: 12166)
  place ||= Place.find_by(place_id: 'ChIJx3HrOXR644kRX-ITHrA0ulQ')
  if place.present?
    Place.find(1185).merge(place)
  else
    place = Place.create!({"id":12166,"name":"M J O'Connor's","reference":"CnRvAAAAquXo3zFpNItkHh9_BuFyWCiXZcr1FHmeqyIHDkj5P69GGMx1Pcd9o0qSj52HbANZhrRGo4CqliVmTHtCHLuSKCHEdzaKEM8n481psJwRCm21_NIgOEoZE058og2r4v6moDlek-Hiakvj-n2rZOfVABIQSlxhGCcCVf-C_wUjyXzFWRoUS38nuojcw3PyCkg8RLFgamU9ijg","place_id":"ChIJx3HrOXR644kRX-ITHrA0ulQ","types":["bar","restaurant","food","establishment"],"formatted_address":"27 Columbus Avenue, Boston, MA 02116, United States","street_number":"27","route":"Columbus Avenue","zipcode":"02116","city":"Boston","state":"Massachusetts","country":"US","created_at":"2015-02-08T15:42:49.000-08:00","updated_at":"2015-02-18T11:01:17.223-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":"5122069","location_id":93,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.068968 42.35117)","do_not_connect_to_api":true,"merged_with_place_id":1185})
  end
elsif Place.where(id: 12166).any?
  place = Place.find_by(id: 1185)
  place ||= Place.find_by(place_id: 'e5f2f7861e446b5ee4adbf80358d853f91e2cc6e')
  if place.present?
    Place.find(12166).merge(place)
  else
    place = Place.create!({"id":1185,"name":"M J O'Connor's","reference":"CnRnAAAADi-cEyOFBDGd36V2vyqckmwDsq32cQurOuAku-nWwVfV0jukkxofZxh4FJhG-8ReirOGJZuGstoCvdaNhnXPY74qlzChWi-Ym4hrcF3i94LoXKRT3-3uo0lq7KslgnI86y6dx8xLVE-ZF4oafCNsShIQRzYuCloIUhn6eMG9rw8hlxoUEVIDHj_-q5FTKO6md4CC_ji2wHM","place_id":"e5f2f7861e446b5ee4adbf80358d853f91e2cc6e","types":["bar","restaurant","food","establishment"],"formatted_address":"27 Columbus Avenue, Boston, MA, United States","street_number":"27","route":"Columbus Avenue","zipcode":"02116","city":"Boston","state":"Massachusetts","country":"US","created_at":"2013-10-17T17:35:15.520-07:00","updated_at":"2015-02-23T12:27:10.740-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":"5122069","location_id":93,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.068897 42.35115)","do_not_connect_to_api":true,"merged_with_place_id":12166})
  end
end
puts "\n\n\n--------------------\n- Recreating The Draft: [1191]"
if Place.where(id: 6991).any?
  place = Place.find_by(id: 1191)
  place ||= Place.find_by(place_id: '2f124f09896b2b016dca6aef7d230cfc3c7d5d84')
  if place.present?
    Place.find(6991).merge(place)
  else
    place = Place.create!({"id":1191,"name":"The Draft","reference":"CnRjAAAA2JENFe2IhlBTEg6tsDH6HLYUZzuC9GDfdUJglsgqB6uyFcZIpdnF2N4NURzx2hxwrWWoVn39cSQ3sXwoc4kIflsmJJQuUY7hPOx_aJgCwhLK5bRZjI3Hj_vd8-RfVzKpM6LUHxvU3i08KdewLDnY7hIQ9ijPUQg7H8A1x2ID7y84whoUfY8QJTPjtkUXj6E2ZHozpzTDCAM","place_id":"2f124f09896b2b016dca6aef7d230cfc3c7d5d84","types":["establishment"],"formatted_address":"34 Harvard Avenue, Boston, MA, United States","street_number":"34 Harvard Avenue","route":"","zipcode":"02134","city":"Boston","state":"Massachusetts","country":"US","created_at":"2013-10-17T17:49:23.315-07:00","updated_at":"2014-02-17T20:08:49.008-08:00","administrative_level_1":"MA","administrative_level_2":"Suffolk County","td_linx_code":"5100287","location_id":93,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.132487 42.35484)","do_not_connect_to_api":true,"merged_with_place_id":6991})
  end
elsif Place.where(id: 1191).any?
  place = Place.find_by(id: 6991)
  place ||= Place.find_by(place_id: '8f299e13f3bb4eb5f8541bdc0e3b05c180bf5c0c')
  if place.present?
    Place.find(1191).merge(place)
  else
    place = Place.create!({"id":6991,"name":"The Draft Bar and Grille","reference":"CoQBegAAALRaDlpuDDbhx3y3psVaPMdyFrIz8QsLWJXv1Be3JrA6zu--x9RgslaGEnpgJYFJB7o14qX71bkF-kuF_16IQuqrX3iVGfrhEXYo-m6brqgUMY6nPeC23pMBB_yLE7zQkdEbK89f6Z1J3yDpB0ia_2DqE0eGj8EPNJOVs_XqS-m-EhBqEdCqps--Gv8BBF9ADxLqGhRTfu032u03g_nz1H2EA7sdk6qXHQ","place_id":"8f299e13f3bb4eb5f8541bdc0e3b05c180bf5c0c","types":["bar","restaurant","food","establishment"],"formatted_address":"34 Harvard Ave, Allston, MA, United States","street_number":"34","route":"Harvard Ave","zipcode":"02134","city":"Boston","state":"Massachusetts","country":"US","created_at":"2014-06-09T11:59:45.394-07:00","updated_at":"2014-06-09T11:59:45.394-07:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":nil,"location_id":157,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.132488 42.354845)","do_not_connect_to_api":true,"merged_with_place_id":1191})
  end
end
puts "\n\n\n--------------------\n- Recreating McLadden's Irish Publick House: [12046]"
if Place.where(id: 8459).any?
  place = Place.find_by(id: 12046)
  place ||= Place.find_by(place_id: 'ChIJJTcq8u2s54kRDp5xwIS0QuE')
  if place.present?
    Place.find(8459).merge(place)
  else
    place = Place.create!({"id":12046,"name":"McLadden's Irish Publick House","reference":"CoQBgAAAAIaiVmonApjzdmZ7fjPww8KmfWjujmYpGblxuZK6mD0dSEod2Vwm3eAMTSV70PQ7NsnNIq1npNOxov5Gtp0UTNqf3Y-tOtTeX8zTsRfzsfcAK8GcjTveMD_jkOpb3cJ86MHT-8NrZi4MAQVARVEgS1OhHn8k32Wf11IcWFOzHTcCEhDPXs3LaFR9by5ToM9swGtFGhT5TFD3lZ0sOr2K1YvA7Hm2Za5H-A","place_id":"ChIJJTcq8u2s54kRDp5xwIS0QuE","types":["bar","restaurant","food","establishment"],"formatted_address":"37 LaSalle Road, West Hartford, CT 06107, United States","street_number":"37","route":"LaSalle Road","zipcode":"06107","city":"West Hartford","state":"Connecticut","country":"US","created_at":"2015-02-05T07:12:08.885-08:00","updated_at":"2015-02-05T07:12:08.885-08:00","administrative_level_1":"CT","administrative_level_2":nil,"td_linx_code":nil,"location_id":1556,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-72.744609 41.759996)","do_not_connect_to_api":true,"merged_with_place_id":8459})
  end
elsif Place.where(id: 12046).any?
  place = Place.find_by(id: 8459)
  place ||= Place.find_by(place_id: 'e3162ee26322a40bbc23d88a56950066112e1668')
  if place.present?
    Place.find(12046).merge(place)
  else
    place = Place.create!({"id":8459,"name":"McLadden's Irish Publick House","reference":"CoQBgAAAAIEI3reT0rvZzjRk1fMkufQOX0KLHr6h2ec3bEHeb-JG5ZeUp6MlF2vPQt-7M1_SVPiidylbi4xnY2RhBPjg2-Yp5q_7Qw92i36wGhuXVxu0ZYLFFxqO3HCiKyLZYnDpnWzqwID4O6kIjvrVNSWjaIdV4aDq-T5T9BMwEymnqry1EhCXg-8uS1WK4rdPnKO5LVt1GhQuYAf8tfZZvDgfZlYY93Z5B3DKhQ","place_id":"e3162ee26322a40bbc23d88a56950066112e1668","types":["bar","restaurant","food","establishment"],"formatted_address":"37 LaSalle Rd, West Hartford, CT, United States","street_number":"37","route":"LaSalle Rd","zipcode":"06107","city":"West Hartford","state":"Connecticut","country":"US","created_at":"2014-09-29T19:46:45.701-07:00","updated_at":"2014-09-29T19:46:45.701-07:00","administrative_level_1":"CT","administrative_level_2":"Hartford County","td_linx_code":nil,"location_id":1556,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-72.744802 41.760233)","do_not_connect_to_api":true,"merged_with_place_id":12046})
  end
end
puts "\n\n\n--------------------\n- Recreating Quality Meats: [3383]"
if Place.where(id: 10070).any?
  place = Place.find_by(id: 3383)
  place ||= Place.find_by(place_id: '38e93b243543adeef14b29f76eecac52aec529f7')
  if place.present?
    Place.find(10070).merge(place)
  else
    place = Place.create!({"id":3383,"name":"Quality Meats","reference":"CnRvAAAAs-j3IiYlUONmvg_6VstaHIgBNhJuv2yWyiRWntvw2vVCpxjGB-B3s87yl6GsCeq4GnjuY_weXwosHuxm-pJ0sS47Q6kA7vWfS56iWDcGfEUGloRorrrJAddM9pYC2emtDu-5O9t-g4cPDzw41932exIQWszNoIgNsiZucyIzv0Zp0hoUT02Ttr-og4T7O8vNUzFpLVw1Z9k","place_id":"38e93b243543adeef14b29f76eecac52aec529f7","types":["restaurant","food","establishment"],"formatted_address":"57 West 58th St, New York, NY, United States","street_number":"57","route":"West 58th St","zipcode":"10019","city":"New York","state":"New York","country":"US","created_at":"2013-12-06T10:41:52.053-08:00","updated_at":"2014-02-17T20:21:00.502-08:00","administrative_level_1":"NY","administrative_level_2":"New York County","td_linx_code":"5089846","location_id":347,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.976301 40.764885)","do_not_connect_to_api":true,"merged_with_place_id":10070})
  end
elsif Place.where(id: 3383).any?
  place = Place.find_by(id: 10070)
  place ||= Place.find_by(place_id: 'c06f9ad2302b773f63f5bfec6bfe1c94153176e8')
  if place.present?
    Place.find(3383).merge(place)
  else
    place = Place.create!({"id":10070,"name":"Quality Italian","reference":"CoQBcQAAAGjCf49cHoPnH5k4JD6zqoRLfLyoZFzTdJUUOlLkBSJ8D2LrQhVGTZK8i1WEV2J1n-XKyVzKbdKcjuHe2-c-OX4-2Uv0FefxFlYtTCCyuzYQ1ZO-UcO5F2r0c_8dl6yMVuG-kMCXwpj9833UPN3ioAV-JkULcF2b3MxZvgnt-6QUEhC7j5yC2sBvg2vc8Pi-OBonGhQBF89fC2r2Xut_6updl3o6vvOa-g","place_id":"c06f9ad2302b773f63f5bfec6bfe1c94153176e8","types":["bar","restaurant","food","establishment"],"formatted_address":"57 West 57th Street, Entrance on Sixth Avenue, New York, NY 10019, United States","street_number":nil,"route":nil,"zipcode":"10019","city":"New York","state":"New York","country":"US","created_at":"2014-11-24T11:09:28.854-08:00","updated_at":"2014-11-24T11:09:28.854-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":nil,"location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.97679 40.764528)","do_not_connect_to_api":true,"merged_with_place_id":3383})
  end
end
puts "\n\n\n--------------------\n- Recreating Mr. Dooley's Boston: [12442]"
if Place.where(id: 9639).any?
  place = Place.find_by(id: 12442)
  place ||= Place.find_by(place_id: 'ChIJqS-U6IZw44kR1E7QGX8PuEw')
  if place.present?
    Place.find(9639).merge(place)
  else
    place = Place.create!({"id":12442,"name":"Mr. Dooley's Boston","reference":"CnRmAAAA9aj8mLBoHqW0jL3Czow_b7hVnbY9zUqNvbw4hR2y8CDrKcTmDPDXyLORRJQkV2Dn04I6EJdaHLzuGTlxUYUMDKKrR7kg1kEwNSkiKCVXnMD6dK-CQeOnDN4e7GghvyB3aj3nF6zOc8FIAHQjUNB_vRIQA4e3C_h8Y8FzC--I_KKWsBoUtoPznSNeCFEhE42dnMApkzbZuDM","place_id":"ChIJqS-U6IZw44kR1E7QGX8PuEw","types":["bar","restaurant","food","establishment"],"formatted_address":"77 Broad Street, Boston, MA 02109, United States","street_number":"77","route":"Broad Street","zipcode":"02109","city":"Boston","state":"Massachusetts","country":"US","created_at":"2015-02-18T09:40:16.091-08:00","updated_at":"2015-02-18T10:54:33.715-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":nil,"location_id":93,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.053647 42.357639)","do_not_connect_to_api":true,"merged_with_place_id":9639})
  end
elsif Place.where(id: 12442).any?
  place = Place.find_by(id: 9639)
  place ||= Place.find_by(place_id: 'b33bf15cb82f7aad97f2d6e6723072027f8f4348')
  if place.present?
    Place.find(12442).merge(place)
  else
    place = Place.create!({"id":9639,"name":"Mr. Dooley's Boston","reference":"CoQBdAAAAJ8hy1sfRE5eLV6aZ_5c_nipk8uBocn4avymy6i1Amm4obFGvPCXwbJwkOLZCEWzCoVHpbSS7_2-BJNdQ5hjICESp0yT4XLSZHmZTNwxqOWR8TDkZRKTMifosVfTkhlU_mF20SZezjnl_-wzRLcUAAXKJgDn8WhE1B67ihwSR3kZEhCDdDDJmndLYJ87LK6x2GztGhRnBTX3ltGwbcU7YfeRYKz9s0zW7w","place_id":"b33bf15cb82f7aad97f2d6e6723072027f8f4348","types":["restaurant","food","establishment"],"formatted_address":"77 Broad St, Boston, MA 02109, United States","street_number":"77","route":"Broad St","zipcode":"02109","city":"Boston","state":"Massachusetts","country":"US","created_at":"2014-11-06T13:44:05.944-08:00","updated_at":"2014-11-06T13:44:05.944-08:00","administrative_level_1":"MA","administrative_level_2":"Suffolk County","td_linx_code":"5068973","location_id":93,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.053647 42.357639)","do_not_connect_to_api":true,"merged_with_place_id":12442})
  end
end
puts "\n\n\n--------------------\n- Recreating Jig and Reel: [12161]"
if Place.where(id: 9563).any?
  place = Place.find_by(id: 12161)
  place ||= Place.find_by(place_id: 'ChIJhVwDBs8XXIgR9Cu0UfpNsFc')
  if place.present?
    Place.find(9563).merge(place)
  else
    place = Place.create!({"id":12161,"name":"Jig and Reel","reference":"CnRtAAAA-LBexy7cpwQKcqagHfM7b33ewKxhMoC8tJFRwS7A9YAYtDwpWUp5zhNHxsezO4MpUki6XydmmfGA4JDWxLfM-ygnwJxzfmsHvvgBjN14gwcgMbO9CdidiQt_aUnJjlo8aJYSZmV-Q9RXQ94HVznLZBIQUxKcvv5nyyaGRh2du4AHNRoUFV8KFvhkdJyN2z0wUo-yujcKyQg","place_id":"ChIJhVwDBs8XXIgR9Cu0UfpNsFc","types":["bar","restaurant","food","establishment"],"formatted_address":"101 South Central Street, Knoxville, TN 37902, United States","street_number":"101","route":"South Central Street","zipcode":"37902","city":"Knoxville","state":"Tennessee","country":"US","created_at":"2015-02-07T19:28:53.291-08:00","updated_at":"2015-02-18T11:01:18.001-08:00","administrative_level_1":"TN","administrative_level_2":nil,"td_linx_code":nil,"location_id":2018,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.918587 35.9702)","do_not_connect_to_api":true,"merged_with_place_id":9563})
  end
elsif Place.where(id: 12161).any?
  place = Place.find_by(id: 9563)
  place ||= Place.find_by(place_id: '75cc3a96db3186ca17d03d5e76c0420209d1f970')
  if place.present?
    Place.find(12161).merge(place)
  else
    place = Place.create!({"id":9563,"name":"Jig and Reel","reference":"CnRtAAAA2818cFyRm91eSBlRBqOMiDhglnlq7hz3H_IV8iYDVZvTfXjbJlRDf3nUHir_Ru-tU-HeBp5oNpvXy2Y-o9LxDWgFd2s_4iLp1-wB98tTbZucuRiwa2-fYwkNtJekrdrjB6X66yoXFtMH-TnxncJ_hxIQgbg01M8oujFn3PWOTy4gURoUbcyK4CxuysZyu5voxaMkiARH8L8","place_id":"75cc3a96db3186ca17d03d5e76c0420209d1f970","types":["bar","restaurant","food","establishment"],"formatted_address":"101 S Central St, Knoxville, TN 37902, United States","street_number":"101","route":"S Central St","zipcode":"37902","city":"Knoxville","state":"Tennessee","country":"US","created_at":"2014-11-04T12:21:10.444-08:00","updated_at":"2014-11-04T12:21:10.444-08:00","administrative_level_1":"TN","administrative_level_2":nil,"td_linx_code":nil,"location_id":2018,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.918587 35.9702)","do_not_connect_to_api":true,"merged_with_place_id":12161})
  end
end
puts "\n\n\n--------------------\n- Recreating Cooper's Union: [10653]"
if Place.where(id: 3376).any?
  place = Place.find_by(id: 10653)
  place ||= Place.find_by(place_id: '6ac2e71fea361f790adb1669270a0fb77cfffea7')
  if place.present?
    Place.find(3376).merge(place)
  else
    place = Place.create!({"id":10653,"name":"Cooper's Union","reference":"CoQBeQAAAEl9iPVg4XXQBGkV9DxzaY4bksLL8woDv7gInSTCqpQIduSuZQ0uWJ4hr8nTlkecsu21IBxG6FDa00HhuCbwymj3AScQR2sxpbCN-Er5q2ajkCtfFnIERvbCSqzNqD1MOJD7hWisLUtaR1p2Av6MWgq30GbZnTR-k1MLo59cXzHgEhBdUdHf5Z0wxRuUQAB1hELiGhS4mm3m7xTkd3HdOaoD2_6V6VX_kg","place_id":"6ac2e71fea361f790adb1669270a0fb77cfffea7","types":["bar","point_of_interest","establishment"],"formatted_address":"Cooper's Union, 104 Hudson St, Hoboken, NJ 07030, USA","street_number":"104","route":"Hudson St","zipcode":"07030","city":"Hoboken","state":"New Jersey","country":"US","created_at":"2014-12-07T16:32:02.792-08:00","updated_at":"2015-02-11T13:34:05.630-08:00","administrative_level_1":"NJ","administrative_level_2":"Hudson County","td_linx_code":"5097761","location_id":835,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.0301165 40.7375518)","do_not_connect_to_api":true,"merged_with_place_id":3376})
  end
elsif Place.where(id: 10653).any?
  place = Place.find_by(id: 3376)
  place ||= Place.find_by(place_id: 'c05cafc372fa24cc0b9bd31046e69d930737c61b')
  if place.present?
    Place.find(10653).merge(place)
  else
    place = Place.create!({"id":3376,"name":"Cooper's Union","reference":"CnRwAAAAiXkGTyJsFWcXkLxWkdbRG289nXDafXQLBS65e6XArthSWwgmKveOjakbpdLu3wjxz8oZ5voIKO613ATf10SkPR3KXGjg2RYz8_FRRk0PBJu4lhxtM_r5h5yj5tv_x0JBEz8Di9qmTDBe8rGhQV564RIQCQDLwZzkXJwVVzxJSrl3JxoUGPsCYOC9xzlFM6EO6EEAkAOXC_g","place_id":"c05cafc372fa24cc0b9bd31046e69d930737c61b","types":["bar","establishment"],"formatted_address":"104 Hudson Street, Hoboken, NJ, United States","street_number":"104","route":"Hudson Street","zipcode":"07030","city":"Hoboken","state":"New Jersey","country":"US","created_at":"2013-12-06T08:41:05.077-08:00","updated_at":"2015-02-11T13:33:56.128-08:00","administrative_level_1":"NJ","administrative_level_2":"Hudson County","td_linx_code":"5097761","location_id":835,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.029961 40.73752)","do_not_connect_to_api":true,"merged_with_place_id":10653})
  end
end
puts "\n\n\n--------------------\n- Recreating Cole's: [11263]"
if Place.where(id: 1336).any?
  place = Place.find_by(id: 11263)
  place ||= Place.find_by(place_id: 'bd2c080550ef6f41e68d6f5bac205f916c62c855')
  if place.present?
    Place.find(1336).merge(place)
  else
    place = Place.create!({"id":11263,"name":"Cole's","reference":"CoQBcgAAAKvg0zjph2wySvUY-837apFPJOVOkThptPnpflzzRt9ciLEMUC2TVh77iiWE6Mw55edsIbQysRimykk6-YALLPxIMTdRLtjtidlXBS6cS5zJPa3cHogX5ijEySpmT-tzWKShhGO7ylay7MnJUq8C8qCe7xEOerPsB8JOZZ3wcsDKEhB0jkWKLlN76GW6R-HOdoSnGhRAOuuR8x3HeOdPSArMRMSWioM3jA","place_id":"bd2c080550ef6f41e68d6f5bac205f916c62c855","types":["restaurant","food","point_of_interest","establishment"],"formatted_address":"Cole's, 118 E 6th St, Los Angeles, CA 90014, USA","street_number":"118","route":"E 6th St","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-09T08:51:53.949-08:00","updated_at":"2015-01-09T08:51:53.949-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"5504587","location_id":1195,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.2495838 34.0447998)","do_not_connect_to_api":true,"merged_with_place_id":1336})
  end
elsif Place.where(id: 11263).any?
  place = Place.find_by(id: 1336)
  place ||= Place.find_by(place_id: 'c5e8726dfd58fee0bee1aa185408bfdeba754afe')
  if place.present?
    Place.find(11263).merge(place)
  else
    place = Place.create!({"id":1336,"name":"Cole's","reference":"CnRoAAAAoYEUSLy6yjoxd9jDzK9BJdgLs_phlN4W7Bi3dF236Hb4b_d0O4kXpD1sC0lb4IiMN_Zk8t0z8em1jrHTihRmNU-Su2-XE4QS5ZBTLv8EYA6865WGLguBdESAugh4rbpNRz5k8-03lPcDNNIL_zaSJBIQmtFcEzrBUgjVODu9U81-LBoULBkOJnD7bkbL9x2xL9Z1nWhPHjo","place_id":"c5e8726dfd58fee0bee1aa185408bfdeba754afe","types":["meal_takeaway","restaurant","food","establishment"],"formatted_address":"118 East 6th Street, Los Angeles, CA, United States","street_number":"118","route":"East 6th Street","zipcode":"90013","city":"Los Angeles","state":"California","country":"US","created_at":"2013-11-03T13:20:11.200-08:00","updated_at":"2014-02-17T20:09:34.585-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles","td_linx_code":"5504587","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.249546 34.044852)","do_not_connect_to_api":true,"merged_with_place_id":11263})
  end
end
puts "\n\n\n--------------------\n- Recreating Kirby's Steakhouse: [11951]"
if Place.where(id: 6261).any?
  place = Place.find_by(id: 11951)
  place ||= Place.find_by(place_id: 'ChIJR9qm5gFiXIYRWRbwtBiPjQw')
  if place.present?
    Place.find(6261).merge(place)
  else
    place = Place.create!({"id":11951,"name":"Kirby's Steakhouse","reference":"CoQBcwAAANgBNruY1JufvYMI0ilC6OoksIAgeL10UcfFeNsgg1UyuxhUwJeIhT2PabNIo5It5WpD-7mq2uyhHwUBrWppbPSFzThpVVAP1m0CGFjPyLpvrR6RS2vaUu8VPQXHI5ZoQAFTKlqv_o8VC8_ceSPAhXB4zfjDaEANvdXgx9Lxx5eTEhC1iKOwchjwRF7NmT8-0iUBGhTRNalVMfL3UzNWEoW04VVTAOZm8g","place_id":"ChIJR9qm5gFiXIYRWRbwtBiPjQw","types":["restaurant","food","establishment"],"formatted_address":"123 Loop 1604 NE, San Antonio, TX 78232, United States","street_number":"123 Loop","route":"1604 NE","zipcode":"78232","city":"San Antonio","state":"Texas","country":"US","created_at":"2015-02-02T14:40:02.414-08:00","updated_at":"2015-02-02T14:40:02.414-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2262892","location_id":745,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-98.488494 29.609674)","do_not_connect_to_api":true,"merged_with_place_id":6261})
  end
elsif Place.where(id: 11951).any?
  place = Place.find_by(id: 6261)
  place ||= Place.find_by(place_id: '93d5e0ff7119e7158ab030e2c6e0e83eac1ff4ff')
  if place.present?
    Place.find(11951).merge(place)
  else
    place = Place.create!({"id":6261,"name":"Kirby's Steakhouse","reference":"CoQBcwAAAJnaitMChGfaoZ60YSmwAXj-hExltBc9RHHDSVLYJ_XMHU3oQvALRPE264VFyJMgZFFtOcu81KgcNUYZ7N4FBHENSbfgD_PTkfUwlp4gwIQDjn8lRkkNPOAzEsycxyH9xJvHxtKLAxrl5EmlmebvVdRnABXYdlbKaX_NUu1Z2SIsEhAJUFv4p7ffl_JL7b2oikfYGhQglltopmMCpVuBlHn3FjHRfhRo3Q","place_id":"93d5e0ff7119e7158ab030e2c6e0e83eac1ff4ff","types":["restaurant","food","establishment"],"formatted_address":"123 Loop 1604 NE, San Antonio, TX, United States","street_number":"123 Loop","route":"1604 NE","zipcode":"78232","city":"San Antonio","state":"Texas","country":"US","created_at":"2014-04-28T10:34:19.083-07:00","updated_at":"2014-04-28T10:34:19.083-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2262892","location_id":745,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-98.488494 29.609674)","do_not_connect_to_api":true,"merged_with_place_id":11951})
  end
end
puts "\n\n\n--------------------\n- Recreating Binion's: [12240]"
if Place.where(id: 8968).any?
  place = Place.find_by(id: 12240)
  place ||= Place.find_by(place_id: 'ChIJm0UnxgrDyIARFK_velkJ0uU')
  if place.present?
    Place.find(8968).merge(place)
  else
    place = Place.create!({"id":12240,"name":"Binion's","reference":"CnRqAAAA_961mCTnJatbQg2gCIq1k8zC8YFH4qjf1_Fz-dUlkbENUAOrRQqy7qCjReyLAQ6-GpFNCAEo0DyzsV0jmGUquVAeyajg1NBYrziu3eOq5LF3MRCLR2bSrNla2V5Wccmh6xxfT-5nI7365q9jkr5VExIQsk_uwh6WcGeYkNMn25xvIRoUbtyXFaFdIm44xo8rKDKFyYcvo4E","place_id":"ChIJm0UnxgrDyIARFK_velkJ0uU","types":["casino","establishment"],"formatted_address":"128 Fremont Street, Las Vegas, NV 89101, United States","street_number":"128","route":"Fremont Street","zipcode":"89101","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-02-09T21:55:46.437-08:00","updated_at":"2015-02-18T10:58:00.342-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.14426 36.171546)","do_not_connect_to_api":true,"merged_with_place_id":8968})
  end
elsif Place.where(id: 12240).any?
  place = Place.find_by(id: 8968)
  place ||= Place.find_by(place_id: '946fa4b2c1cb037cc3a92ea088847290d422c22e')
  if place.present?
    Place.find(12240).merge(place)
  else
    place = Place.create!({"id":8968,"name":"Binion's Gambling Hall \u0026 Hotel","reference":"CoQBgAAAAGd2GQUSJfBTGOuy-IYZusddYvBTaLtBNbPpn9vfoIDLBSzusXx3v-szmZmJj7TZa_7lqSb0OSQONPZxqANWOaZU5xFHswqyOpyzj3pyGMAIGEOt4yWSXzA2dP34gS5OP1L5NT0KMcP7zGiERCUHFvqS7RYfSUN2bqgwMI5Z9uF4EhA7Af9A1yXfmnhYxxZZtR8GGhT5S9KTWg3c0XzMTOdn4AfWqy1Tmw","place_id":"946fa4b2c1cb037cc3a92ea088847290d422c22e","types":["lodging","casino","establishment"],"formatted_address":"128 Fremont St, Las Vegas, NV 89101, United States","street_number":"128","route":"Fremont St","zipcode":"89101","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-10-18T14:39:47.946-07:00","updated_at":"2015-02-24T08:05:27.681-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.144024 36.171396)","do_not_connect_to_api":true,"merged_with_place_id":12240})
  end
end
puts "\n\n\n--------------------\n- Recreating King Eddy Saloon INCORRECT: [11757]"
if Place.where(id: 5165).any?
  place = Place.find_by(id: 11757)
  place ||= Place.find_by(place_id: 'ChIJg5Tm9jXGwoARHxmYNdax1UI')
  if place.present?
    Place.find(5165).merge(place)
  else
    place = Place.create!({"id":11757,"name":"King Eddy Saloon INCORRECT","reference":"CoQBcQAAAN68ZGd8c7pIDV1gOu8sAOzJz2x4P-zH4op9NYQMju4rWpOd0-V__7GrjF0_fp65qDsSRqFzChqhmZjinbZLPLAhoYh3MZS8LKXvai4UMw-fjSXRMcubl_Zpb0YOd1ZDldLrZHJxP7dRgu-9iuVcJKCqPpWonRf1TjeUAWo0WO-MEhCBd3HfBx4Awn53BbQGwShTGhTYOod_lFwB_qNZLY4xYkB0eyFaWA","place_id":"ChIJg5Tm9jXGwoARHxmYNdax1UI","types":["bar","establishment"],"formatted_address":"131 East 5th Street, Los Angeles, CA 90013, United States","street_number":"131","route":"East 5th Street","zipcode":"90013","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-27T21:56:30.458-08:00","updated_at":"2015-02-27T11:08:05.137-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"4004212","location_id":19,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.247582 34.046264)","do_not_connect_to_api":true,"merged_with_place_id":5165})
  end
elsif Place.where(id: 11757).any?
  place = Place.find_by(id: 5165)
  place ||= Place.find_by(place_id: 'cc29fb57db45f5aa38e0fc60b5720941ed62bcc7')
  if place.present?
    Place.find(11757).merge(place)
  else
    place = Place.create!({"id":5165,"name":"King Eddy Saloon","reference":"CoQBcgAAAF7bpyPhrZJ7pXWs2VzXY6A4ha_cF3fts7mMC6t0C5ZpeGicTYKahmk0SIKU8_elRM7LrltlbLPX5Nxfwgcr7YtLTso3vBF5PsiCJDHMiTeKNV6SGTrHCYZGXpHQb6k1S7nuEM1HjLpmjZ8doyzdYOfPqhX_4bGdDFoRu4FHkDgiEhBpmlyQLZE07Y0ZzSqUg4-RGhTp0z5xNzVQy9z6N9ZaYwFEq-QoEQ","place_id":"cc29fb57db45f5aa38e0fc60b5720941ed62bcc7","types":["night_club","bar","establishment"],"formatted_address":"131 E 5th Street, Los Angeles, CA 90013","street_number":"131","route":"E 5th St","zipcode":"90013","city":"Los Angeles","state":"California","country":"US","created_at":"2014-03-11T17:00:52.241-07:00","updated_at":"2015-02-27T11:08:35.386-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"4004212","location_id":19,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.247611 34.04621)","do_not_connect_to_api":true,"merged_with_place_id":11757})
  end
end
puts "\n\n\n--------------------\n- Recreating 3 Sheets Saloon: [11996]"
if Place.where(id: 3037).any?
  place = Place.find_by(id: 11996)
  place ||= Place.find_by(place_id: 'ChIJvz4F1JNZwokRN-_0V6iwxpY')
  if place.present?
    Place.find(3037).merge(place)
  else
    place = Place.create!({"id":11996,"name":"3 Sheets Saloon","reference":"CoQBcQAAAEsFL-D34Or8gJM_gRC5vVdKT6TCbDBTTl8u217o2f8v0NWZuBsEL6tRqDkXfheqWtEGbC2xd575FFEdznZwOm3XspPGiXxFvDqlVIMu5bQNmriFeKUQkICkacu_LKynLFB5HX6gRNPSATu0JDMFvY-5kn1RH3oTE9CMHbxOikMpEhBw8rjQP34VD1MJ6CFBBXHQGhSDRNGyzj1cPJacKtQ01gsIB9E5hw","place_id":"ChIJvz4F1JNZwokRN-_0V6iwxpY","types":["bar","restaurant","food","establishment"],"formatted_address":"134 West 3rd Street, New York, NY 10012, United States","street_number":"134","route":"West 3rd Street","zipcode":"10012","city":"New York","state":"New York","country":"US","created_at":"2015-02-03T11:32:48.635-08:00","updated_at":"2015-02-03T11:32:48.635-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"1893410","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.000996 40.73078)","do_not_connect_to_api":true,"merged_with_place_id":3037})
  end
elsif Place.where(id: 11996).any?
  place = Place.find_by(id: 3037)
  place ||= Place.find_by(place_id: '61ebb56bb0fdd549e55fe647107b8a7a38ac16b7')
  if place.present?
    Place.find(11996).merge(place)
  else
    place = Place.create!({"id":3037,"name":"3 Sheets Saloon","reference":"CoQBcQAAAIgRGA84wzS8Fs27PgLk9BPv68TGTs80QpIy1M3uedsmC9dKOGSiqgdyfPgZ-nkTyotiNqD2VZPXY6973V1VXhU4mdxuiUMjlbAMca2Mgw2YqvysyPfk_yRIgpebTylIbyxRq4lX8WDBWibqRk8t5CvlH2dcSCcZRYRE7D55ZvjFEhDnRhTcox6CyZbp3z8Va3XIGhTK139EfGgCDlrGUiA7EAcmGDlCAQ","place_id":"61ebb56bb0fdd549e55fe647107b8a7a38ac16b7","types":["bar","establishment"],"formatted_address":"134 West 3rd Street, New York, NY, United States","street_number":"134","route":"West 3rd Street","zipcode":"10012","city":"New York","state":"New York","country":"US","created_at":"2013-11-19T19:12:16.169-08:00","updated_at":"2015-02-01T22:10:04.770-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"1893410","location_id":101,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.000996 40.73078)","do_not_connect_to_api":true,"merged_with_place_id":11996})
  end
end
puts "\n\n\n--------------------\n- Recreating Dick O'Dow's: [10666]"
if Place.where(id: 2231).any?
  place = Place.find_by(id: 10666)
  place ||= Place.find_by(place_id: 'c37c3682a2d671dd061dbd81ff3e1132e2fd15d9')
  if place.present?
    Place.find(2231).merge(place)
  else
    place = Place.create!({"id":10666,"name":"Dick O'Dow's","reference":"CoQBdwAAALho0l377j9CRmWUHqj4OEYLSG0fd_HfRvCqQs0Gk-XImsrFLkc8Wh7kKbl78sFJTR9TPqEsQPLZRQTemeZNq8nLLaC146FNNYDbrPe5JYP364VVp67XHel0mmIgdPhvHzZrzi99LJsZevtpaY3TsRY0iERHcuW5juc0cI9jeS76EhC5LZ_PbFZ3f9df46Pqj1OdGhQeuL01cXeolxPfEzFhCx1cDcX4dw","place_id":"c37c3682a2d671dd061dbd81ff3e1132e2fd15d9","types":["bar","point_of_interest","establishment"],"formatted_address":"Dick O'Dow's, 160 W Maple Rd, Birmingham, MI 48009, USA","street_number":"160","route":"W Maple Rd","zipcode":"48009","city":"Birmingham","state":"Michigan","country":"US","created_at":"2014-12-08T08:45:32.211-08:00","updated_at":"2014-12-08T08:45:32.211-08:00","administrative_level_1":"MI","administrative_level_2":"Oakland County","td_linx_code":"5559081","location_id":567,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.2157101 42.5468196)","do_not_connect_to_api":true,"merged_with_place_id":2231})
  end
elsif Place.where(id: 10666).any?
  place = Place.find_by(id: 2231)
  place ||= Place.find_by(place_id: '3d9d689e40d835668bdb088624636269360aff58')
  if place.present?
    Place.find(10666).merge(place)
  else
    place = Place.create!({"id":2231,"name":"Dick O'Dow's","reference":"CnRuAAAAbUHLMbj-uSJ65-zN97DVcjHRIZckFhzuGw7xJ9ILecSLNc07Ff-QMiC6pvid7-iDpT7wgs4ui1zAXoy-T4stFkxEb3jOYFooBWqWHj7nConrKUscbr6419sxvzVdBn4GBkqn50PnubJhtVUM6f6TjBIQJ4TXcdy8lEwv0YxkH2xJCxoUhbbnABzfPxNhwq0_N08bHFH9CLY","place_id":"3d9d689e40d835668bdb088624636269360aff58","types":["bar","restaurant","food","establishment"],"formatted_address":"160 West Maple Road, Birmingham, MI, United States","street_number":"160","route":"West Maple Road","zipcode":"48009","city":"Birmingham","state":"Michigan","country":"US","created_at":"2013-11-11T00:52:45.207-08:00","updated_at":"2014-02-17T20:14:39.462-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":"5559081","location_id":567,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.215658 42.546761)","do_not_connect_to_api":true,"merged_with_place_id":10666})
  end
end
puts "\n\n\n--------------------\n- Recreating O'Hara's Downtown Sports Bar & Grill: [12096]"
if Place.where(id: 9968).any?
  place = Place.find_by(id: 12096)
  place ||= Place.find_by(place_id: 'ChIJkS4qca1QwokRs_W1uMHSQYQ')
  if place.present?
    Place.find(9968).merge(place)
  else
    place = Place.create!({"id":12096,"name":"O'Hara's Downtown Sports Bar \u0026 Grill","reference":"CpQBhgAAAM1YOW7Iu7AvBAVq305gXCRuHGsCeGEunlomYd-ALG43Rtz6BEY8KFMYHkcUk_zLiGNrQfWhO_Akan-oWjG4dd6hbjE7SAArLHN-UPgX50HUI2NRhVt-lKBpRUIh2xtldZ37IRbODLNMBf_QwaL-N-pB0grN8FZ7aBup4hi-5wEbfgftzqUDpkhGTvgPTKgzORIQIHg4raW9qq9RnfFGwlNqeRoUWvz9U1NRm-ge9zBlxvgyHJZaLLs","place_id":"ChIJkS4qca1QwokRs_W1uMHSQYQ","types":["bar","restaurant","food","establishment"],"formatted_address":"172 1st Street, Jersey City, NJ 07302, United States","street_number":"172","route":"1st Street","zipcode":"07302","city":"Jersey City","state":"New Jersey","country":"US","created_at":"2015-02-05T16:50:36.724-08:00","updated_at":"2015-02-18T11:01:31.621-08:00","administrative_level_1":"NJ","administrative_level_2":nil,"td_linx_code":nil,"location_id":836,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.040835 40.721612)","do_not_connect_to_api":true,"merged_with_place_id":9968})
  end
elsif Place.where(id: 12096).any?
  place = Place.find_by(id: 9968)
  place ||= Place.find_by(place_id: 'cce3e143fa66261a4b6ec4dfd8697e79aeaf56a3')
  if place.present?
    Place.find(12096).merge(place)
  else
    place = Place.create!({"id":9968,"name":"O'Hara's Downtown Sports Bar \u0026 Grill","reference":"CpQBhgAAAEEHrDVhstELugkojgcCxfuZ-ZKjDUQAr198GQv-_mBLOZSIScVuUeoXDF4SRcFbWsXrbTi8xhnMka0FX0gmGrpWqo5AHyrv0HqHab19DZg5xB7svfHhyF94LgSiw8h-21GSjZdLNsJKavttQ-QsS-CWXHftzt4vPGFRLXis52ShxZ0Knm8XoU67iUDlNYWFpxIQBZU7kMbb_BpclQVS7CFaphoU4lTR24gRHu9WJTc1ONNes-C0u4E","place_id":"cce3e143fa66261a4b6ec4dfd8697e79aeaf56a3","types":["bar","restaurant","food","establishment"],"formatted_address":"172 1st St, Jersey City, NJ 07302, United States","street_number":"172","route":"1st St","zipcode":"07302","city":"Jersey City","state":"New Jersey","country":"US","created_at":"2014-11-18T19:12:03.884-08:00","updated_at":"2014-11-18T19:12:03.884-08:00","administrative_level_1":"NJ","administrative_level_2":nil,"td_linx_code":nil,"location_id":836,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.040835 40.721612)","do_not_connect_to_api":true,"merged_with_place_id":12096})
  end
end
puts "\n\n\n--------------------\n- Recreating P T O'Malley's: [11918]"
if Place.where(id: 1211).any?
  place = Place.find_by(id: 11918)
  place ||= Place.find_by(place_id: 'ChIJecsPcdTpIogRa8BjcUWcpyw')
  if place.present?
    Place.find(1211).merge(place)
  else
    place = Place.create!({"id":11918,"name":"P T O'Malley's","reference":"CnRvAAAA7_rPxEZ24dSh5lxj5g7fGR4ihzaRi18G-4WUhnfjEeTuAIyKZOUGQ5J4VnOXufaYRJLAcbtxi8Hdw1ux5DbflaflKybdCfsYPKC_r6SCdZr63HMFBpNCmk9ngDJwhpqqlyG9cD-ZYkkoxCCq9awwRRIQJzuAS0v1tMtWBhmsH9MQiRoUDXW4cP54JfR_QaQayZC0xLxKVrQ","place_id":"ChIJecsPcdTpIogRa8BjcUWcpyw","types":["restaurant","food","establishment"],"formatted_address":"210 Abbott Road, East Lansing, MI 48823, United States","street_number":"210","route":"Abbott Road","zipcode":"48823","city":"East Lansing","state":"Michigan","country":"US","created_at":"2015-02-02T03:42:21.013-08:00","updated_at":"2015-02-03T16:20:24.272-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":nil,"location_id":456,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-84.48361 42.73555)","do_not_connect_to_api":true,"merged_with_place_id":1211})
  end
elsif Place.where(id: 11918).any?
  place = Place.find_by(id: 1211)
  place ||= Place.find_by(place_id: '48885e539a2f1352c06864cbf7a7fc8c76dd177b')
  if place.present?
    Place.find(11918).merge(place)
  else
    place = Place.create!({"id":1211,"name":"P T O'Malley's","reference":"CnRnAAAAmbZIGXr9JlwdQvI6e48-2n8gk9xb2fmpPFdD3IuVn-wJxWSpVZjPqKZExJhBj0JPNbw_-g0w2AU_MaLBRpt1xde-O8BCGs6s7Cj2lU1N9pGwOxqHCdgr1BCvwoKzN_ViHhho7cdddkIJDwxFZpAX-hIQOTFEfHYwXGJFbjq2257XoRoUc20_elGYUjS6XZmRZaSerKWmLdo","place_id":"48885e539a2f1352c06864cbf7a7fc8c76dd177b","types":["restaurant","food","establishment"],"formatted_address":"210 Abbott Road, East Lansing, MI, United States","street_number":"210","route":"Abbott Road","zipcode":"48823","city":"East Lansing","state":"Michigan","country":"US","created_at":"2013-10-20T12:36:49.588-07:00","updated_at":"2015-01-26T12:23:03.241-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":"5579009","location_id":456,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-84.48361 42.73555)","do_not_connect_to_api":true,"merged_with_place_id":11918})
  end
end
puts "\n\n\n--------------------\n- Recreating Fado Irish Pub Austin: [11772]"
if Place.where(id: 401).any?
  place = Place.find_by(id: 11772)
  place ||= Place.find_by(place_id: 'ChIJ0XNo4Qi1RIYRxylNoz6Xuq0')
  if place.present?
    Place.find(401).merge(place)
  else
    place = Place.create!({"id":11772,"name":"Fado Irish Pub Austin","reference":"CoQBdwAAAF3CZzX97b9PIC7u0fTQV1oKtDG3cSbrQqkdnzFAQiJRSvZ1Tt8b3SGys3m-NFjK7A_alDPdJ9ckaD06Ao6qy-PbOUAVjy441huVcXm2pG1YcLE-6Y-j3nz4RT3q9QeXzTZC67yJNpJPlduDCm3gi8w3yVFVVehFaZ2XWDrOJhrtEhBM6yUaAwvWAY09S60L_8hnGhRVFIjw1PWXVQllQERvbMf-i_4bAg","place_id":"ChIJ0XNo4Qi1RIYRxylNoz6Xuq0","types":["bar","restaurant","food","establishment"],"formatted_address":"214 West 4th Street, Austin, TX 78701, United States","street_number":"214","route":"West 4th Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2015-01-28T08:42:46.896-08:00","updated_at":"2015-02-04T09:13:03.638-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5619080","location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.745434 30.267047)","do_not_connect_to_api":true,"merged_with_place_id":401})
  end
elsif Place.where(id: 11772).any?
  place = Place.find_by(id: 401)
  place ||= Place.find_by(place_id: '6a8e832f581835b64bb689736d50cd522c233093')
  if place.present?
    Place.find(11772).merge(place)
  else
    place = Place.create!({"id":401,"name":"Fado Irish Pub Austin","reference":"CoQBcwAAABySaP1Tu5oFzgiih56hsKFeIND1qO4QhcToTOBPUJ1tVgx_Pd9cCmWHxgdalWvt1vys6tfyPcokx5b-kiwXjAT-3ylrw4ohvJSO7goVMs69ycF_J7EYZ5aiouAYCzz750LAsDBgGDL3ftyQXWmJ44Bgi8mCvb4MNsj8LvAmXl8EEhAhBxnbVEKbmCrYd4wDhwgUGhR4buaTsrFvam0w85oMC4754wOCOQ","place_id":"6a8e832f581835b64bb689736d50cd522c233093","types":["bar","restaurant","food","establishment"],"formatted_address":"214 West 4th Street, Austin, TX, United States","street_number":"214","route":"West 4th Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2013-10-11T13:36:17.110-07:00","updated_at":"2015-02-04T09:13:03.742-08:00","administrative_level_1":"TX","administrative_level_2":"Travis County","td_linx_code":"5619080","location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.745567 30.266898)","do_not_connect_to_api":true,"merged_with_place_id":11772})
  end
end
puts "\n\n\n--------------------\n- Recreating Professor Thom's: [11975]"
if Place.where(id: 3803).any?
  place = Place.find_by(id: 11975)
  place ||= Place.find_by(place_id: 'ChIJz-GEXZ5ZwokRoNsYh5LJy3s')
  if place.present?
    Place.find(3803).merge(place)
  else
    place = Place.create!({"id":11975,"name":"Professor Thom's","reference":"CoQBcQAAAFWnL0H3P8k4yEa1XE9pPiq-cY4hS-vcA2eDSFNe63YRzxhXe_tmwQgbIC8iO1l6e0C5iRWC7d9ruAjrqjWCRRgmDSFPViN65R4s00ktqE5U2JdDUTmIRTBXRj52qTp9DE1bi6zegGF392WZrBL7HF-X1CKpYA_pf7s8HSLSUTDuEhBXc3H2PaDQyciZPwLuxGwNGhTzQafRbOTQVRWbc8I5CpQMM78CmA","place_id":"ChIJz-GEXZ5ZwokRoNsYh5LJy3s","types":["bar","restaurant","food","establishment"],"formatted_address":"219 2nd Avenue, New York, NY 10003, United States","street_number":"219","route":"2nd Avenue","zipcode":"10003","city":"New York","state":"New York","country":"US","created_at":"2015-02-03T00:00:28.808-08:00","updated_at":"2015-02-03T00:00:28.808-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5077897","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.98548 40.732048)","do_not_connect_to_api":true,"merged_with_place_id":3803})
  end
elsif Place.where(id: 11975).any?
  place = Place.find_by(id: 3803)
  place ||= Place.find_by(place_id: '124539a0d097da888b9d5b6500d1c9934d0f45d7')
  if place.present?
    Place.find(11975).merge(place)
  else
    place = Place.create!({"id":3803,"name":"Professor Thom's","reference":"CoQBcQAAAFQCdGM4DJ4BYYGLM3OWRbKx0GywyXDnMJMoDRJytVqDcvOpwBKpEneqrao_JszMsVSElLv8Vl6HFKxHHL3syBSLHXdLedbQI_EuCyd7OPe7HLkV4TuMT6BLf0paE-OK9uVfX13PloCZZazYvWMRJPGeArf43b41NQCQ3Js78DhAEhB5l9NbFFRizIEavnOChu1RGhTPPaaPoSQaFYEe6BJOwg8Jdw3LUw","place_id":"124539a0d097da888b9d5b6500d1c9934d0f45d7","types":["bar","restaurant","food","establishment"],"formatted_address":"219 2nd Avenue, New York, NY, United States","street_number":"219","route":"2nd Avenue","zipcode":"10003","city":"New York","state":"New York","country":"US","created_at":"2013-12-30T07:45:02.027-08:00","updated_at":"2015-02-01T21:59:10.317-08:00","administrative_level_1":"NY","administrative_level_2":"New York County","td_linx_code":"5077897","location_id":347,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.985433 40.732011)","do_not_connect_to_api":true,"merged_with_place_id":11975})
  end
end
puts "\n\n\n--------------------\n- Recreating Cafe Tallulah: [3700]"
if Place.where(id: 1864).any?
  place = Place.find_by(id: 3700)
  place ||= Place.find_by(place_id: '614a94c58e2c7aacd9bffd7f554f3ff4dd17c210')
  if place.present?
    Place.find(1864).merge(place)
  else
    place = Place.create!({"id":3700,"name":"Cafe Tallulah","reference":"CqQBlQAAADrSrXvmZmoiNRyOX1sRvO8I2URgojsS0ZJXkqOFc0FaXMaoPuenGtmc7Zc3aBqzl6Dw0OutHBBrUDFhxNG0aB6CovPN4ATw_ON4205ghltfYyHgUi7ipyL6hTDoTiSZCoKxhYZWfyfHQ_JkIXYHuLhMVDdRDgApT5U3EsHa4m3ybvwn_akye2MpvzaKFU5S5ApxqnyHH762fP-HBf0uo8YSEFO5Aje2T2Ykg1BSd1t3KlEaFKlKdDDeJs36ZJndT18HI1DEC9Ea","place_id":"614a94c58e2c7aacd9bffd7f554f3ff4dd17c210","types":["street_address"],"formatted_address":"240 Columbus Ave, New York, NY 10023, USA","street_number":"240","route":"Columbus Ave","zipcode":"10023","city":"New York","state":"New York","country":"US","created_at":"2013-12-19T06:00:55.577-08:00","updated_at":"2014-02-17T20:22:51.021-08:00","administrative_level_1":"NY","administrative_level_2":"New York","td_linx_code":"5073761","location_id":347,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.9792852 40.7767682)","do_not_connect_to_api":true,"merged_with_place_id":1864})
  end
elsif Place.where(id: 3700).any?
  place = Place.find_by(id: 1864)
  place ||= Place.find_by(place_id: 'b066628b9650b28c9f2d0636ef34731e44e0f5f7')
  if place.present?
    Place.find(3700).merge(place)
  else
    place = Place.create!({"id":1864,"name":"Cafe Tallulah","reference":"CnRvAAAAGzCHE2vLv0HPU6C9dJ6fsgV7QNW__87msI44GTENEAGGMZmsPpS1WHVanP1f7p08HonOjNXtqXUwhQvTDNxfyb4RJMIHUX8QovTE4opmuSueTYTraEhc9v2nRMY1VE9cuBzm1Phnsr0LF6cvCn5B9RIQqyFUK2Pu3YezSOhz3ecj4xoUAn7fdFA5fshZT6vR44-IceXfhzo","place_id":"b066628b9650b28c9f2d0636ef34731e44e0f5f7","types":["cafe","bar","restaurant","food","establishment"],"formatted_address":"240 Columbus Avenue, New York, NY, United States","street_number":"240","route":"Columbus Avenue","zipcode":"10023","city":"New York","state":"New York","country":"US","created_at":"2013-11-11T00:49:26.199-08:00","updated_at":"2014-02-17T20:12:47.220-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5073761","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.979384 40.77692)","do_not_connect_to_api":true,"merged_with_place_id":3700})
  end
end
puts "\n\n\n--------------------\n- Recreating The Stag's Head: [12359]"
if Place.where(id: 1506).any?
  place = Place.find_by(id: 12359)
  place ||= Place.find_by(place_id: 'ChIJNceaAeNYwokRDLhgOBibfV0')
  if place.present?
    Place.find(1506).merge(place)
  else
    place = Place.create!({"id":12359,"name":"The Stag's Head","reference":"CnRiAAAA_kenltG6Kjg7i2FxSqTW6UukVDZb8H14ch74MbEKUfJlHOc4MZQuIufXAFBs_0acidjexYLeG3wXbhP1bJxEPuszAb1335CplIQvxNPX4k0pBz_8Syt7Vw30MTY_Wuku_u_tY-YXHyNzF2pC5llNExIQ58ELoosmp3x_q1IAcZeODhoUBiFt9e-2ZxTIyOnjet257ekTW-s","place_id":"ChIJNceaAeNYwokRDLhgOBibfV0","types":["bar","establishment"],"formatted_address":"252 East 51st Street, New York, NY 10022, United States","street_number":"252","route":"East 51st Street","zipcode":"10022","city":"New York","state":"New York","country":"US","created_at":"2015-02-16T11:37:30.166-08:00","updated_at":"2015-02-18T10:54:50.264-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":nil,"location_id":101,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.968633 40.75556)","do_not_connect_to_api":true,"merged_with_place_id":1506})
  end
elsif Place.where(id: 12359).any?
  place = Place.find_by(id: 1506)
  place ||= Place.find_by(place_id: '98447bc7988cf125a20c55beefb1b85b5d5340c9')
  if place.present?
    Place.find(12359).merge(place)
  else
    place = Place.create!({"id":1506,"name":"The Stag's Head","reference":"CoQBcQAAAFid-5gobkaWtzjEsxgFtlfaWvZnANLrarCCwXV5plE2dxhCHyC5iEb8tfoPOpiKXPrONQWVkQp5P7iQFRLt-xTGS9cStkSfOqA0RlHM_05LzatmAoZTNBkCheILkWkFL0ooWwK71lgRd7akoNdveqN0Qu6uhuIjWWYCuE85gGEEEhDKNiJdkrZCmogR74j-xyH0GhQgpkLjuZZA8jL1X6O4r02fY4_IEw","place_id":"98447bc7988cf125a20c55beefb1b85b5d5340c9","types":["bar","establishment"],"formatted_address":"252 East 51st Street, New York, NY, United States","street_number":"252","route":"East 51st Street","zipcode":"10022","city":"New York","state":"New York","country":"US","created_at":"2013-11-09T09:35:05.868-08:00","updated_at":"2014-02-17T20:10:44.868-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5079532","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.968456 40.755586)","do_not_connect_to_api":true,"merged_with_place_id":12359})
  end
end
puts "\n\n\n--------------------\n- Recreating Fadó Irish Pub Atlanta: [12102]"
if Place.where(id: 8945).any?
  place = Place.find_by(id: 12102)
  place ||= Place.find_by(place_id: 'ChIJlWRLpY0F9YgRTIf_Vqx_3tg')
  if place.present?
    Place.find(8945).merge(place)
  else
    place = Place.create!({"id":12102,"name":"Fadó Irish Pub Atlanta","reference":"CoQBeQAAADV4qyoTL0Sy6qzgklSp4yf8Il76W0v1fdFSbRpu9c2a4CKGPUdlc6POsARQi5hFnz5skWwPZvUJuWjuAvR5AVY5EPxjlmZ9UwnJQMbUnishyB_pjiDCAYt1df-LwKX8Q5u5HVWaZyKlZvMJqKWm6WI-CDGp_Yu4HNbqHoN4iP0MEhDc0UDwjUO-8kEZ56TqUBpiGhTdAZ5c7cTrTUz0AiVNz_KaWARdYQ","place_id":"ChIJlWRLpY0F9YgRTIf_Vqx_3tg","types":["bar","restaurant","food","establishment"],"formatted_address":"273 Buckhead Avenue Northeast, Atlanta, GA 30305, United States","street_number":"273","route":"Buckhead Avenue Northeast","zipcode":"30305","city":"Atlanta","state":"Georgia","country":"US","created_at":"2015-02-05T21:37:30.983-08:00","updated_at":"2015-02-05T21:40:43.598-08:00","administrative_level_1":"GA","administrative_level_2":nil,"td_linx_code":"2581089","location_id":466,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-84.378534 33.837882)","do_not_connect_to_api":true,"merged_with_place_id":8945})
  end
elsif Place.where(id: 12102).any?
  place = Place.find_by(id: 8945)
  place ||= Place.find_by(place_id: 'a4279e6b6bba95f2246fc1d5a46082731c9fe26b')
  if place.present?
    Place.find(12102).merge(place)
  else
    place = Place.create!({"id":8945,"name":"Fadó Irish Pub Atlanta","reference":"CoQBegAAAIw7y0m1jJF1kjuO0P3z7F7eanYdoFKet0EcGVTXFtndWsq5Zxb0wgvewu0avBgUp9e5MZHxKWNcl2N2CId5RYJD1kbn06dy1BFNhGWKbqV8isB-qKm4SOajNy5Bh6PxcEjeGOdJzOp4MgP1GSD3z3_252eh_6Sz1uhE3S16Uk9SEhD3_Pz7Koa0aLNkp9OY3ZSJGhQoBkyQnneewYuSZ6kiTg9Qq0LhUw","place_id":"a4279e6b6bba95f2246fc1d5a46082731c9fe26b","types":["bar","restaurant","food","establishment"],"formatted_address":"273 Buckhead Avenue, Atlanta, GA 30305, United States","street_number":nil,"route":nil,"zipcode":"30305","city":"Atlanta","state":"Georgia","country":"US","created_at":"2014-10-17T13:57:28.744-07:00","updated_at":"2015-02-05T21:44:00.634-08:00","administrative_level_1":"GA","administrative_level_2":nil,"td_linx_code":nil,"location_id":466,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-84.378534 33.837882)","do_not_connect_to_api":true,"merged_with_place_id":12102})
  end
end
puts "\n\n\n--------------------\n- Recreating Louie and Chan: [10108]"
if Place.where(id: 6043).any?
  place = Place.find_by(id: 10108)
  place ||= Place.find_by(place_id: 'd1671f1263223bd3d767e137660554cd8bf00942')
  if place.present?
    Place.find(6043).merge(place)
  else
    place = Place.create!({"id":10108,"name":"Louie and Chan","reference":"CoQBcQAAAEMN5Jbnzqe54-uLDTNVHl6SnYB3O9aVyHqkFIZOTYyCXpjGMRW0XoOAvQEQAkSQEz_PbTUeEmDG2Iv5HipXZo7rTzqut6qJWkB2qLcC2nXrO3VUdoqgyJA0q2oKGqEvv-25q1KO-EF5zdeKnPzYPfRsqkjIieufyYgC37XxzhjSEhBmw_Ws-E1rOKkDsN-p7T-kGhQg3kpjq5s0wNvww_Mw3Q2jZw7zxw","place_id":"d1671f1263223bd3d767e137660554cd8bf00942","types":["restaurant","food","establishment"],"formatted_address":"303 Broome Street, Brooklyn, NY 10002, United States","street_number":nil,"route":nil,"zipcode":"10002","city":"New York","state":"New York","country":"US","created_at":"2014-11-25T12:03:36.645-08:00","updated_at":"2014-11-25T12:03:36.645-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":nil,"location_id":102,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.992464 40.71855)","do_not_connect_to_api":true,"merged_with_place_id":6043})
  end
elsif Place.where(id: 10108).any?
  place = Place.find_by(id: 6043)
  place ||= Place.find_by(place_id: '92e6840cbe49052b8bdb16773a17613cb2d62b28')
  if place.present?
    Place.find(10108).merge(place)
  else
    place = Place.create!({"id":6043,"name":"Louie and Chan","reference":"CnRvAAAA61ehpX50kU5CTF2FA9ZsMmkebZyq-v1sO4C9FzlK4g4XZXUqO0TvwJSM6eHHZ0pHnbCiOB55vIVblW88LNu8VCitZkx7BJsHd_61Z6o2GewswWjLVrMCYcA1vaI4TlT4dPHB7UoKC9cwlrEYX3XyuxIQsze0IonzaWTIyfrZSf98yRoUn5-bmY3cIEPAWEJi5PqBHfeoMwg","place_id":"92e6840cbe49052b8bdb16773a17613cb2d62b28","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"303 Broome St, New York, NY, United States","street_number":"303","route":"Broome St","zipcode":"10002","city":"New York","state":"New York","country":"US","created_at":"2014-04-16T12:26:11.865-07:00","updated_at":"2014-04-16T12:26:11.865-07:00","administrative_level_1":"NY","administrative_level_2":"New York County","td_linx_code":"7286146","location_id":347,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.992441 40.718663)","do_not_connect_to_api":true,"merged_with_place_id":10108})
  end
end
puts "\n\n\n--------------------\n- Recreating Duddley's Draw: [12315]"
if Place.where(id: 9127).any?
  place = Place.find_by(id: 12315)
  place ||= Place.find_by(place_id: 'ChIJV_qcqb2DRoYRp6qX_VsAyT0')
  if place.present?
    Place.find(9127).merge(place)
  else
    place = Place.create!({"id":12315,"name":"Duddley's Draw","reference":"CnRhAAAAkjbCKEnXEYT8fPFcrRZQ8gjwnn8dydW_kmNEGUcr0Qgp5ejVjVJnUiO4i3ql7qvDOpHGOa9Gh1Rr3aFlFatYL1cwww31va1_GQZIQZptNTm_YcjTsTSaos9wNEZKXD_p9d4ZtR_p2jqDVhnF1rbHKhIQWmCNV5zB9ryRePeMxfPMqhoUykgy4St48ayO02JsQumQJQCOxfE","place_id":"ChIJV_qcqb2DRoYRp6qX_VsAyT0","types":["bar","establishment"],"formatted_address":"311 University Drive, College Station, TX 77840, United States","street_number":"311","route":"University Drive","zipcode":"77840","city":"College Station","state":"Texas","country":"US","created_at":"2015-02-13T07:06:01.940-08:00","updated_at":"2015-02-18T10:54:59.190-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":16,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.346274 30.618012)","do_not_connect_to_api":true,"merged_with_place_id":9127})
  end
elsif Place.where(id: 12315).any?
  place = Place.find_by(id: 9127)
  place ||= Place.find_by(place_id: '00505eb3322a43d4ab1bac5aba101ca2ab393bf4')
  if place.present?
    Place.find(12315).merge(place)
  else
    place = Place.create!({"id":9127,"name":"Duddley's Draw","reference":"CnRvAAAA4iBqkD6wHYyu2HrPMubxc48kE14_V-xP1WbPEm5QuoRL4q88-0dhaFJwFjqOj3-Oc3R9I0xw2E0cYeCfhfLBq3ajnSOr2ZKAk6qr0dizzQjmoyLzR85Iv8Br6acu8zg-AyPW264PbKhhd3qrj_VveBIQpS5nF9FaxqXBqhjA-cLiRhoUENyJBMXNOgZ2rOUDRAu8TA_WH8Y","place_id":"00505eb3322a43d4ab1bac5aba101ca2ab393bf4","types":["bar","establishment"],"formatted_address":"311 University Dr, College Station, TX 77840, United States","street_number":"311","route":"University Dr","zipcode":"77840","city":"College Station","state":"Texas","country":"US","created_at":"2014-10-22T14:54:08.714-07:00","updated_at":"2015-01-26T06:38:01.368-08:00","administrative_level_1":"TX","administrative_level_2":"Brazos County","td_linx_code":"5618674","location_id":96715,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.346274 30.618012)","do_not_connect_to_api":true,"merged_with_place_id":12315})
  end
end
puts "\n\n\n--------------------\n- Recreating Sol Venue: [8733]"
if Place.where(id: 1657).any?
  place = Place.find_by(id: 8733)
  place ||= Place.find_by(place_id: '28c0336ddbbd656f28600de7371936b92668f2a2')
  if place.present?
    Place.find(1657).merge(place)
  else
    place = Place.create!({"id":8733,"name":"Sol Venue","reference":"CnRsAAAAIS_BdMZP8u90ak4LBBKRdz5dyN239Xu3rUG52XIiAfWNJIxJHUz94m8Icu6JAShJi_YpDwrxf1uw7SOdSuk0Rpw8CiyBnzjgP-RyO-fff4S_Cq978_mCUIPw2FEhpMsKVmSoKxOT3x3HRX-IYX0_hxIQnK709N-fbuv9jSMAlI1bkRoUtymM28h0-RAK_6hPnTCiRPjbplE","place_id":"28c0336ddbbd656f28600de7371936b92668f2a2","types":["night_club","bar","establishment"],"formatted_address":"313 E Carson St, Carson, CA 90745, United States","street_number":"313","route":"E Carson St","zipcode":"90745","city":"Carson","state":"California","country":"US","created_at":"2014-10-06T17:42:15.645-07:00","updated_at":"2014-10-06T17:42:15.645-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5246468","location_id":416,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.271872 33.832422)","do_not_connect_to_api":true,"merged_with_place_id":1657})
  end
elsif Place.where(id: 8733).any?
  place = Place.find_by(id: 1657)
  place ||= Place.find_by(place_id: '836dd431ba298b770a9b9c49c164649c9201670e')
  if place.present?
    Place.find(8733).merge(place)
  else
    place = Place.create!({"id":1657,"name":"SOL Venue","reference":"CnRqAAAArcM_JRYr64R0p65MVmH8QPFqRP4w2P4Q5N6mAlDnWn5h_KEHKKj0UIhhQwAQFED5UXj3pWDNliuaWvJUBhRCPnwKXK0LU1tsiCAce2LP2cyyvwl4-MCY7qn-be31JX8iULmxWcC1K50b_ybrqqZ80xIQ399aedsOiIKE0g3895UEyBoUI6zTkIsnnFwaAT9Ytg6oNzPZSMY","place_id":"836dd431ba298b770a9b9c49c164649c9201670e","types":["bar","establishment"],"formatted_address":"313 East Carson Street, Carson, CA, United States","street_number":"313","route":"East Carson Street","zipcode":"90745","city":"Carson","state":"California","country":"US","created_at":"2013-11-11T00:48:12.202-08:00","updated_at":"2014-02-17T20:11:33.284-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5246468","location_id":416,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.271707 33.831773)","do_not_connect_to_api":true,"merged_with_place_id":8733})
  end
end
puts "\n\n\n--------------------\n- Recreating Third Floor Café: [11761]"
if Place.where(id: 4946).any?
  place = Place.find_by(id: 11761)
  place ||= Place.find_by(place_id: 'ChIJwTK_XahZwokRRBSlgGs0AF0')
  if place.present?
    Place.find(4946).merge(place)
  else
    place = Place.create!({"id":11761,"name":"Third Floor Café","reference":"CoQBcgAAAFH1JaWiHc6_aQLs58V890tUI_NELf1eI-EqeUcF59QXSsqAqqpCgDXdJIhZh8DSh33lFtspvHXRrsOwqk_c8INDhOzZZqy7NUT2cNtn34d8PFf38VcV8vM4jDu5KdDnJLQRVDHK44QOLgUVyj5dVL0uvl8_XbLa3oukjSm1vudKEhDX1NRwiVhd1dbyQm3gnCawGhTYFw2-DYfhZJyitmIA5l8WwBpHpQ","place_id":"ChIJwTK_XahZwokRRBSlgGs0AF0","types":["bar","restaurant","food","establishment"],"formatted_address":"315 5th Avenue, New York, NY 10016, United States","street_number":"315","route":"5th Avenue","zipcode":"10016","city":"New York","state":"New York","country":"US","created_at":"2015-01-28T06:17:53.158-08:00","updated_at":"2015-01-28T06:17:53.158-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5105117","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.985416 40.746964)","do_not_connect_to_api":true,"merged_with_place_id":4946})
  end
elsif Place.where(id: 11761).any?
  place = Place.find_by(id: 4946)
  place ||= Place.find_by(place_id: '287c68107f38bb3809e74511492b72a853c2f6f0')
  if place.present?
    Place.find(11761).merge(place)
  else
    place = Place.create!({"id":4946,"name":"Third Floor Café","reference":"CoQBcgAAAAUI03y5WFA3WIdjGJjgYD_TKoL0FL0h2YKA-KfWA3Sy5rz_ltjLieHrMexRvwImLbL_Hd3wteysSxjsGw3J6xmb3cloQ5WnmJR1q_ZJ9mAy_q1bv063D-KfVXLOcrByQm-F7uj7wg5q2g5Pyr-P_QVZqiYte81m2KvvCtoqhbMjEhBSd-crvL_lVOP71DJsZt-SGhQqpqh98jJIInfxs_PIKDgfZb4AWw","place_id":"287c68107f38bb3809e74511492b72a853c2f6f0","types":["restaurant","food","establishment"],"formatted_address":"315 5th Ave, New York, NY, United States","street_number":"315","route":"5th Ave","zipcode":"10016","city":"New York","state":"New York","country":"US","created_at":"2014-03-03T15:12:24.363-08:00","updated_at":"2014-03-03T15:12:24.363-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5105117","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.985416 40.746964)","do_not_connect_to_api":true,"merged_with_place_id":11761})
  end
end
puts "\n\n\n--------------------\n- Recreating Swift's Attic: [11930]"
if Place.where(id: 5570).any?
  place = Place.find_by(id: 11930)
  place ||= Place.find_by(place_id: 'ChIJOZxxaAi1RIYRe3j7KpIprWo')
  if place.present?
    Place.find(5570).merge(place)
  else
    place = Place.create!({"id":11930,"name":"Swift's Attic","reference":"CnRuAAAAM_lz1VKPrKyVeDyQHeANqvU196HSBxbhp9vkq9kLRucNXOtZjZw8urKo3dOkXGCcoML2hcLOpowtDxaXVLnMXKTDb_WHrOH9yzMg1feuZYw9w57t5TlmCVqIxFCoEK4O_Vvnsr0iw0xV7BCzfkrZGhIQe5MCIxkriZONnB1d6xnhnxoUUjKNhkSddGzePZnLco7zTsNWtEI","place_id":"ChIJOZxxaAi1RIYRe3j7KpIprWo","types":["bar","restaurant","food","establishment"],"formatted_address":"315 Congress Avenue, Austin, TX 78701, United States","street_number":"315","route":"Congress Avenue","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2015-02-02T08:50:01.450-08:00","updated_at":"2015-02-02T08:50:01.450-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.743366 30.265612)","do_not_connect_to_api":true,"merged_with_place_id":5570})
  end
elsif Place.where(id: 11930).any?
  place = Place.find_by(id: 5570)
  place ||= Place.find_by(place_id: 'd8b23348dfe97fcd7a9033c5685ecc75b956c508')
  if place.present?
    Place.find(11930).merge(place)
  else
    place = Place.create!({"id":5570,"name":"Swift's Attic","reference":"CnRvAAAA8oOuFz7Mlj72heMmeu8ThshpAb5CzCFqLRTNXLlZcRQjpw9alaenBAwaVgcaFCl5znt3Dxsko_aZvAiu4WkzdhoOdUS0I07eL4jKjGVmc6dvm8vAWmaEIq5ETWH76-UDzR4i9JUYDA2N85tFWWeq8hIQxFiZwzy762VPeTCqJpBEuBoUXo4dP5eqCaKD8NZNstAVnZPAFxo","place_id":"d8b23348dfe97fcd7a9033c5685ecc75b956c508","types":["restaurant","food","establishment"],"formatted_address":"315 Congress Ave, Austin, TX, United States","street_number":"315","route":"Congress Ave","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2014-03-23T21:29:13.286-07:00","updated_at":"2014-03-23T21:29:13.286-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.743514 30.265638)","do_not_connect_to_api":true,"merged_with_place_id":11930})
  end
end
puts "\n\n\n--------------------\n- Recreating O'Connor's Public House: [12390]"
if Place.where(id: 9936).any?
  place = Place.find_by(id: 12390)
  place ||= Place.find_by(place_id: 'ChIJZ5Y2zLnpJIgRkuvEZqLlKqk')
  if place.present?
    Place.find(9936).merge(place)
  else
    place = Place.create!({"id":12390,"name":"O'Connor's Public House","reference":"CnRrAAAA2w3phKeaOn8WOJMRqNVegMpxFxO5GMDjevyg2FIKoIIhk5l3PgKV2Ngxre_5GULD7Wb42m6OiSeoTea8aCiXQCwp3ukomAOJflz_1b6zU2H-wCC48RKpMA0Myzn1Y6ph4HBzuqX0XhQIru4LPa2D5hIQ9nPQtPdE9eIB0Oy2HQBEBRoUqbVUF-jcOn2lOusBi5wqjTTiIZg","place_id":"ChIJZ5Y2zLnpJIgRkuvEZqLlKqk","types":["bar","restaurant","food","establishment"],"formatted_address":"324 South Main Street, Rochester, MI 48307, United States","street_number":"324","route":"South Main Street","zipcode":"48307","city":"Rochester","state":"Michigan","country":"US","created_at":"2015-02-16T21:36:11.796-08:00","updated_at":"2015-02-18T10:54:43.511-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":nil,"location_id":584,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.133484 42.680373)","do_not_connect_to_api":true,"merged_with_place_id":9936})
  end
elsif Place.where(id: 12390).any?
  place = Place.find_by(id: 9936)
  place ||= Place.find_by(place_id: '3b0ce3e1a8260d26984738f33f7a8ab57e9699b6')
  if place.present?
    Place.find(12390).merge(place)
  else
    place = Place.create!({"id":9936,"name":"O'Connor's Public House","reference":"CoQBeQAAACpEoql-uGKj6E3Ri644RkWoOeK98OYg2mR1N0EfKAp5MFQEqhTuaErw8DTZP68DCZvOmrGAWjsntEPstIaNCZKMng2aR8YEyg94AIktcbFax_Oa4BZKAprZWcz0HXFHs5zjZMZA37PyIpxialnPU10zZCub3zjyTrTCFE24ferzEhAA_teIpEkZC35lrf1OT064GhR63PxFhnbfUYwRuvitukAUJrNnMQ","place_id":"3b0ce3e1a8260d26984738f33f7a8ab57e9699b6","types":["bar","restaurant","food","establishment"],"formatted_address":"324 S Main St, Rochester, MI 48307, United States","street_number":"324","route":"S Main St","zipcode":"48307","city":"Rochester","state":"Michigan","country":"US","created_at":"2014-11-18T06:26:09.536-08:00","updated_at":"2014-11-18T06:26:09.536-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":nil,"location_id":584,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.133484 42.680373)","do_not_connect_to_api":true,"merged_with_place_id":12390})
  end
end
puts "\n\n\n--------------------\n- Recreating Félix: [12415]"
if Place.where(id: 3454).any?
  place = Place.find_by(id: 12415)
  place ||= Place.find_by(place_id: 'ChIJE4nPdYtZwokRFybT0wpKdXo')
  if place.present?
    Place.find(3454).merge(place)
  else
    place = Place.create!({"id":12415,"name":"Félix","reference":"CmRZAAAAHIwMH4SMpb1baae6b301A54Fuaxu_PPHM075hsfRl5AfyABX0tQhdTg1zisxS0Jv_oKuXlC4wzaw57zIGzqjcXEweg9MQ9RVQlpM3qMzfGn38YygbXa7FCBYl_U4OCecEhDlyQYbckhCTT0n6zpMiAHSGhSKTsGromC8o8kfr0hc6rsn-NzzhA","place_id":"ChIJE4nPdYtZwokRFybT0wpKdXo","types":["bar","restaurant","food","establishment"],"formatted_address":"340 West Broadway, New York, NY 10013, United States","street_number":"340","route":"West Broadway","zipcode":"10013","city":"New York","state":"New York","country":"US","created_at":"2015-02-17T12:01:08.933-08:00","updated_at":"2015-02-18T10:54:39.108-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":nil,"location_id":101,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.003781 40.722594)","do_not_connect_to_api":true,"merged_with_place_id":3454})
  end
elsif Place.where(id: 12415).any?
  place = Place.find_by(id: 3454)
  place ||= Place.find_by(place_id: 'c089d60b798012d9cb234af16e2f4de3b0e211aa')
  if place.present?
    Place.find(12415).merge(place)
  else
    place = Place.create!({"id":3454,"name":"Félix","reference":"CnRoAAAAj0P9W6OUGmxrd5wvePWDMoKHa-Mj11GJTKHbZppPSVslkYJOWC3iIICVFU8uL6Cg6ZBjgkpSowX4_241CFPrkschf4XFv76sZxtLztmyyJ4ygd2Dr9nFP5BRN89IkmaYT2DNx4h4CPUlOIbNLwhzNhIQXjsO_VurHjXG9m9Bk8UGNRoU1pyEb67ZPOvybmhlcEBnAaEc4tw","place_id":"c089d60b798012d9cb234af16e2f4de3b0e211aa","types":["bar","restaurant","food","establishment"],"formatted_address":"340 West Broadway, New York, NY, United States","street_number":"340","route":"West Broadway","zipcode":"10013","city":"New York","state":"New York","country":"US","created_at":"2013-12-07T13:59:53.279-08:00","updated_at":"2014-02-17T20:21:25.342-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":"5089962","location_id":101,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-74.0038 40.722499)","do_not_connect_to_api":true,"merged_with_place_id":12415})
  end
end
puts "\n\n\n--------------------\n- Recreating Bull McCabe's: [12444]"
if Place.where(id: 2524).any?
  place = Place.find_by(id: 12444)
  place ||= Place.find_by(place_id: 'ChIJeXef5DR344kRZZZ5D6N9ouU')
  if place.present?
    Place.find(2524).merge(place)
  else
    place = Place.create!({"id":12444,"name":"Bull McCabe's","reference":"CnRhAAAAdX3YzEC3u7SoqBBXSlq46B8yPZqxDFRy_od1KQzlUCdrO0KMjykWJINhX994_p0ryXRYEOLa-fC2yGIj2Nu8D2Kdk_l8aVAytgF7AG4uDk6VT2G4dFwgGiMlkotD8Wr1QIdC5IxXn_QqqPcZHmrdehIQnDiINSd56_fgPs8ecxFMMBoUg1tx_y-bu8knQ33XkhSbYZ9RtBU","place_id":"ChIJeXef5DR344kRZZZ5D6N9ouU","types":["bar","restaurant","food","establishment"],"formatted_address":"366 Somerville Avenue, Somerville, MA 02143, United States","street_number":"366","route":"Somerville Avenue","zipcode":"02143","city":"Somerville","state":"Massachusetts","country":"US","created_at":"2015-02-18T10:04:25.254-08:00","updated_at":"2015-02-18T10:54:33.517-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":nil,"location_id":181,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.099439 42.381019)","do_not_connect_to_api":true,"merged_with_place_id":2524})
  end
elsif Place.where(id: 12444).any?
  place = Place.find_by(id: 2524)
  place ||= Place.find_by(place_id: 'e984d1e8b4e219ad18cc26478ec0824f6eed6ffa')
  if place.present?
    Place.find(12444).merge(place)
  else
    place = Place.create!({"id":2524,"name":"Bull McCabe's","reference":"CnRwAAAAuZnmw3_vOCH7sxkHizYVtXqW8O3kkJQLRIki4w-eDaSbQ45jf2uyyfAqqs2G43WbZ3jWgAcTR76uopMK3u9cUWoBXYcTEzUMI4scZ4080HnllZDgM-nkfmcIPXqxNMtD5p4g5bO5OLtkPSUrLeJpyxIQy3_epTn2BtKud_ILYhxAXhoUpzp0-QeXkkKc_4wj1gPjC5hESa8","place_id":"e984d1e8b4e219ad18cc26478ec0824f6eed6ffa","types":["bar","establishment"],"formatted_address":"366 Somerville Avenue, Somerville, MA, United States","street_number":"366","route":"Somerville Avenue","zipcode":"02143","city":"Somerville","state":"Massachusetts","country":"US","created_at":"2013-11-11T00:55:14.353-08:00","updated_at":"2014-02-17T20:16:11.570-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":"5120473","location_id":181,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.099459 42.381047)","do_not_connect_to_api":true,"merged_with_place_id":12444})
  end
end
puts "\n\n\n--------------------\n- Recreating Moose Knuckle Pub: [11768]"
if Place.where(id: 2110).any?
  place = Place.find_by(id: 11768)
  place ||= Place.find_by(place_id: 'ChIJs6_pVKa1RIYRV-bja6bI-K4')
  if place.present?
    Place.find(2110).merge(place)
  else
    place = Place.create!({"id":11768,"name":"Moose Knuckle Pub","reference":"CoQBcwAAALQe9hVMngUbarItewBRiJpFywluc-jr0_crrg8wXy72AyuhNfDZY3N28Zy6FUvYbLG-wrxhk7rvH8zU_2YY6cVfz6bDTJFexHsouKKXLRa4BHySP5y5i2ob6txeAY6FZGs4LKDNI3m74t0iFcokheqOx85dW_lK4zkoC0LyU7yhEhCedLCY2qPhQ6iJSQDnnuzuGhSM94jTArA1BLnG9PRPa6HmKpUemA","place_id":"ChIJs6_pVKa1RIYRV-bja6bI-K4","types":["bar","establishment"],"formatted_address":"406 East 6th Street, Austin, TX 78701, United States","street_number":"406","route":"East 6th Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2015-01-28T08:28:25.489-08:00","updated_at":"2015-01-28T08:28:25.489-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2001600","location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.738896 30.267153)","do_not_connect_to_api":true,"merged_with_place_id":2110})
  end
elsif Place.where(id: 11768).any?
  place = Place.find_by(id: 2110)
  place ||= Place.find_by(place_id: '389c87939e38f49ff2d29dd9c66cb0205223cc2b')
  if place.present?
    Place.find(11768).merge(place)
  else
    place = Place.create!({"id":2110,"name":"Moose Knuckle Pub","reference":"CoQBdAAAAL7TgSO1IlAd5IbuaMAyuCa6tuEScEW1vLCvuxEpeNxF4Sazzlo8u6IQZ-W0MqDeC3wzEa1uMTI3bCp_RlhQE95opvGuz9R3sIAeTd6ei4fowVB4yNLl6JPz5AWBfdSZ65w5UStpcQyKNSHP6hDyAp9aB04s8cGryuRs-S8M26fNEhDbVj3Rmj8NpFkuOuEZGpldGhTu92yBAl901PevBHt0g_qsIsbO3Q","place_id":"389c87939e38f49ff2d29dd9c66cb0205223cc2b","types":["bar","establishment"],"formatted_address":"406 East 6th Street, Austin, TX, United States","street_number":"406","route":"East 6th Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2013-11-11T00:51:37.198-08:00","updated_at":"2014-02-17T20:14:05.626-08:00","administrative_level_1":"TX","administrative_level_2":"Travis County","td_linx_code":"2001600","location_id":28,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.738929 30.267099)","do_not_connect_to_api":true,"merged_with_place_id":11768})
  end
end
puts "\n\n\n--------------------\n- Recreating Frank Restaurant: [11938]"
if Place.where(id: 285).any?
  place = Place.find_by(id: 11938)
  place ||= Place.find_by(place_id: 'ChIJNWMB_wi1RIYRundVisrOtIc')
  if place.present?
    Place.find(285).merge(place)
  else
    place = Place.create!({"id":11938,"name":"Frank Restaurant","reference":"CoQBcgAAAMgpuR046QdKX1L0tV5KO_zOgrnKSbbmtAYpbFHiRMKV70sMD8ZWNX5ktELG85X12a33NvWQ22ZL4a2TSgSiMa4bDqVCZphcTSdzxQDNkxa9mfSSM-dLgWlpCDs5IXXC0Sf-YduE-mAEFEx2SffJUN_4WRefuSi46UZb530ARCtgEhDP1J6rg7TntdXYJOfU_ds6GhSQFId0qD-zAQCazuvNCr2Mc41YNg","place_id":"ChIJNWMB_wi1RIYRundVisrOtIc","types":["cafe","bar","restaurant","food","establishment"],"formatted_address":"407 Colorado Street, Austin, TX 78701, United States","street_number":"407","route":"Colorado Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2015-02-02T09:30:41.739-08:00","updated_at":"2015-02-02T09:30:41.739-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5204823","location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.744326 30.26691)","do_not_connect_to_api":true,"merged_with_place_id":285})
  end
elsif Place.where(id: 11938).any?
  place = Place.find_by(id: 285)
  place ||= Place.find_by(place_id: '02bda85debca7fb7ee68a61d9982bf1a2063a810')
  if place.present?
    Place.find(11938).merge(place)
  else
    place = Place.create!({"id":285,"name":"Frank Restaurant","reference":"CnRuAAAAxwXlVjUCxUCzhE3-VQzUCi13XBixzLu0iQL-NOVj4Vgei1W7VHExzjOYkcUTUfOBZyqoa9zqLHo2X_V3bKOJx4XBIvTcoZPOAhjcVmcOgM1UVUkY5dUJuOPCFQ0QriVyQKXnCMv7FQwMN7gkmsx10xIQbuMPYSBPrJBXT72_akcYuRoUy51OemH5P3K544ilypPHQeG6NJU","place_id":"02bda85debca7fb7ee68a61d9982bf1a2063a810","types":["cafe","restaurant","food","establishment"],"formatted_address":"407 Colorado Street, Austin, TX, United States","street_number":"407","route":"Colorado Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2013-10-11T13:35:12.299-07:00","updated_at":"2014-02-17T20:04:51.704-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5204823","location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.744552 30.266965)","do_not_connect_to_api":true,"merged_with_place_id":11938})
  end
end
puts "\n\n\n--------------------\n- Recreating Burritt Tavern at the Mystic Hotel: [7999]"
if Place.where(id: 9238).any?
  place = Place.find_by(id: 7999)
  place ||= Place.find_by(place_id: '0a1829af55a89ab302316a14b5dc8de0fd5b99a1')
  if place.present?
    Place.find(9238).merge(place)
  else
    place = Place.create!({"id":7999,"name":"Burritt Tavern at the Mystic Hotel","reference":"CpQBgwAAACJ6Cqd9reHj8610aR0SVlUyYM0A24Qh7H0eAFpa3acqDS8AIcETxVhmwbxdX80YkXp-tq2XT8QwxDm8-tNrC96VbsoZHGu2joTgm3ztSgOF9IsHOQuLlyLF6EwzFkxEdPRpwBrO0zQ46d7excBe74p9iA5CArkmn4_muJprWA0EkY_huSbqfR119AASnp4rVxIQ0mmrHI74JVurtF9mUuKHWRoUzBa7s9OMIrJFrN_mll03qlJEHZc","place_id":"0a1829af55a89ab302316a14b5dc8de0fd5b99a1","types":["bar","restaurant","food","establishment"],"formatted_address":"417 Stockton St, San Francisco, CA, United States","street_number":"417","route":"Stockton St","zipcode":"94108","city":"San Francisco","state":"California","country":"US","created_at":"2014-09-06T11:22:28.244-07:00","updated_at":"2014-09-06T11:22:28.244-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"3695443","location_id":35,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.407328 37.789792)","do_not_connect_to_api":true,"merged_with_place_id":9238})
  end
elsif Place.where(id: 7999).any?
  place = Place.find_by(id: 9238)
  place ||= Place.find_by(place_id: '159d1f1b3368aa2b0f4474b8d3842a956524dd76')
  if place.present?
    Place.find(7999).merge(place)
  else
    place = Place.create!({"id":9238,"name":"Burritt Room + Tavern","reference":"CoQBdwAAACPqq0TUj_jL4IgpVN9v7SxdXz-f7Q1MAC5T5u2jDsv_xYRSkqb5lFwMCYAVO_BuXHmUMP9kRPryRKM0O7kxHbJygC3R_jDJukqpiHCFtp97L03COHsS19wUjps8KetPJHMYg7yWsTlkau0LrWpUj1e_0s3yWwDFCfbgpIHemMyxEhDfgWrz0mcRKQDNLlvtt447GhSB0246B1W-BJ8gSyP_AdoQ4Pm9Ww","place_id":"159d1f1b3368aa2b0f4474b8d3842a956524dd76","types":["bar","establishment"],"formatted_address":"417 Stockton St, San Francisco, CA 94108, United States","street_number":"417","route":"Stockton St","zipcode":"94108","city":"San Francisco","state":"California","country":"US","created_at":"2014-10-27T10:31:08.894-07:00","updated_at":"2014-10-27T10:31:08.894-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"3695443","location_id":35,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.407271 37.789816)","do_not_connect_to_api":true,"merged_with_place_id":7999})
  end
end
puts "\n\n\n--------------------\n- Recreating This is it: [12344]"
if Place.where(id: 8866).any?
  place = Place.find_by(id: 12344)
  place ||= Place.find_by(place_id: 'ChIJH9RrVwgZBYgRn8ud-hd8Enc')
  if place.present?
    Place.find(8866).merge(place)
  else
    place = Place.create!({"id":12344,"name":"This is it","reference":"CmRdAAAAfzj8puknt-z4W0BW9a1N8iy0n7ll3lDfdmpaEdbAEkoAjY5Te8r3zcUgIWjn4gKdo5xuTbpq2W05XipRf0PFE0zPTlTxXV9XeRZ-v9kf4_Rd8nGBV259Au6xZlGgB_-hEhB7dDcr20T1jmAH_149mUKHGhSI7CQ-BltRpr3Ag6zWtu6XGV0a3g","place_id":"ChIJH9RrVwgZBYgRn8ud-hd8Enc","types":["bar","establishment"],"formatted_address":"418 East Wells Street, Milwaukee, WI 53202, United States","street_number":"418","route":"East Wells Street","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2015-02-15T20:29:15.097-08:00","updated_at":"2015-02-18T10:54:53.220-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":nil,"location_id":646,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.906042 43.041436)","do_not_connect_to_api":true,"merged_with_place_id":8866})
  end
elsif Place.where(id: 12344).any?
  place = Place.find_by(id: 8866)
  place ||= Place.find_by(place_id: '786f858b310e302da0d542ca9986d8fd2f0b02c6')
  if place.present?
    Place.find(12344).merge(place)
  else
    place = Place.create!({"id":8866,"name":"This is it","reference":"CnRsAAAA-n5Q6KLBpxPiVe3U8CXQU3FzgLwqKE-7kw_Z0KaDsm76z0vls7YV0uskJ44mrsptPSl04nDlFTMyeBiLgA5P9wZq2CqFdAaro_Bf7xH8dSW703XItzXmMI798bpl64JjqTpaaVfBKmh78IbDzAyDIRIQmqNSbneyoCACPqwfsXtW9RoUaVsGEdgrHV-25o36ehEZVmtYz6M","place_id":"786f858b310e302da0d542ca9986d8fd2f0b02c6","types":["bar","establishment"],"formatted_address":"418 E Wells St, Milwaukee, WI 53202, United States","street_number":"418","route":"E Wells St","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2014-10-14T17:18:35.209-07:00","updated_at":"2014-10-14T17:18:35.209-07:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"5017717","location_id":646,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.906042 43.041436)","do_not_connect_to_api":true,"merged_with_place_id":12344})
  end
end
puts "\n\n\n--------------------\n- Recreating Jake's Dilemma: [12400]"
if Place.where(id: 4313).any?
  place = Place.find_by(id: 12400)
  place ||= Place.find_by(place_id: 'ChIJc6GIBIZYwokRd_xjvFrHhbU')
  if place.present?
    Place.find(4313).merge(place)
  else
    place = Place.create!({"id":12400,"name":"Jake's Dilemma","reference":"CnRiAAAA4o8rjfnE8Rw5oCNpiizc502_KSo5czJD2FnaEePulg4dPPYyx587zvRJiQRx-1Enh49g9O7QmX51Nkoxpweo2seX6JW2s65VLQbZyYRWCfpW40ov-mlQukC-TPqVaAPQd4oIT4yGhPx8HxL8-StXkhIQeb5UODn7VSY_X3DgJdxU_xoUyYxMxEJe38h9kLWmsa_tKzfnjHs","place_id":"ChIJc6GIBIZYwokRd_xjvFrHhbU","types":["bar","restaurant","food","establishment"],"formatted_address":"430 Amsterdam Avenue, New York, NY 10024, United States","street_number":"430","route":"Amsterdam Avenue","zipcode":"10024","city":"New York","state":"New York","country":"US","created_at":"2015-02-17T07:28:18.636-08:00","updated_at":"2015-02-18T10:54:41.673-08:00","administrative_level_1":"NY","administrative_level_2":nil,"td_linx_code":nil,"location_id":101,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.977673 40.784355)","do_not_connect_to_api":true,"merged_with_place_id":4313})
  end
elsif Place.where(id: 12400).any?
  place = Place.find_by(id: 4313)
  place ||= Place.find_by(place_id: '007b1209961b9f2a60027df7dc138ed6ffeb36c4')
  if place.present?
    Place.find(12400).merge(place)
  else
    place = Place.create!({"id":4313,"name":"Jake's Dilemma","reference":"CoQBcQAAAMh_090QiZ2IiEZpn3hiZR6S2N2olrnSu4qWZ3z3bXu2PVCFORZiChsD4YEF-Uod2fXDlzZYve6xILi6LoouSi7lnRNqdLXg7Ov3WCL7y1tiKeT-YR96fukluJDCYx1zRrpwRFpOimfiI51_RCxSm9rkqQc3SZ1fJ6LGQBy14qopEhAZlS0NJLE-x7K3hFcqMJavGhQ5FGac6FnLUl9ycjmPGFtaVCMV5Q","place_id":"007b1209961b9f2a60027df7dc138ed6ffeb36c4","types":["bar","establishment"],"formatted_address":"430 Amsterdam Ave, New York, NY, United States","street_number":"430","route":"Amsterdam Ave","zipcode":"10024","city":"New York","state":"New York","country":"US","created_at":"2014-01-29T08:49:21.386-08:00","updated_at":"2015-02-01T21:51:22.306-08:00","administrative_level_1":"NY","administrative_level_2":"New York County","td_linx_code":"5104345","location_id":347,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-73.977673 40.784355)","do_not_connect_to_api":true,"merged_with_place_id":12400})
  end
end
puts "\n\n\n--------------------\n- Recreating The Los Angeles Athletic Club: [11911]"
if Place.where(id: 3699).any?
  place = Place.find_by(id: 11911)
  place ||= Place.find_by(place_id: 'ChIJ-_RdD7XHwoARN0-Zc_fk4ZA')
  if place.present?
    Place.find(3699).merge(place)
  else
    place = Place.create!({"id":11911,"name":"The Los Angeles Athletic Club","reference":"CoQBfwAAAKlGrB5lzGma7-eMWx4rGpWKJ4w5F1TbCTuaGRM6UrflXesqTn0u-_FD3U8wvWVf1uhS3B4B4wewdrVBy6Vy_6iXJZ9dLNaYuUrcZvfDt6axazUFOqz7OZoWMp1Vgjc0Wvun_kPq2vANK4umosj1tyCSHQspc7s4qw5S6OlGxtvLEhBegAGeY7JhIRs2zVtxxANLGhST5kv6jugSwNk5rb_u9cmlH4uCyg","place_id":"ChIJ-_RdD7XHwoARN0-Zc_fk4ZA","types":["lodging","establishment"],"formatted_address":"431 West 7th Street, Los Angeles, CA 90014, United States","street_number":"431","route":"West 7th Street","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2015-02-01T14:05:47.115-08:00","updated_at":"2015-02-01T14:05:47.115-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5229061","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.255067 34.046754)","do_not_connect_to_api":true,"merged_with_place_id":3699})
  end
elsif Place.where(id: 11911).any?
  place = Place.find_by(id: 3699)
  place ||= Place.find_by(place_id: '31ca02766c4c50704857ec437055af9b02093f06')
  if place.present?
    Place.find(11911).merge(place)
  else
    place = Place.create!({"id":3699,"name":"The Los Angeles Athletic Club","reference":"CoQBgAAAALZ2oXN1D5bxy6OkH1rsobwMTv4SndL0SU3Rg2spNwB3YWvZqO5QwMhSr7KL41nmJtBU8encG7EHtmgAu59ZukMgHTm-9uXfIn1XEsIGE1750-yBOfdY79uCYJYmMN3Us5wUIzg27SoqOJYq5pQAV9VDNS1UqM3Rjf2wuLEcF4NoEhAI2AwgBS6syIjuKQXC78ApGhSA_RSY1l4knV9J1yBuvyXX415Bdw","place_id":"31ca02766c4c50704857ec437055af9b02093f06","types":["bar","lodging","spa","establishment"],"formatted_address":"431 West 7th Street, Los Angeles, CA, United States","street_number":"431","route":"West 7th Street","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2013-12-19T02:32:25.686-08:00","updated_at":"2014-02-17T20:22:50.610-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5229061","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.255022 34.046667)","do_not_connect_to_api":true,"merged_with_place_id":11911})
  end
end
puts "\n\n\n--------------------\n- Recreating Wolfgang's Steakhouse: [11861]"
if Place.where(id: 3467).any?
  place = Place.find_by(id: 11861)
  place ||= Place.find_by(place_id: 'ChIJl752qQe8woARSWF_HGpEcyA')
  if place.present?
    Place.find(3467).merge(place)
  else
    place = Place.create!({"id":11861,"name":"Wolfgang's Steakhouse","reference":"CoQBdwAAAHXGXBquI0C4AHvi9ZpzKW02rJLd88Y5iStqCH5iZnzWvkaYhSXvEkFuk664UL9U1uw72BTnUK6_7Yz7MnEQfhhCSf2g2NfuQbD2bMgyI9kot0a2I9-yjgfrgLFTIgbq4mWvNaSHFEPJ87Jx1Iv7mNjMoj9mqusOiWnpVDQDtjIyEhD594-rabFQvNp81t1pxeHIGhSMpHn5lKJzvixHyA5AtCt9BQzMkQ","place_id":"ChIJl752qQe8woARSWF_HGpEcyA","types":["bar","restaurant","food","establishment"],"formatted_address":"445 North Cañon Drive, Beverly Hills, CA 90210, United States","street_number":"445","route":"North Cañon Drive","zipcode":"90210","city":"Beverly Hills","state":"California","country":"US","created_at":"2015-01-30T18:02:20.038-08:00","updated_at":"2015-01-30T18:02:20.038-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"2597026","location_id":415,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.401759 34.071278)","do_not_connect_to_api":true,"merged_with_place_id":3467})
  end
elsif Place.where(id: 11861).any?
  place = Place.find_by(id: 3467)
  place ||= Place.find_by(place_id: '1302b4d6aa9c9ef46a13d73c3c010c369314cd50')
  if place.present?
    Place.find(11861).merge(place)
  else
    place = Place.create!({"id":3467,"name":"Wolfgang's Steakhouse","reference":"CoQBdwAAAM-rNNazCwrqRzS7CtX0KQZH6_GqQfvBWNQf9z_C2ACo2PmRy9x8_xWnGyjhn1v2m4EqXO8vEjYUlj8etWylwJjyG4QrKZPBxPU2tCcAzVm5A_kcyulBuHnHnFQmZMDGt0GWNWravnYJqgDqu8ZP9FcGzqcylUzIp4cGlFPcdha1EhA0FLzgg9qIW7a6Ytekpg3IGhTA1dXD9UhV--NfPG8TNKxCn6BpbA","place_id":"1302b4d6aa9c9ef46a13d73c3c010c369314cd50","types":["restaurant","food","establishment"],"formatted_address":"445 North Canon Drive, Beverly Hills, CA, United States","street_number":"445","route":"North Canon Drive","zipcode":"90210","city":"Beverly Hills","state":"California","country":"US","created_at":"2013-12-09T02:33:29.023-08:00","updated_at":"2014-02-17T20:21:29.713-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"2597026","location_id":415,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.401759 34.071278)","do_not_connect_to_api":true,"merged_with_place_id":11861})
  end
end
puts "\n\n\n--------------------\n- Recreating Ullr's Sports Bar & Grill: [11858]"
if Place.where(id: 4896).any?
  place = Place.find_by(id: 11858)
  place ||= Place.find_by(place_id: 'ChIJwUk-sWb2aocRapSf2HWRa2c')
  if place.present?
    Place.find(4896).merge(place)
  else
    place = Place.create!({"id":11858,"name":"Ullr's Sports Bar \u0026 Grill","reference":"CoQBegAAAJrfj3qHEVnzmdS3VvSFKSApJiiBjX-9_UVTCZsQjP7JJPP7ee6O4fX-EK8oOqJCoPj55M80P7aUk6hjFVSSDL19M5zeobFcwwvEpfUfcf_pnCCyPcWl4BTqznP7skx3mV9bQDwy0SO1KaaVNyPYcNzPkO_mDS2qSDaRPxfj1RAvEhD5_27nkcPEdn26OOYXVbdlGhQKHr_lqeOZTRy1-foTL0sF2dC3tQ","place_id":"ChIJwUk-sWb2aocRapSf2HWRa2c","types":["bar","restaurant","food","establishment"],"formatted_address":"505 South Main Street, Breckenridge, CO 80424, United States","street_number":"505","route":"South Main Street","zipcode":"80424","city":"Breckenridge","state":"Colorado","country":"US","created_at":"2015-01-30T17:50:32.392-08:00","updated_at":"2015-02-02T12:02:16.909-08:00","administrative_level_1":"CO","administrative_level_2":nil,"td_linx_code":"1834862","location_id":286,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-106.045283 39.476369)","do_not_connect_to_api":true,"merged_with_place_id":4896})
  end
elsif Place.where(id: 11858).any?
  place = Place.find_by(id: 4896)
  place ||= Place.find_by(place_id: '71d2ca60121c76ffe0e3de65f1a539f26d78cfd5')
  if place.present?
    Place.find(11858).merge(place)
  else
    place = Place.create!({"id":4896,"name":"Ullr's Sports Bar \u0026 Grill","reference":"CoQBegAAAMzzpvg36h_3QgDcniKO5EyPc6Re92WpVQhq89xOYVQwCtXnnZESsoCLjVmLYX6QNHuqYD-Fevubp2HWj5BCVBHkF29QAADlQ7shis4_lEvLi2o9Wr39l66fSJSmiuYivcJJ45GiwsECYWypZZUK1O8EN4sToEB_gvWm1OdSZrLyEhCY9584US9LATUME0onTjk9GhT3FB-UNyhD5lW5Jftqv9n9p7d91Q","place_id":"71d2ca60121c76ffe0e3de65f1a539f26d78cfd5","types":["bar","restaurant","food","establishment"],"formatted_address":"505 S Main St, Breckenridge, CO, United States","street_number":"505","route":"S Main St","zipcode":"80424","city":"Breckenridge","state":"Colorado","country":"US","created_at":"2014-02-28T15:53:14.706-08:00","updated_at":"2015-02-02T11:59:20.748-08:00","administrative_level_1":"CO","administrative_level_2":nil,"td_linx_code":"1834862","location_id":286,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-106.045283 39.476369)","do_not_connect_to_api":true,"merged_with_place_id":11858})
  end
end
puts "\n\n\n--------------------\n- Recreating Seven Grand: [11882]"
if Place.where(id: 3317).any?
  place = Place.find_by(id: 11882)
  place ||= Place.find_by(place_id: 'ChIJd-OpVLTHwoARJ3fFiZG_xD4')
  if place.present?
    Place.find(3317).merge(place)
  else
    place = Place.create!({"id":11882,"name":"Seven Grand","reference":"CnRtAAAACsgVYz3XPfSzjGhMJ47ZG93g9RlN4O1eGtW24CzHpaROkpGFirQG11eRe00w9IfNYK6_hEnX7whjkY7Kjkpu71PjqzXD-ZCOZOI61FCR1KhA9a9QvziLtsn2Nc5pA4HtgJfLZ9Gyu402kfcW7EYq1xIQXNIDxUwtiPnb2SGzhOSG5hoUgD4em8nFMAx9Ttl3ydX2YTss9mE","place_id":"ChIJd-OpVLTHwoARJ3fFiZG_xD4","types":["bar","establishment"],"formatted_address":"515 West 7th Street #2, Los Angeles, CA 90014, United States","street_number":"515","route":"West 7th Street","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-31T13:47:05.891-08:00","updated_at":"2015-02-19T11:05:07.183-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":4,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.255863 34.047062)","do_not_connect_to_api":true,"merged_with_place_id":3317})
  end
elsif Place.where(id: 11882).any?
  place = Place.find_by(id: 3317)
  place ||= Place.find_by(place_id: '185b64eb576d1f11c2c2ddb4128042fc743cb157')
  if place.present?
    Place.find(11882).merge(place)
  else
    place = Place.create!({"id":3317,"name":"Seven Grand","reference":"CnRsAAAARH0iNbRnFtvX1bmLef5cgfQopfP2-Z42NMMYRvZXwuhvaoSAr5wm09_Gt5PKNGXvTkOq8rrikETUobiKLhaV-Hab7XNqn8HfnfPa7ETTMfXNtGq2CkPhk_JMAnN-Q1BEEvqY8mgo_MpfiurTXSw12RIQCbaRkiPk4YpskXKIRigPdxoUbzeuwMWYpMvoX5F6uE5y3fSWO2A","place_id":"185b64eb576d1f11c2c2ddb4128042fc743cb157","types":["bar","establishment"],"formatted_address":"515 West 7th Street #2, Los Angeles, CA, United States","street_number":"515","route":"West 7th Street","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2013-12-04T13:25:21.621-08:00","updated_at":"2015-02-19T11:05:08.287-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles","td_linx_code":"3874976","location_id":19,"is_location":false,"price_level":4,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.25595 34.046986)","do_not_connect_to_api":true,"merged_with_place_id":11882})
  end
end
puts "\n\n\n--------------------\n- Recreating Tasty N Alder: [12363]"
if Place.where(id: 5799).any?
  place = Place.find_by(id: 12363)
  place ||= Place.find_by(place_id: 'ChIJq6qqqmqqlVQRcApXp7G1RGg')
  if place.present?
    Place.find(5799).merge(place)
  else
    place = Place.create!({"id":12363,"name":"Tasty N Alder","reference":"CmRgAAAARY9f5NGPyTWuG-ytYm4tnsHDscWds4azfGFy92GK1DwCkAeIbxmGmOVzBnBRq5y3OsxcekzVfA52g0jdBh7OSbnQ5rCFddc7xE6ycTTeh1J0Rz-R_-Mn9RoUuPFRlhMyEhCiRBCcPYSMpJ8F2ZjYm69eGhSqndmAqJOwZH3nDsjTmP8nBr-M3Q","place_id":"ChIJq6qqqmqqlVQRcApXp7G1RGg","types":["bar","restaurant","food","establishment"],"formatted_address":"580 Southwest 12th Avenue, Portland, OR 97205, United States","street_number":"580","route":"Southwest 12th Avenue","zipcode":"97205","city":"Portland","state":"Oregon","country":"US","created_at":"2015-02-16T11:43:11.033-08:00","updated_at":"2015-02-18T10:54:49.417-08:00","administrative_level_1":"OR","administrative_level_2":nil,"td_linx_code":nil,"location_id":738,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.68362 45.521363)","do_not_connect_to_api":true,"merged_with_place_id":5799})
  end
elsif Place.where(id: 12363).any?
  place = Place.find_by(id: 5799)
  place ||= Place.find_by(place_id: '83d39000a523902fa35bb09ece206b93522d84dd')
  if place.present?
    Place.find(12363).merge(place)
  else
    place = Place.create!({"id":5799,"name":"Tasty N Alder","reference":"CnRuAAAAWkct75U3zwOxcL0gQhgvvwzaVNQ1B0qshrF4HsWF6-YCzKmOSGbvPxSqWQ36g27dQBQ5QVNyTgMYhKJ1ZJgxF7n3q4I7tBNf8oZ4SSqqIOHRDT86QC8BEx2s-b8bDjw28kB4_6nQbj8JtTWVafQ83RIQZJtPEhxOXcIrb3rPTkRmAhoUHxwp4BgT5opadYIXVc8fvgEHzjk","place_id":"83d39000a523902fa35bb09ece206b93522d84dd","types":["restaurant","food","establishment"],"formatted_address":"580 SW 12th Ave, Portland, OR, United States","street_number":"580","route":"SW 12th Ave","zipcode":"97205","city":"Portland","state":"Oregon","country":"US","created_at":"2014-04-03T12:28:31.229-07:00","updated_at":"2014-04-03T12:28:31.229-07:00","administrative_level_1":"OR","administrative_level_2":nil,"td_linx_code":"7199854","location_id":738,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.68362 45.521363)","do_not_connect_to_api":true,"merged_with_place_id":12363})
  end
end
puts "\n\n\n--------------------\n- Recreating Beelman's Pub: [12149]"
if Place.where(id: 7420).any?
  place = Place.find_by(id: 12149)
  place ||= Place.find_by(place_id: 'ChIJh-Xhn0rGwoARKY7X9WpT_Jg')
  if place.present?
    Place.find(7420).merge(place)
  else
    place = Place.create!({"id":12149,"name":"Beelman's Pub","reference":"CnRvAAAAIbSrwgi463fdM0daC3XbVLj4ZghNBa9mKwlR25zJSsGDlFNiS7W9cankKjAYcEOeVfWLrv7h3CfJgjt03QBwFoHKMg5EokpfamWyuFaQ-snVa-o9CzcQ-QBWLivNUGPlCU07U-aHWshC73dqivqxGxIQsay7t63dCeZVRJbKWsxw6RoUA_iD2a7cjsH3B2LX1lJ8LGl5Yxs","place_id":"ChIJh-Xhn0rGwoARKY7X9WpT_Jg","types":["bar","restaurant","food","establishment"],"formatted_address":"600 South Spring Street, Los Angeles, CA 90014, United States","street_number":"600","route":"South Spring Street","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2015-02-07T16:22:04.300-08:00","updated_at":"2015-02-18T11:01:20.522-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"7328441","location_id":19,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.25107 34.045591)","do_not_connect_to_api":true,"merged_with_place_id":7420})
  end
elsif Place.where(id: 12149).any?
  place = Place.find_by(id: 7420)
  place ||= Place.find_by(place_id: '957430550984af4f71fd4aadc61bcf5e37a3ce34')
  if place.present?
    Place.find(12149).merge(place)
  else
    place = Place.create!({"id":7420,"name":"Beelman's Pub","reference":"CnRwAAAAU4zDi3sEU8UA-oH_idp4ofsc8J9yF7E1bTsRCk52-kUyaFvnzwiqDWcrrPfsOedmzQO5T1m0P1dbk5dEoNqiw5-epWPzqGG1rAX5EjETyBnXuWgG_kHdzpZT0D15F8Fn_h91fE0eFzJRe9egQZvoDhIQxVWs3GcTS8qpOdZxZAPd_BoUm2tMct0IsVlTPNhnenrg1UF2-g4","place_id":"957430550984af4f71fd4aadc61bcf5e37a3ce34","types":["bar","restaurant","food","establishment"],"formatted_address":"600 S Spring St, Los Angeles, CA, United States","street_number":"600","route":"S Spring St","zipcode":"90014","city":"Los Angeles","state":"California","country":"US","created_at":"2014-07-13T13:11:54.795-07:00","updated_at":"2015-01-28T09:44:19.776-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"7328441","location_id":811,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.251128 34.045602)","do_not_connect_to_api":true,"merged_with_place_id":12149})
  end
end
puts "\n\n\n--------------------\n- Recreating Original Joe's: [12234]"
if Place.where(id: 6336).any?
  place = Place.find_by(id: 12234)
  place ||= Place.find_by(place_id: 'ChIJfSGLEfGAhYARC8Egs7nINzk')
  if place.present?
    Place.find(6336).merge(place)
  else
    place = Place.create!({"id":12234,"name":"Original Joe's","reference":"CnRwAAAA1ksveAVTDFkaxeqYT0ZWXq-t-Qnh52Ws2o452jJLTDjnDu7IgAOFnt2WqJSgmuGl7uum4NYZlZH2XprgtqjZ42tzMKV8pQ8Y5eAKYdYLtkBi4JGGaP-DUk0yey8ZZPLUeDugjuzVO8HQudgaTwdbmxIQ1UW4AT2ZZTxqxou48bf3iRoU4fOlXzKr-OXym4kFDPNpiUobV08","place_id":"ChIJfSGLEfGAhYARC8Egs7nINzk","types":["bar","restaurant","food","establishment"],"formatted_address":"601 Union Street, San Francisco, CA 94133, United States","street_number":"601","route":"Union Street","zipcode":"94133","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-09T16:28:05.677-08:00","updated_at":"2015-02-18T10:58:01.674-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5224997","location_id":35,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.409382 37.800269)","do_not_connect_to_api":true,"merged_with_place_id":6336})
  end
elsif Place.where(id: 12234).any?
  place = Place.find_by(id: 6336)
  place ||= Place.find_by(place_id: '65065e3fa93388158dc38bc319a36ac1e6a8d771')
  if place.present?
    Place.find(12234).merge(place)
  else
    place = Place.create!({"id":6336,"name":"Original Joe's","reference":"CnRwAAAACKi3ovBnZ0tM2FD7U_NNBWe5nNSuC4sbu3wGN4kwYJv3aDw_p2iUcvqcBPSAfa89bDfO9rfDh_-NxhIEnkhXg6tIlh6ACB_qs9188RozGlRBdOMnsNKKbmoufeoAM6mrmoOJF9xmoqKBiXZnfYmgkRIQsW0uJ0ze_3L7fk_6YkRIZxoUBu0tIZMz8hwBC2a4WUtFnNiJIjc","place_id":"65065e3fa93388158dc38bc319a36ac1e6a8d771","types":["restaurant","food","establishment"],"formatted_address":"601 Union St, San Francisco, CA, United States","street_number":"601","route":"Union St","zipcode":"94133","city":"San Francisco","state":"California","country":"US","created_at":"2014-04-30T22:49:29.527-07:00","updated_at":"2014-04-30T22:49:29.527-07:00","administrative_level_1":"CA","administrative_level_2":"San Francisco County","td_linx_code":"5224997","location_id":1679,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.409382 37.800269)","do_not_connect_to_api":true,"merged_with_place_id":12234})
  end
end
puts "\n\n\n--------------------\n- Recreating Wando's: [12280]"
if Place.where(id: 1).any?
  place = Place.find_by(id: 12280)
  place ||= Place.find_by(place_id: 'ChIJGVuCVjRTBogREUGxwjE1TZo')
  if place.present?
    Place.find(1).merge(place)
  else
    place = Place.create!({"id":12280,"name":"Wando's","reference":"CnRqAAAAUfBRZUw4FpGBx8_dKKjhysFJIOtQB0PvvomDVP1PO31RQlHE4KJ-VoWWS6mz1agWQ-T0EAt323yOr0GdCYs3Xmb4KugpQMWtDbB4Ql1fMVNTqy0bNLkY1FJBupXZDXF9PdyL54omMIB5zlDAxTsdMRIQ5mIVcstz99699NZo_FaVjBoUbNiJ-vD75G1NeQHXoudzS-TFbw8","place_id":"ChIJGVuCVjRTBogREUGxwjE1TZo","types":["bar","restaurant","food","establishment"],"formatted_address":"602 University Avenue, Madison, WI 53715, United States","street_number":"602","route":"University Avenue","zipcode":"53715","city":"Madison","state":"Wisconsin","country":"US","created_at":"2015-02-11T15:42:53.924-08:00","updated_at":"2015-02-18T10:57:52.742-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":nil,"location_id":4,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-89.395922 43.073367)","do_not_connect_to_api":true,"merged_with_place_id":1})
  end
elsif Place.where(id: 12280).any?
  place = Place.find_by(id: 1)
  place ||= Place.find_by(place_id: '8e8f078ef6b744cc7b879b601f7fac720016aec2')
  if place.present?
    Place.find(12280).merge(place)
  else
    place = Place.create!({"id":1,"name":"Wando's","reference":"CnRlAAAAi742bLbKh_Y6ts83aJOx3MpqUT9O0ItvXH837ot_5IWr_EnX69tEIYYhUxXqT2Wy2X-vlAQUxDU9dqc9hRYL59BWELf07eC8195wDsfDXAD85_mfVlGR10-TOwZlXgBTSK7b14COF-uh7b5axkMErRIQ2BVMqZ0B3Q8qgG2-BsoAQxoUs3fqo_qqJvF2VKysp_D2qLjpIVw","place_id":"8e8f078ef6b744cc7b879b601f7fac720016aec2","types":["bar","restaurant","food","establishment"],"formatted_address":"602 University Avenue, Madison, WI, United States","street_number":"602","route":"University Avenue","zipcode":"53715","city":"Madison","state":"Wisconsin","country":"US","created_at":"2013-10-11T13:32:29.145-07:00","updated_at":"2015-01-28T15:16:17.365-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"5046509","location_id":4,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-89.395954 43.073307)","do_not_connect_to_api":true,"merged_with_place_id":12280})
  end
end
puts "\n\n\n--------------------\n- Recreating Rick's American Cafe INCORRECT: [12245]"
if Place.where(id: 4267).any?
  place = Place.find_by(id: 12245)
  place ||= Place.find_by(place_id: 'ChIJ50UHyEWuPIgRcgnmQJBsoRw')
  if place.present?
    Place.find(4267).merge(place)
  else
    place = Place.create!({"id":12245,"name":"Rick's American Cafe INCORRECT","reference":"CoQBdgAAALp48lPZFibRpjVSIFJ_wQeC95y_V_LqBzQEw-JQM_BGnQT8P-FLAkjH4u36LS0bQX95IRbq3wo8FTXMP_1lNL1v9bKTRik5XqxrrgqQnJS6opIgc_SvkKpcl2fHqq-EnrMPP_lwiqXUZTSPctq7YqkYK3bHIVCvKel80gm99IdWEhA-wm4iIrjSSU83GEvptbHPGhSqp6-rwXt8KDM-hUHlv1kDbTaIww","place_id":"ChIJ50UHyEWuPIgRcgnmQJBsoRw","types":["cafe","food","establishment"],"formatted_address":"611 Church Street, Ann Arbor, MI 48104, United States","street_number":"611","route":"Church Street","zipcode":"48104","city":"Ann Arbor","state":"Michigan","country":"US","created_at":"2015-02-10T07:40:38.202-08:00","updated_at":"2015-02-27T10:37:31.556-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":"5583461","location_id":454,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.734418 42.274408)","do_not_connect_to_api":true,"merged_with_place_id":4267})
  end
elsif Place.where(id: 12245).any?
  place = Place.find_by(id: 4267)
  place ||= Place.find_by(place_id: '3f06722bd341a5978e197a6d21090624653fdd02')
  if place.present?
    Place.find(12245).merge(place)
  else
    place = Place.create!({"id":4267,"name":"Rick's American Cafe","reference":"CoQBdgAAAEWzHLnizC6kEFTrWHrtqf5LqBhaID_qyVIsJvpPvQO7-GoKguEWv3UgGDneD0iLx5Ntt7N87kQn3t9RPzI89_d2_mjjvFKoAqFbXtxzX1wy2FN8lwimY3_J6pz3PbNq85QNOAsk1qsYtaR8hPE9sfI6mLUe__ZzLB-i3Cx7CE0PEhCHLUJtydKyB6ID0cv3HmDJGhTy1a2S63n82Se7D3SCjjljbWkVZg","place_id":"3f06722bd341a5978e197a6d21090624653fdd02","types":["cafe","food","establishment"],"formatted_address":"611 Church St, Ann Arbor, MI, United States, 48104","street_number":"611","route":"Church St","zipcode":"48104","city":"Ann Arbor","state":"Michigan","country":"US","created_at":"2014-01-28T12:28:44.648-08:00","updated_at":"2015-02-27T10:38:20.297-08:00","administrative_level_1":"MI","administrative_level_2":nil,"td_linx_code":"5583461","location_id":454,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.734479 42.274385)","do_not_connect_to_api":true,"merged_with_place_id":12245})
  end
end
puts "\n\n\n--------------------\n- Recreating John & Pete's Fine Wine & Spirits: [1655]"
if Place.where(id: 12454).any?
  place = Place.find_by(id: 1655)
  place ||= Place.find_by(place_id: 'a1114b45126ae5cf4b77396f34e48e28d00ae673')
  if place.present?
    Place.find(12454).merge(place)
  else
    place = Place.create!({"id":1655,"name":"John \u0026 Pete's Fine Wine \u0026 Spirits","reference":"CpQBhAAAABPUSmnWIN5ZirNhYkHKMeGOu2_XELAbE9O6bLMPeblORMYU2ySBMXlgdbi68qBkrxV3oPfc36-zqHw3jb0iFGIdTefRrlswEeItMHwmK6NzfZ7MlUQ574cGKpw6KuqUz0lHdxRju8VkXCYk74EpdkSj3MnNL3Ssnl6aU5AoshJ45nyYLBHT94LokLHyiJT6uRIQEVtAUv2lgP4fCEb3hLaJtxoUL6kDbWI1gTFETxpmWXFw5gmZsZo","place_id":"a1114b45126ae5cf4b77396f34e48e28d00ae673","types":["liquor_store","food","store","establishment"],"formatted_address":"621 North La Cienega Boulevard, West Hollywood, CA, United States","street_number":"621","route":"North La Cienega Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2013-11-11T00:48:11.324-08:00","updated_at":"2014-02-17T20:11:32.444-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"0765372","location_id":891,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.376627 34.082584)","do_not_connect_to_api":true,"merged_with_place_id":12454})
  end
elsif Place.where(id: 1655).any?
  place = Place.find_by(id: 12454)
  place ||= Place.find_by(place_id: 'ChIJAbn6PLG-woARRna7-KbG5_Q')
  if place.present?
    Place.find(1655).merge(place)
  else
    place = Place.create!({"id":12454,"name":"John \u0026 Pete's Fine Wine and Spirits","reference":"CoQBdwAAAL_irH61HIjthUoqGOfWzwur7CJPp4HBof_Aox_DhfqNP1LMhndxaRBqHzsYf1rBot7ZjcEP8o1fQTiJ1V9qIA1D9gM6qA6dtTBpdD_EKL3EHmHJO9qAM-ZjrTUKyczvLcTzDnFEJlqKK_IrCP8F5pEk_9rOqQOpSIdcV8IRCoEPEhBdEPXErvg1Z_9B3ERlolE2GhSROhjabvTl_a-hCQ7Gptxo8JkwHg","place_id":"ChIJAbn6PLG-woARRna7-KbG5_Q","types":["liquor_store","store","food","establishment"],"formatted_address":"621 North La Cienega Boulevard, West Hollywood, CA 90069, United States","street_number":"621","route":"North La Cienega Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2015-02-18T12:11:32.440-08:00","updated_at":"2015-02-18T12:11:32.440-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.37665 34.082585)","do_not_connect_to_api":true,"merged_with_place_id":1655})
  end
end
puts "\n\n\n--------------------\n- Recreating The Abbey: [11955]"
if Place.where(id: 5261).any?
  place = Place.find_by(id: 11955)
  place ||= Place.find_by(place_id: 'ChIJq3zyY6--woARAsdovehTDMw')
  if place.present?
    Place.find(5261).merge(place)
  else
    place = Place.create!({"id":11955,"name":"The Abbey","reference":"CnRrAAAARAhIAJ7fCP2HMUzGhndCzSv6HyeczQs1eaBdk5YMJwa7MnfTejx-yoV6IzbO10IdloodBzDVlM1SmaOtaC6t-vEyjeTMrTC-AHuRkcVROJhG5BhOpnq-5xuqPc7yWP56KEkNcM7zGT4dyZFHVOlCjBIQtUvHnk4pxNu5yQn_g4uY3hoUZy78ZrFfCnTddVP39NV3JF-dFBo","place_id":"ChIJq3zyY6--woARAsdovehTDMw","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"692 North Robertson Boulevard, West Hollywood, CA 90069, United States","street_number":"692","route":"North Robertson Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2015-02-02T16:10:09.972-08:00","updated_at":"2015-02-02T16:10:09.972-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5247637","location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.385253 34.08342)","do_not_connect_to_api":true,"merged_with_place_id":5261})
  end
elsif Place.where(id: 11955).any?
  place = Place.find_by(id: 5261)
  place ||= Place.find_by(place_id: '3efd5878add9197f267a6ffe87d907ff0d66a03c')
  if place.present?
    Place.find(11955).merge(place)
  else
    place = Place.create!({"id":5261,"name":"The Abbey Food \u0026 Bar","reference":"CoQBdgAAACW89agARIT6DIyVTinTLtIIoiDDcyP-_mYP4C2-jTO4gR6N1K4qzgDLE7zsVCacOa2Hm-lj_6f5oeHWyxNLhLgPzv2evqkPb0JOxa4w0lBYp0BsNnEBNTMmd0u_dSLdzz-yXF_Ev1mFzsV-sevEqH-aYKggBN3m3imtD9YpMKgZEhCGp6C0YgUz0glNcKId05MqGhRwgF7FAgbFnSaBY82r3Vu2_PAMTg","place_id":"3efd5878add9197f267a6ffe87d907ff0d66a03c","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"692 N Robertson Blvd, West Hollywood, CA, United States","street_number":"692","route":"N Robertson Blvd","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2014-03-13T11:43:49.877-07:00","updated_at":"2014-03-13T11:43:49.877-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5247637","location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.385266 34.083406)","do_not_connect_to_api":true,"merged_with_place_id":11955})
  end
end
puts "\n\n\n--------------------\n- Recreating Mission Wine & Spirits 4: [12115]"
if Place.where(id: 9590).any?
  place = Place.find_by(id: 12115)
  place ||= Place.find_by(place_id: 'ChIJebjwxALBwoARPfYUkxcQ0gE')
  if place.present?
    Place.find(9590).merge(place)
  else
    place = Place.create!({"id":12115,"name":"Mission Wine \u0026 Spirits 4","reference":"CoQBegAAAHoGFtFgCp6l2xoHKHW-7b5hZjs2AoGSAqel079h2laVzbYFF4vm21Wp4JGwN2MomtcdF2pXwSCle7UKs8e7K5iUKySiqKhdoMgT34PjP5IhiTxVKlwPBG9hucug6b6OorxuFwO3QvB-FpASeb28zwvobBJ1mFY2Ll4t9d31ZUwZEhDB4CS1qMi3q6uoegw2GYm4GhS9P22MkXA2tK6gnPT5JNzW4gQ6jw","place_id":"ChIJebjwxALBwoARPfYUkxcQ0gE","types":["liquor_store","food","store","establishment"],"formatted_address":"708 South Glendale Avenue, Glendale, CA 91205, United States","street_number":"708","route":"South Glendale Avenue","zipcode":"91205","city":"Glendale","state":"California","country":"US","created_at":"2015-02-06T11:20:36.718-08:00","updated_at":"2015-02-18T11:01:28.101-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"1422636","location_id":96,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.250785 34.138666)","do_not_connect_to_api":true,"merged_with_place_id":9590})
  end
elsif Place.where(id: 12115).any?
  place = Place.find_by(id: 9590)
  place ||= Place.find_by(place_id: 'e41dd5122ed7705e5a59fd9c4353e962c8e16073')
  if place.present?
    Place.find(12115).merge(place)
  else
    place = Place.create!({"id":9590,"name":"Mission Wine \u0026 Spirits 4","reference":"CoQBeQAAAPpKD181j7EKXrZps79Lj3HAkdxdW3NEeUxp4o4Pg6z_yGjvpDj7eN0KsOAu1jVmjzi5v4kkncclZHaTyhf98KAM0smr3TdK-rGMewf_5XTG2zE5KaoVr1MoQW_kX7V7OJU5hVX3aXEWSVgQgzEYPPg8Gzm_r48zMzaqmpn6Jpo8EhCzzFLxTt0n22DmmkjTnXX_GhRmVGS0_jZ4eIlyhhYg6-Tik03IAw","place_id":"e41dd5122ed7705e5a59fd9c4353e962c8e16073","types":["liquor_store","food","store","establishment"],"formatted_address":"708 S Glendale Ave, Glendale, CA 91205, United States","street_number":"708","route":"S Glendale Ave","zipcode":"91205","city":"Glendale","state":"California","country":"US","created_at":"2014-11-04T23:03:27.829-08:00","updated_at":"2014-11-04T23:03:27.829-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"1422636","location_id":126552,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.250785 34.138666)","do_not_connect_to_api":true,"merged_with_place_id":12115})
  end
end
puts "\n\n\n--------------------\n- Recreating J. BLACK'S Feel Good Kitchen & Lounge: [12426]"
if Place.where(id: 148).any?
  place = Place.find_by(id: 12426)
  place ||= Place.find_by(place_id: 'ChIJm2xbKwy1RIYRIUhFgBs73Ts')
  if place.present?
    Place.find(148).merge(place)
  else
    place = Place.create!({"id":12426,"name":"J. BLACK'S Feel Good Kitchen \u0026 Lounge","reference":"CoQBeAAAACrFzjt42UYgTSLo-o4u06XmjiIj5tvocWq0F0C5bNVGe-hHsp1BnGhaStcFrWyknXReCD6r3nCskHC8KBouFwxp4W1lH_JR1MZuPkYUljab_y2I8aXZCp0EF--7iEkrCQgGpfMKrCnFAvac0206kDIZc77rfUK1ihyQXOdL5TCGEhAw7FHT52wnWmhaHpwlFTRAGhTX_YaUKrvdb60LfI6WlOZDp7TCGg","place_id":"ChIJm2xbKwy1RIYRIUhFgBs73Ts","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"710 B W 6th Street, Austin, TX 78701, United States","street_number":"710","route":"B W 6th Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2015-02-17T14:51:27.950-08:00","updated_at":"2015-02-18T10:54:37.062-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.750092 30.27029)","do_not_connect_to_api":true,"merged_with_place_id":148})
  end
elsif Place.where(id: 12426).any?
  place = Place.find_by(id: 148)
  place ||= Place.find_by(place_id: '4327eafc878f61056fcd8a25989f304cbea8591f')
  if place.present?
    Place.find(12426).merge(place)
  else
    place = Place.create!({"id":148,"name":"J. BLACK'S Feel Good Kitchen \u0026 Lounge","reference":"CpQBgwAAAB-gR35ZdOLZJK3eIfNNgSkktw4B45cyN7MvA7hddQ735tWBJC4uEqN8I0IDtz_G7Ujk5IngBWz44xPaTvrLiFeEQrX8idg07iAvhoCu63uJbHYX3jHLvZk4rO5rs3FK1dc2383lrAKrWfM8JGlMA3gqrTD_i9aQPXcF7k-dMUFuj5B7JbZVVj_DAnDsRQPneBIQsGRg8XlgskQy-6kYpwoJkxoU_A6c_zctWlh2uKHxIPjYK98BxmA","place_id":"4327eafc878f61056fcd8a25989f304cbea8591f","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"710 B W 6th Street, Austin, TX, United States","street_number":"710","route":"B W 6th Street","zipcode":"78701","city":"Austin","state":"Texas","country":"US","created_at":"2013-10-11T13:33:49.795-07:00","updated_at":"2014-02-17T20:04:10.314-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2221627","location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.750117 30.270227)","do_not_connect_to_api":true,"merged_with_place_id":12426})
  end
end
puts "\n\n\n--------------------\n- Recreating Caña Rum Bar: [12325]"
if Place.where(id: 9253).any?
  place = Place.find_by(id: 12325)
  place ||= Place.find_by(place_id: 'ChIJ9WyHlLfHwoARc_0kqEVS0w4')
  if place.present?
    Place.find(9253).merge(place)
  else
    place = Place.create!({"id":12325,"name":"Caña Rum Bar","reference":"CmRgAAAAJ_v-0NlHtgRfEzB6PTFCM9o83VceysbWWt5ZXJSg0zK8fAcu6SBCLiutyilx5kRdTs2YbUQTSeor2uUf5Wr7TdIfVyBJTqcDDEYgD_dKaCx3HV6hLdsvSEb6W-CnmBetEhArs_b0bOHP7BDLrYR65YC5GhQoH_1PeVVrxE1JBTe55w6doFghrg","place_id":"ChIJ9WyHlLfHwoARc_0kqEVS0w4","types":["bar","establishment"],"formatted_address":"714 West Olympic Boulevard, Los Angeles, CA 90015, United States","street_number":"714","route":"West Olympic Boulevard","zipcode":"90015","city":"Los Angeles","state":"California","country":"US","created_at":"2015-02-14T09:19:56.105-08:00","updated_at":"2015-02-18T10:54:57.214-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":4,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.263453 34.044383)","do_not_connect_to_api":true,"merged_with_place_id":9253})
  end
elsif Place.where(id: 12325).any?
  place = Place.find_by(id: 9253)
  place ||= Place.find_by(place_id: '80318729c71255b754a33f6e78352f2685fca71b')
  if place.present?
    Place.find(12325).merge(place)
  else
    place = Place.create!({"id":9253,"name":"Caña Rum Bar","reference":"CnRvAAAAuEfDzQfwE1Y2eM_lU3_vkmAjD4SioY7xE-ef7eigO389xoGUdeHO_gyHAt4D1ey5rn1jeUtcqJYFk2xEVCcqdc--eJaJ6uVGXhO9mDILRxU0XWVVgN27wo9vNQGH8497rbcyNLy8mWMJ6gLtrnryVxIQUCAqXdQOgdBzmosPdLoByhoUYG485laOANJkTXCbTYZsPeuWRts","place_id":"80318729c71255b754a33f6e78352f2685fca71b","types":["bar","establishment"],"formatted_address":"714 W Olympic Blvd, Los Angeles, CA 90015, United States","street_number":"714","route":"W Olympic Blvd","zipcode":"90015","city":"Los Angeles","state":"California","country":"US","created_at":"2014-10-27T11:40:15.524-07:00","updated_at":"2014-10-27T11:40:15.524-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"2523639","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.263453 34.044383)","do_not_connect_to_api":true,"merged_with_place_id":12325})
  end
end
puts "\n\n\n--------------------\n- Recreating Caffrey's Pub: [11915]"
if Place.where(id: 1240).any?
  place = Place.find_by(id: 11915)
  place ||= Place.find_by(place_id: 'ChIJ55q-D4AZBYgRmE_eS7OQG04')
  if place.present?
    Place.find(1240).merge(place)
  else
    place = Place.create!({"id":11915,"name":"Caffrey's Pub","reference":"CnRuAAAA_LhMdzYoXda1o7hXZxosi4tMEyEcal9yxC3bGYpnBtk0Se1UEAlkiKUqv-cQkZvqdLfFVC6-37Erh0GKumFqeyX3Mp_G08DrD6rNlozUXZEAVjCIkbBDqvaOw0RxjzDHodGg7HVZPG2wYp5FesfJGRIQcdH6QANnNMXNdYR6xWJaFBoUXUvOmgGSZ-Nrv_CIMFqTUzJjcos","place_id":"ChIJ55q-D4AZBYgRmE_eS7OQG04","types":["bar","establishment"],"formatted_address":"717 North 16th Street, Milwaukee, WI 53233, United States","street_number":"717","route":"North 16th Street","zipcode":"53233","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2015-02-01T21:42:44.495-08:00","updated_at":"2015-02-01T21:42:44.495-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"5017749","location_id":646,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.933177 43.039178)","do_not_connect_to_api":true,"merged_with_place_id":1240})
  end
elsif Place.where(id: 11915).any?
  place = Place.find_by(id: 1240)
  place ||= Place.find_by(place_id: '29a9980012d1dd7d0cff2963e535e098dee9aa80')
  if place.present?
    Place.find(11915).merge(place)
  else
    place = Place.create!({"id":1240,"name":"Caffrey's Pub","reference":"CnRmAAAAx7SS1vTmHsT3W0msn9EuFuuiCZ75fsmq9GOzzEjiYUQ9ANoXk4FTfo-g1KOkLHq8i0G_nNgFPesfTkYQAHKkqguraN_LF1u_QTw468-PqRxy7Uqtt5RKGmvc38Wb4Poh5nlb87tJ24FM-3oxaYeueRIQmm0gXcV0XO_9QaP9udW-IxoUNJ9-WZF7Pk8C3OQDdaK6_9ArgOU","place_id":"29a9980012d1dd7d0cff2963e535e098dee9aa80","types":["bar","establishment"],"formatted_address":"717 North 16th Street, Milwaukee, WI, United States","street_number":"717","route":"North 16th Street","zipcode":"53233","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2013-10-21T10:19:45.183-07:00","updated_at":"2014-02-17T20:09:04.638-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"5017749","location_id":646,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.933057 43.039132)","do_not_connect_to_api":true,"merged_with_place_id":11915})
  end
end
puts "\n\n\n--------------------\n- Recreating The Dawson: [11925]"
if Place.where(id: 1378).any?
  place = Place.find_by(id: 11925)
  place ||= Place.find_by(place_id: 'ChIJg8Oa6M0sDogR3e1jtbxfK2c')
  if place.present?
    Place.find(1378).merge(place)
  else
    place = Place.create!({"id":11925,"name":"The Dawson","reference":"CnRsAAAAYH3H1YDpbyZsB4jH3LSVnXBKGOSP49wmFtqU2Pr2vxCQojYLpEwkzBg5XdMX8Wwb2BIqm5NFaxHdkxVSFiT-1zfRLB3HOQKDKH61F9wWs6Yvtf-OTGwQAXN16EGn6tSEhdEBCSJDJ_qrr7lQHoF_fhIQEcjC2UrhmwcgsLnSKhTzyhoUeK052rJZtWgBP3VdiiuOYfYJbaQ","place_id":"ChIJg8Oa6M0sDogR3e1jtbxfK2c","types":["bar","restaurant","food","establishment"],"formatted_address":"730 West Grand Avenue, Chicago, IL 60654, United States","street_number":"730","route":"West Grand Avenue","zipcode":"60654","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-02T08:40:04.418-08:00","updated_at":"2015-02-16T14:34:57.165-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"3945967","location_id":43,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.647213 41.891294)","do_not_connect_to_api":true,"merged_with_place_id":1378})
  end
elsif Place.where(id: 11925).any?
  place = Place.find_by(id: 1378)
  place ||= Place.find_by(place_id: 'dabc15adbfcb6a1eba7ad9b9ea9c540e9bff98da')
  if place.present?
    Place.find(11925).merge(place)
  else
    place = Place.create!({"id":1378,"name":"The Dawson","reference":"CnRsAAAAv13VdTUsTXHQiKNy1XcVT_TWTFXBk2DMeX2JtCGH8FeWWQW6SIcUKEXNxkxGCR-abmnHf2ntisEmcmeMKKxtJ42K70dI0WT-gHHgYq9BRvWRXMk2_eTrKzfImZwZaDVpDw6QJ7Gfbz38nVj2TFWb5RIQOHcJup2m-utvJw9ckwh-fRoUdrAB_YkItsbv_fOqVvFAUZsiee8","place_id":"dabc15adbfcb6a1eba7ad9b9ea9c540e9bff98da","types":["bar","restaurant","food","establishment"],"formatted_address":"730 West Grand Avenue, Chicago, IL, United States","street_number":"730","route":"West Grand Avenue","zipcode":"60642","city":"Chicago","state":"Illinois","country":"US","created_at":"2013-11-04T10:38:08.155-08:00","updated_at":"2015-02-16T14:37:13.915-08:00","administrative_level_1":"IL","administrative_level_2":"Cook County","td_linx_code":"3945967","location_id":43,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.647213 41.891294)","do_not_connect_to_api":true,"merged_with_place_id":11925})
  end
end
puts "\n\n\n--------------------\n- Recreating The Wishing Well: [12348]"
if Place.where(id: 10049).any?
  place = Place.find_by(id: 12348)
  place ||= Place.find_by(place_id: 'ChIJaQrItCHGxokR3SZ082s5MlI')
  if place.present?
    Place.find(10049).merge(place)
  else
    place = Place.create!({"id":12348,"name":"The Wishing Well","reference":"CnRjAAAAokbCK9AZsfiwqCswaBt8QO_m4uE2bkSC5E1tTbwEOjWIf9yKYTwzKrrnaA1MQ2eok3WQ5Zu2VY6bhLgxGqeR8E4GG1vhlja22Fu7WnSp8CL6jF2NxVSXxUHJ9K3TWYYSZBNgjnuHFp6WxUWSEQ-9CBIQZzx56UW7tp3XJbBOW09InhoUhpy3rBN8Z7grvS2iMKFgNOT-5XQ","place_id":"ChIJaQrItCHGxokR3SZ082s5MlI","types":["bar","restaurant","food","establishment"],"formatted_address":"767 South 9th Street, Philadelphia, PA 19147, United States","street_number":"767","route":"South 9th Street","zipcode":"19147","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2015-02-16T07:49:00.597-08:00","updated_at":"2015-02-18T10:54:52.395-08:00","administrative_level_1":"PA","administrative_level_2":nil,"td_linx_code":nil,"location_id":62,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.157402 39.939811)","do_not_connect_to_api":true,"merged_with_place_id":10049})
  end
elsif Place.where(id: 12348).any?
  place = Place.find_by(id: 10049)
  place ||= Place.find_by(place_id: '5715143886fa87ef5f063387860e57c9e7be5ad7')
  if place.present?
    Place.find(12348).merge(place)
  else
    place = Place.create!({"id":10049,"name":"The Wishing Well","reference":"CoQBcQAAABC5yWe9hosaOKUAUMeObryxWkJgBHHiDe03fneiybwIYScQxM42jjpkPkJ-zLQhqvlhH6tWR8CHWaybRdnbnxYesIDOQledxzYwA_PfX6a7__gRXcq1nUadCxGdmOlwJIdp1wM372g57lFLqDtDOF14b9xMBnDW_K3f0ssKOfXrEhA1RREJYlTuzbesMOjevwLLGhQaNgQuQ3Wb6q7SwOGhYqYi7oD6kg","place_id":"5715143886fa87ef5f063387860e57c9e7be5ad7","types":["bar","restaurant","food","establishment"],"formatted_address":"767 S 9th St, Philadelphia, PA 19147, United States","street_number":"767","route":"S 9th St","zipcode":"19147","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2014-11-23T19:01:30.861-08:00","updated_at":"2014-11-23T19:01:30.861-08:00","administrative_level_1":"PA","administrative_level_2":nil,"td_linx_code":nil,"location_id":62,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.157402 39.939811)","do_not_connect_to_api":true,"merged_with_place_id":12348})
  end
end
puts "\n\n\n--------------------\n- Recreating Oya Restaurant & Lounge: [12176]"
if Place.where(id: 10703).any?
  place = Place.find_by(id: 12176)
  place ||= Place.find_by(place_id: 'ChIJYaC5iJG3t4kR_CGfZuwmxJ4')
  if place.present?
    Place.find(10703).merge(place)
  else
    place = Place.create!({"id":12176,"name":"Oya Restaurant \u0026 Lounge","reference":"CoQBegAAAKSmX62vaDmYYdLLMFdfBeDxIb3H140YpathluxzwdlvvxM9qqHnrparbwYNvhkhZj_EUdwFL-9QhwW1ghiDww3enNkOgfjeBV93nLWtSyKS__lQcwQOs_dwTLp4F8abV8-cl3bLDkgNadleN2kqINnsUGFEkqWRBqcP17M8qLPZEhBShbhVCFZgZ05lN_wcE3YeGhTvZ9trM-HnGyQFs_h4F3_WrgasWg","place_id":"ChIJYaC5iJG3t4kR_CGfZuwmxJ4","types":["bar","restaurant","food","establishment"],"formatted_address":"777 9th Street Northwest, Washington, DC 20001, United States","street_number":"777","route":"9th Street Northwest","zipcode":"20001","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-02-08T21:22:55.548-08:00","updated_at":"2015-02-18T11:01:14.972-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"5123963","location_id":538,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.023681 38.899497)","do_not_connect_to_api":true,"merged_with_place_id":10703})
  end
elsif Place.where(id: 12176).any?
  place = Place.find_by(id: 10703)
  place ||= Place.find_by(place_id: 'b5b22be78567e9e579642fa63633fd557457cb93')
  if place.present?
    Place.find(12176).merge(place)
  else
    place = Place.create!({"id":10703,"name":"Oya Restaurant \u0026 Lounge","reference":"CoQBegAAAECFprmJxBOyJpyK0suGDm-nzn_lFoGmj84dtZApnP5FQlcXedYenCHo86W8O2GbTutsSa4agDL-pioy3AqbFFGU041N8QIlf-0orNKJyIuJTfavjNPKMxWrCHK544DkRJU6x3jQJD8k6Wf8Gd5OFcGJUBiFN8V7RYZ1h8noMjYCEhAY4qR_6F0h9XlIf8b8q_KxGhRoMAHnUtEwGf3CGp3xAR5ddrmIng","place_id":"b5b22be78567e9e579642fa63633fd557457cb93","types":["bar","restaurant","food","establishment"],"formatted_address":"777 9th St NW, Washington, DC 20001, United States","street_number":"777","route":"9th St NW","zipcode":"20001","city":"Washington","state":"District of Columbia","country":"US","created_at":"2014-12-08T11:57:01.050-08:00","updated_at":"2014-12-08T11:57:01.050-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"5123963","location_id":538,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.023681 38.899497)","do_not_connect_to_api":true,"merged_with_place_id":12176})
  end
end
puts "\n\n\n--------------------\n- Recreating Pippin's Tavern: [12211]"
if Place.where(id: 262).any?
  place = Place.find_by(id: 12211)
  place ||= Place.find_by(place_id: 'ChIJ6QPIAlPTD4gRvwOcakYkLXE')
  if place.present?
    Place.find(262).merge(place)
  else
    place = Place.create!({"id":12211,"name":"Pippin's Tavern","reference":"CnRwAAAAG002cuwizTpIdJE4MjJ3IPrAS_VLZKCpixPmFdeYkRJiNXJ843kO1IjsT6ODPw0qN_-uMKRcoK8mS8rnAQZJE0G7dNgzSmY4QEHPz2CVpsapkdslX_FMCwOIpw2vGBUDtGJxjt4SIM025y0OcG35YhIQB2AS1BhSiWrv9V9GkhYsRBoU7zY2rkj3kEYi0ctfjmxqm6qeY34","place_id":"ChIJ6QPIAlPTD4gRvwOcakYkLXE","types":["bar","restaurant","food","establishment"],"formatted_address":"806 North Rush Street, Chicago, IL 60611, United States","street_number":"806","route":"North Rush Street","zipcode":"60611","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-09T11:55:03.524-08:00","updated_at":"2015-02-18T10:58:07.494-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":nil,"location_id":43,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.62583 41.897029)","do_not_connect_to_api":true,"merged_with_place_id":262})
  end
elsif Place.where(id: 12211).any?
  place = Place.find_by(id: 262)
  place ||= Place.find_by(place_id: '4d20db773357a9040fd726b3ee37c5b6c9c94a9d')
  if place.present?
    Place.find(12211).merge(place)
  else
    place = Place.create!({"id":262,"name":"Pippin's Tavern","reference":"CnRsAAAAMk2VuqMUd01mIxkkOfKyDhcB9P7mAdPlgzAKw1rSzZ1-usnvti6QdhJCHDirSslaewDNCVFk8iw4qsiwuqzQ4urEhKReBsafTyjl7S-uiGPeJOmvbpbWdGYCFvSYGsXYh3sezEOTR2wnjb_zM2HKzBIQsCkwn1-DDqbibyhAB6yJ_RoU3cJ2pqTuaeBT9kfrMI483967Kwo","place_id":"4d20db773357a9040fd726b3ee37c5b6c9c94a9d","types":["bar","restaurant","food","establishment"],"formatted_address":"806 North Rush Street, Chicago, IL, United States","street_number":"806","route":"North Rush Street","zipcode":"60611","city":"Chicago","state":"Illinois","country":"US","created_at":"2013-10-11T13:34:59.417-07:00","updated_at":"2014-02-17T20:04:44.833-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5024649","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.62583 41.897029)","do_not_connect_to_api":true,"merged_with_place_id":12211})
  end
end
puts "\n\n\n--------------------\n- Recreating Tree House: [11842]"
if Place.where(id: 9933).any?
  place = Place.find_by(id: 11842)
  place ||= Place.find_by(place_id: 'ChIJz-VJspj6MIgRwNhG4n3vgfo')
  if place.present?
    Place.find(9933).merge(place)
  else
    place = Place.create!({"id":11842,"name":"Tree House","reference":"CnRtAAAAUFbG6l-jvhcPYkjIkkgg2xcF-W9unpLSYvMW3BoUgHTvkJWNHBMNVqL-ugGit2ySSctOBV0qBL3Ke4Xz-vg6kgd3BAZ4ip7xD6cIGxohav7AgsXA1_XXrrVPX3DDGY9b6bXxsG8rDLB7uWanNnAjxRIQeZAg_EobsyDq-xIgyYRZtRoUVpcNofdLytZc52WzjuOKxkP1OQw","place_id":"ChIJz-VJspj6MIgRwNhG4n3vgfo","types":["bar","establishment"],"formatted_address":"820 College Avenue, Cleveland, OH 44113, United States","street_number":"820","route":"College Avenue","zipcode":"44113","city":"Cleveland","state":"Ohio","country":"US","created_at":"2015-01-30T13:40:06.778-08:00","updated_at":"2015-01-30T13:40:06.778-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":"5591781","location_id":945,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.685516 41.480712)","do_not_connect_to_api":true,"merged_with_place_id":9933})
  end
elsif Place.where(id: 11842).any?
  place = Place.find_by(id: 9933)
  place ||= Place.find_by(place_id: 'dfd1244ffb6b478e2f2565ce1ccb10e268b692cd')
  if place.present?
    Place.find(11842).merge(place)
  else
    place = Place.create!({"id":9933,"name":"Tree House","reference":"CnRtAAAAANQxOb0dRK5a-aEy3U6YAV2iwWnxGSQICL5ufxSIkAPypa0QNP0_oJkmBQNjF4wn0Xc5eUkV7ZY5Zn8OmleFYR_1K2qCX1Mln8ZEDJXiQPDy-6rGIBe8m_CCHriS3X2_BXuVQNFEBMDxpNU23_rj1xIQ0qoYRgbw6x1ZVJS92lMakBoUFYgFIVju7RJQ55Ja22V3bB3_Mkk","place_id":"dfd1244ffb6b478e2f2565ce1ccb10e268b692cd","types":["bar","establishment"],"formatted_address":"820 College Ave, Cleveland, OH 44113, United States","street_number":"820","route":"College Ave","zipcode":"44113","city":"Cleveland","state":"Ohio","country":"US","created_at":"2014-11-18T04:50:12.502-08:00","updated_at":"2014-11-18T04:50:12.502-08:00","administrative_level_1":"OH","administrative_level_2":"Cuyahoga County","td_linx_code":"5591781","location_id":945,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.685516 41.480712)","do_not_connect_to_api":true,"merged_with_place_id":11842})
  end
end
puts "\n\n\n--------------------\n- Recreating Nellcôte: [7798]"
if Place.where(id: 4190).any?
  place = Place.find_by(id: 7798)
  place ||= Place.find_by(place_id: 'c2f68096089266af931e2ba8162f26c75be1b2e9')
  if place.present?
    Place.find(4190).merge(place)
  else
    place = Place.create!({"id":7798,"name":"Nellcôte","reference":"CoQBdQAAAMT-9azzc1OQBIMk4__elP2JZNj9-sPL-ZHmC6RL1tirBFPAgmMdcyzPKATq4aUn1_YUhRz4SvEncDU94-v73JoPvRO6n5Kcett_eJu_vt12Fupdzy1jZlbCO-g5zjoDp5uLhzcOXo7HMDmy4v_1O-33lBzeq2sumHvvMeG5fcbcEhCHLz-ZuU6_ZYPipBdmQLZnGhQ7ABNb10WvviySn0KlRsr-_ASLBA","place_id":"c2f68096089266af931e2ba8162f26c75be1b2e9","types":["restaurant","food","point_of_interest","establishment"],"formatted_address":"Nellcôte, 833 W Randolph St, Chicago, IL 60607, USA","street_number":"833","route":"W Randolph St","zipcode":"60607","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-08-18T10:57:01.931-07:00","updated_at":"2014-08-18T10:57:01.931-07:00","administrative_level_1":"IL","administrative_level_2":"Cook County","td_linx_code":"5026658","location_id":1057,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.6489513 41.884141)","do_not_connect_to_api":true,"merged_with_place_id":4190})
  end
elsif Place.where(id: 7798).any?
  place = Place.find_by(id: 4190)
  place ||= Place.find_by(place_id: '337bd538bcc80c3a7c92d4c673b8a6ca3f7ff1ff')
  if place.present?
    Place.find(7798).merge(place)
  else
    place = Place.create!({"id":4190,"name":"Nellcôte","reference":"CnRrAAAAf9LIREiVTT_KusEp1heZTczYNEIh-hPGJ8ZmNQWCSY_jU2iMDWMcOAfmn9YNH6JyqvikTfDWu-IOEjlnHENbr-ym7Iq9Q6-XQ1AOkEEmyhZMs3KV5sZxaFUWlPHzRgBkQ3mLCD9_d8cYAsZvB6Z0bBIQJPu9VOxaSpKg33yevepe5BoUHCgGe0TYXp2QcJgkHawEFbIQ5aA","place_id":"337bd538bcc80c3a7c92d4c673b8a6ca3f7ff1ff","types":["restaurant","food","establishment"],"formatted_address":"833 West Randolph Street, Chicago, IL, United States","street_number":"833","route":"West Randolph Street","zipcode":"60607","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-01-25T16:45:28.567-08:00","updated_at":"2014-02-17T20:25:49.881-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5026658","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.648905 41.883953)","do_not_connect_to_api":true,"merged_with_place_id":7798})
  end
end
puts "\n\n\n--------------------\n- Recreating Tom Bergin's INCORRECT: [11820]"
if Place.where(id: 9272).any?
  place = Place.find_by(id: 11820)
  place ||= Place.find_by(place_id: 'ChIJn1DEwT25woAR7ZpireTp1U4')
  if place.present?
    Place.find(9272).merge(place)
  else
    place = Place.create!({"id":11820,"name":"Tom Bergin's INCORRECT","reference":"CnRuAAAAvMTBscPoFdjztVAXRIA3JkSl7bq6pf4YnBjTAX0VvDKKaKOS5sWgwmDuzrL3J1LCIrgRNVVNuFnoyyDICNEHpOIFb8cmZZcthdTER4Vq2IePiEcKyrGanWMEjCVBcCxKgecU00vBivw0RENlaZJxMBIQ4kNMxODfjk7GGI5phUGZBBoUVajhpzCjbdo6NF6wKlnrpfkqFrY","place_id":"ChIJn1DEwT25woAR7ZpireTp1U4","types":["bar","restaurant","food","establishment"],"formatted_address":"840 South Fairfax Avenue, Los Angeles, CA 90036, United States","street_number":"840","route":"South Fairfax Avenue","zipcode":"90036","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-29T20:46:20.335-08:00","updated_at":"2015-02-27T10:56:29.870-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5246372","location_id":19,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.362717 34.060066)","do_not_connect_to_api":true,"merged_with_place_id":9272})
  end
elsif Place.where(id: 11820).any?
  place = Place.find_by(id: 9272)
  place ||= Place.find_by(place_id: '949ce987d613046782e4a8f0b27f220931f30ae8')
  if place.present?
    Place.find(11820).merge(place)
  else
    place = Place.create!({"id":9272,"name":"Tom Bergin's ","reference":"CnRtAAAAX_6Lzd1a7Rychte6D4VzSGOLgL-AunrCWtlkUSiQK3bGwdetf0RCApwlu8iAqBFAT3lqGiRGZm9nvgIOSvLSu0BtO13JHbRcpAKAkw1NEzVru3G34Zr0IHWv0NnyTOlCLdGMY4-xl-BHBkY9G-t0VhIQbg14dsXlQYSgHjDEgXIQNxoUtnox-DzupfO2tZA3XXJQebd7bBc","place_id":"949ce987d613046782e4a8f0b27f220931f30ae8","types":["bar","restaurant","food","establishment"],"formatted_address":"840 S Fairfax Ave, Los Angeles, CA 90036","street_number":"840","route":"S Fairfax Ave","zipcode":"90036","city":"Los Angeles","state":"California","country":"US","created_at":"2014-10-28T08:13:22.847-07:00","updated_at":"2015-02-27T10:55:56.199-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5246372","location_id":19,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.362717 34.060066)","do_not_connect_to_api":true,"merged_with_place_id":11820})
  end
end
puts "\n\n\n--------------------\n- Recreating Whiskey's Smokehouse: [12170]"
if Place.where(id: 1194).any?
  place = Place.find_by(id: 12170)
  place ||= Place.find_by(place_id: 'ChIJFbXWuA9644kRxnorjH_gg1s')
  if place.present?
    Place.find(1194).merge(place)
  else
    place = Place.create!({"id":12170,"name":"Whiskey's Smokehouse","reference":"CoQBdQAAAGrHLo_PR-_x9JcWGGF6myd1JtfKI0OGJWBrI8yC35SadAIoZoNHHHqd2ibX3rlgj0Ruscw8zI5V1VcMsPFy81aOubyfniCtbiK4Iy6eFIQJ9JSQRir4Fa6G3L5KLLzT-uYI_pX8nv7gbMhabUjhtUBiLlpg5t0flGzCXckblF4PEhC53gfOsx-hM4vxJPgekXrQGhQWvjrSWpfdypJyp929oaoGgzLBoA","place_id":"ChIJFbXWuA9644kRxnorjH_gg1s","types":["bar","restaurant","food","establishment"],"formatted_address":"885 Boylston Street, Boston, MA 02116, United States","street_number":"885","route":"Boylston Street","zipcode":"02116","city":"Boston","state":"Massachusetts","country":"US","created_at":"2015-02-08T16:20:41.985-08:00","updated_at":"2015-02-18T11:01:16.447-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":nil,"location_id":93,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.083687 42.34864)","do_not_connect_to_api":true,"merged_with_place_id":1194})
  end
elsif Place.where(id: 12170).any?
  place = Place.find_by(id: 1194)
  place ||= Place.find_by(place_id: '3204374a22c0e72aa81180ac37dd6973aa63f61c')
  if place.present?
    Place.find(12170).merge(place)
  else
    place = Place.create!({"id":1194,"name":"Whiskey's Smokehouse","reference":"CnRtAAAAaHTc-gkHQGX85Ok01Ur0Kl-qjw9K9qYFZDTUi8xn8Gp9nzT-7w9AWhNnduSLTtfl3whKk4q9G9hUeQKwipBM-oJnE8qjV29CMFrxd3fGk7ZpNYkj34fRlAGeViz3X9SmetPsGSMJ6iG7ifZ4gQjmQBIQ0dfMQvDAsmx8xCGWBYe32BoUt1kWqSvte8Y6twbUQp7PZrrGKP4","place_id":"3204374a22c0e72aa81180ac37dd6973aa63f61c","types":["bar","restaurant","food","establishment"],"formatted_address":"885 Boylston Street, Boston, MA, United States","street_number":"885","route":"Boylston Street","zipcode":"02116","city":"Boston","state":"Massachusetts","country":"US","created_at":"2013-10-17T18:00:26.299-07:00","updated_at":"2014-02-17T20:08:50.087-08:00","administrative_level_1":"MA","administrative_level_2":nil,"td_linx_code":"5129272","location_id":93,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.083654 42.348505)","do_not_connect_to_api":true,"merged_with_place_id":12170})
  end
end
puts "\n\n\n--------------------\n- Recreating Brother Jimmy's Barbeque.: [2018]"
if Place.where(id: 11997).any?
  place = Place.find_by(id: 2018)
  place ||= Place.find_by(place_id: '44d92d7bd52dfb2fa91c84907a938a9c32ce7f99')
  if place.present?
    Place.find(11997).merge(place)
  else
    place = Place.create!({"id":2018,"name":"Brother Jimmy's Barbeque.","reference":"CoQBewAAAAt1BvwZoPwKY3KbUX6ObIhbgePM2XQhgw9UZ4PUS6W79_l1OwQQZBWTEcgxqqFk_qZBXG1DMPTBsP3RDbTpG9C-blwni4HDPTiarRptMftc1Z_rkO3Wtwtoxp0nxKwswfDQ0DbH4BSGPvXG_ol0GeR8eN4422jh6FcnjFwKJ4DHEhAlfgzVSStZo5XJZKooCt8WGhT079Ly45FreXcsRb3uw2hN-Gi5tA","place_id":"44d92d7bd52dfb2fa91c84907a938a9c32ce7f99","types":["restaurant","food","establishment"],"formatted_address":"900 South Miami Avenue, Miami, FL, United States","street_number":"900","route":"South Miami Avenue","zipcode":"33130","city":"Miami","state":"Florida","country":"US","created_at":"2013-11-11T00:50:22.112-08:00","updated_at":"2014-02-17T20:13:39.242-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"2240407","location_id":690,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.194099 25.765057)","do_not_connect_to_api":true,"merged_with_place_id":11997})
  end
elsif Place.where(id: 2018).any?
  place = Place.find_by(id: 11997)
  place ||= Place.find_by(place_id: 'ChIJvbXCcYS22YgR0nZZzyu3Wis')
  if place.present?
    Place.find(2018).merge(place)
  else
    place = Place.create!({"id":11997,"name":"Brother Jimmy's BBQ Brickell","reference":"CoQBfQAAAFsRIEvqxhehpiOFMaVAfop31Iu3FQP_0ojCWSQIW5kU3GLjY6ru6qqnXhDfExazeFdbvD1IXtGLVurIdl4lGmU7ZadT2n9U2IJ06UILDdHAyVZY8pY8NfaSZx61uDCbIN0avrw89eYkpjAIZKcmlUh2HO88cKL7smH6bMLmcF6ZEhBvE4s4Y36jjHlc0qMUS4aXGhSs9uz7WXMEbXxozqdpRdhazrs8rw","place_id":"ChIJvbXCcYS22YgR0nZZzyu3Wis","types":["bar","restaurant","food","establishment"],"formatted_address":"900 South Miami Avenue, Miami, FL 33130, United States","street_number":"900","route":"South Miami Avenue","zipcode":"33130","city":"Miami","state":"Florida","country":"US","created_at":"2015-02-03T11:43:14.874-08:00","updated_at":"2015-02-03T11:43:14.874-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"7048121","location_id":690,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.194099 25.765057)","do_not_connect_to_api":true,"merged_with_place_id":2018})
  end
end
puts "\n\n\n--------------------\n- Recreating Brooklyn's At the Pepsi Center: [11826]"
if Place.where(id: 8848).any?
  place = Place.find_by(id: 11826)
  place ||= Place.find_by(place_id: 'ChIJsRODlcd4bIcRg1OK-N72S6w')
  if place.present?
    Place.find(8848).merge(place)
  else
    place = Place.create!({"id":11826,"name":"Brooklyn's At the Pepsi Center","reference":"CoQBgAAAAKIy5oCpiQhHBzu2y2sJc1D2o4TmzJlORLoLneEZ9wF8OWtUvkAnmHFRblHXnxLWJnPkabBp05yjGurmct3xmqS92LvUbF9pxlImM9FTENdt37d4qX5eUCA0w2q7HgVqdq9mlV4GfYNpH9_ClBwpWu798LdAloLDrCKFwNbotky-EhDJUWJkVOWZSbzQwj3z9fnEGhRRIYWfoqcpkwNqluMTqQgfY3JqZA","place_id":"ChIJsRODlcd4bIcRg1OK-N72S6w","types":["bar","establishment"],"formatted_address":"901 Auraria Parkway, Denver, CO 80204, United States","street_number":"901","route":"Auraria Parkway","zipcode":"80204","city":"Denver","state":"Colorado","country":"US","created_at":"2015-01-30T07:25:00.113-08:00","updated_at":"2015-01-30T07:25:00.113-08:00","administrative_level_1":"CO","administrative_level_2":nil,"td_linx_code":"5210827","location_id":40,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-105.007625 39.747021)","do_not_connect_to_api":true,"merged_with_place_id":8848})
  end
elsif Place.where(id: 11826).any?
  place = Place.find_by(id: 8848)
  place ||= Place.find_by(place_id: '7d86067ca96d1888b9ef87f2154f2ffb0608673e')
  if place.present?
    Place.find(11826).merge(place)
  else
    place = Place.create!({"id":8848,"name":"Brooklyn's At the Pepsi Center","reference":"CpQBgQAAAKQhLyqrgctSKmM73frC4OfnoeaVV0hg4tJOX0eYjNVszewhxgIJwB60oCRMEZ1c2E7GYFCZguYBza60RzSJUV8lK6yaj5ALuSe9IdP32DR0TIuX2FwNKTRugvPkqnWIkKJqeg3CMKzrwmPPbMIg9NNsm-Lzs5ZoG_ec7-mxdz6xyFo5zGH1XGdkcvyhmz834hIQgi9_FN9t9X-rDlFqzTAE6hoUwD8MDOKTk6kCE_N35uCoIgnbBj4","place_id":"7d86067ca96d1888b9ef87f2154f2ffb0608673e","types":["bar","establishment"],"formatted_address":"901 Auraria Pkwy, Denver, CO 80204, United States","street_number":"901","route":"Auraria Pkwy","zipcode":"80204","city":"Denver","state":"Colorado","country":"US","created_at":"2014-10-13T22:46:30.460-07:00","updated_at":"2014-10-13T22:46:30.460-07:00","administrative_level_1":"CO","administrative_level_2":nil,"td_linx_code":"5210827","location_id":40,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-105.007625 39.747021)","do_not_connect_to_api":true,"merged_with_place_id":11826})
  end
end
puts "\n\n\n--------------------\n- Recreating Morrissey's Irish Pub: [11781]"
if Place.where(id: 4756).any?
  place = Place.find_by(id: 11781)
  place ||= Place.find_by(place_id: 'ChIJpVLNg4Yn9ocRnhnZ19b02jc')
  if place.present?
    Place.find(4756).merge(place)
  else
    place = Place.create!({"id":11781,"name":"Morrissey's Irish Pub","reference":"CoQBdgAAAJsmJ4XhQx6ysdjpkNrIvGpjokybICa1QnstHk0p89uN075_c2NF5B3Q8Tj9BSMRpi2g6c6SgpGu2zO0t_29rr2JZf4vydJHGisFri3vmdcHA1u0KBTjKuquiCZhAZ1qpDhsoXaZtY5sBAPhLqZHKGcJTjvgZLyf1rlqin3rMWYeEhAQhlVXubTbyWgvkXb-NYqkGhQWydYV9R2Kz3U2XRyM0qj9W52UEA","place_id":"ChIJpVLNg4Yn9ocRnhnZ19b02jc","types":["bar","restaurant","food","establishment"],"formatted_address":"913 West Lake Street, Minneapolis, MN 55408, United States","street_number":"913","route":"West Lake Street","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2015-01-28T11:09:47.639-08:00","updated_at":"2015-01-28T11:09:47.639-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"1461205","location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.291398 44.948178)","do_not_connect_to_api":true,"merged_with_place_id":4756})
  end
elsif Place.where(id: 11781).any?
  place = Place.find_by(id: 4756)
  place ||= Place.find_by(place_id: '00db671de9da7f0fc75619309fd2f0f2e7c7f27f')
  if place.present?
    Place.find(11781).merge(place)
  else
    place = Place.create!({"id":4756,"name":"Morrissey's Irish Pub","reference":"CoQBdwAAACvKACoSwDVGOrM2JAjk2hKzB-NMJ9eIZxwIEW-rL2XCLvjAmAb4-ihpsdT0_LD_CO6iAjhhE9NKf8wjE-NhN0y-VNa7rPD0g4eFm89pJRjCB5ZecVnRkSGiGylrm9V0_CxIZmiiVS9vdFXuQPYXQ8wOhOVyzpK64_SAtvP4rmRkEhDEOZoazmuqvGZZxa1TMCgMGhTaTogfM_4mtgB7r7zYDlcndnLPeQ","place_id":"00db671de9da7f0fc75619309fd2f0f2e7c7f27f","types":["bar","restaurant","food","establishment"],"formatted_address":"913 W Lake St, Minneapolis, MN, United States","street_number":"913","route":"W Lake St","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2014-02-20T17:25:11.258-08:00","updated_at":"2014-02-20T17:25:11.258-08:00","administrative_level_1":"MN","administrative_level_2":"Hennepin County","td_linx_code":"1461205","location_id":1273,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.291418 44.948257)","do_not_connect_to_api":true,"merged_with_place_id":11781})
  end
end
puts "\n\n\n--------------------\n- Recreating Plan B: [11917]"
if Place.where(id: 8237).any?
  place = Place.find_by(id: 11917)
  place ||= Place.find_by(place_id: 'ChIJS18nFnJTBogRzNfj4A5H8lg')
  if place.present?
    Place.find(8237).merge(place)
  else
    place = Place.create!({"id":11917,"name":"Plan B","reference":"CnRoAAAASY-3s4zt45vCOGN0MKhutNqW6jnn8WuP8gjlEnL5aLd2gGMjWSd9nyjp-cPvTS6bmx1BVOf8E1BgsmpPmsA7TSh5kgZcYnzqE8y2gzAoOHW3-K4l-4UvtX26nYE5PCsyP7-o_ujwHgAiDMxbE86I_hIQu3OmE-8ErFBNF7qlCLj68RoU-swXjxdZ4j3fgrKrDGYMZ7pMEy0","place_id":"ChIJS18nFnJTBogRzNfj4A5H8lg","types":["night_club","bar","establishment"],"formatted_address":"924 Williamson Street, Madison, WI 53703, United States","street_number":"924","route":"Williamson Street","zipcode":"53703","city":"Madison","state":"Wisconsin","country":"US","created_at":"2015-02-01T22:24:16.709-08:00","updated_at":"2015-02-01T22:24:16.709-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"3629346","location_id":4,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-89.369251 43.080168)","do_not_connect_to_api":true,"merged_with_place_id":8237})
  end
elsif Place.where(id: 11917).any?
  place = Place.find_by(id: 8237)
  place ||= Place.find_by(place_id: '6d3500747e3abc247565ec84b9494dd4aa87ac56')
  if place.present?
    Place.find(11917).merge(place)
  else
    place = Place.create!({"id":8237,"name":"Plan B","reference":"CnRoAAAAKIyZPnwvlLmb_vy0GRK-Eqb_4z-_YCmwcXDe-Da4xuIk9cN7KNSOsExB4LBCYdmkWuJKnYdWOKWRBj4Ao9jQSNwOErpOaOm3FiFR0r-IwnPM7_GsBBeo7dE8mwcWdp-no3sL-8Iso1cS2Z2bdRkpLBIQGBViFaXWsU0bsqa5bFOimxoUfOKH6wSJekYeePdcmwm83lw8ACE","place_id":"6d3500747e3abc247565ec84b9494dd4aa87ac56","types":["night_club","bar","establishment"],"formatted_address":"924 Williamson St, Madison, WI, United States","street_number":"924","route":"Williamson St","zipcode":"53703","city":"Madison","state":"Wisconsin","country":"US","created_at":"2014-09-19T18:33:38.055-07:00","updated_at":"2015-01-29T23:29:37.891-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"3629346","location_id":4,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-89.369251 43.080168)","do_not_connect_to_api":true,"merged_with_place_id":11917})
  end
end
puts "\n\n\n--------------------\n- Recreating canon: whiskey and bitters emporium: [12275]"
if Place.where(id: 4431).any?
  place = Place.find_by(id: 12275)
  place ||= Place.find_by(place_id: 'ChIJTQLM3M5qkFQRSPbIugsT_H0')
  if place.present?
    Place.find(4431).merge(place)
  else
    place = Place.create!({"id":12275,"name":"canon: whiskey and bitters emporium","reference":"CpQBhQAAAMjNwS0hb4Dh1K_mrtGPXO7zT4X7Kz5rqvIYyV2SGtOyjhLEEW8IGCJPW1tjVVTO1VC5U5CyMmcvjIHv7OoaTkJtc0SVtOTiJWSKjmJCuiwdKLiVybuYS3BN7q4Z_1Z4gXauDZRsRIF_hL0AaecgZL5KPBXM-RmeG_c9FSPXbN0Ow3iJXQ4ZCFae-DYUwlP1vBIQYR8ov3hMCtC02Id55KeXhhoUq7GyX6gBcy75G2xlPGoWdt46xaw","place_id":"ChIJTQLM3M5qkFQRSPbIugsT_H0","types":["bar","restaurant","food","establishment"],"formatted_address":"928 12th Avenue, Seattle, WA 98122, United States","street_number":"928","route":"12th Avenue","zipcode":"98122","city":"Seattle","state":"Washington","country":"US","created_at":"2015-02-11T14:35:53.687-08:00","updated_at":"2015-02-18T10:57:53.645-08:00","administrative_level_1":"WA","administrative_level_2":nil,"td_linx_code":nil,"location_id":30,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.316539 47.611277)","do_not_connect_to_api":true,"merged_with_place_id":4431})
  end
elsif Place.where(id: 12275).any?
  place = Place.find_by(id: 4431)
  place ||= Place.find_by(place_id: '47f74ffc6827a980676b0527d902355f5a448ed5')
  if place.present?
    Place.find(12275).merge(place)
  else
    place = Place.create!({"id":4431,"name":"canon: whiskey and bitters emporium","reference":"CpQBhAAAAN49YXSzXJ_tdjxgiXwweZ1hEvOKYiKFJvfxGvuj9lUwUWkEIoFN1ZUakm5_wnpS_fjSjMC2keamWtRbZ_JieQ_MeZ8c8J1gaUoGQfu9DaFX7SpZULoDh1dUM8UDKcp9Y_V_JPRRglz5i0ZlCZozpMcW2bs2MeaRWZ8nLYGY49vq2eDCKrSLpvUQmswc6RucABIQMLxKeeJGmT-xaYD4evFROxoU4ycgrt0OO5lnr6zCGVig63QXSPo","place_id":"47f74ffc6827a980676b0527d902355f5a448ed5","types":["bar","restaurant","food","establishment"],"formatted_address":"928 12th Ave, Seattle, WA, United States","street_number":"928","route":"12th Ave","zipcode":"98122","city":"Seattle","state":"Washington","country":"US","created_at":"2014-01-31T20:43:20.111-08:00","updated_at":"2014-02-17T20:27:07.784-08:00","administrative_level_1":"WA","administrative_level_2":nil,"td_linx_code":"2132617","location_id":30,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.31659 47.611279)","do_not_connect_to_api":true,"merged_with_place_id":12275})
  end
end
puts "\n\n\n--------------------\n- Recreating The News Room: [12320]"
if Place.where(id: 5065).any?
  place = Place.find_by(id: 12320)
  place ||= Place.find_by(place_id: 'ChIJ5edqYJYys1IR4Qs1AHmx7rU')
  if place.present?
    Place.find(5065).merge(place)
  else
    place = Place.create!({"id":12320,"name":"The News Room","reference":"CnRhAAAAE1b20nuOYKOtU_LyVDW3Fqg4vDxqo_98DHoijcV-5DeuTFrRzp1Jof1jGMDkbk2BmNN7UFpozWDn5HBFL3U5QNaHntRcDKoKfTt9ufvNH0iEhlNKFNnWaUscmPeRf8Miyjzbin_nlQTKMzXgiOrCdRIQD3Vl3PsKmEE16gnBEUiFzhoULfjvJIt20h1Bgd400FIdRKx9raM","place_id":"ChIJ5edqYJYys1IR4Qs1AHmx7rU","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"990 Nicollet Mall, Minneapolis, MN 55403, United States","street_number":"990","route":"Nicollet Mall","zipcode":"55403","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2015-02-13T14:33:09.148-08:00","updated_at":"2015-02-18T10:54:58.162-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":nil,"location_id":12,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.274801 44.974206)","do_not_connect_to_api":true,"merged_with_place_id":5065})
  end
elsif Place.where(id: 12320).any?
  place = Place.find_by(id: 5065)
  place ||= Place.find_by(place_id: '15c48c4f3684ebd28b4e13fdbf404c2b3b7c3056')
  if place.present?
    Place.find(12320).merge(place)
  else
    place = Place.create!({"id":5065,"name":"The News Room","reference":"CnRvAAAA0eT3f5FebsfbFZ20pK7WAx_htujM8B45TNoTlPTs1PCX9VIJ9P_un7543NMofsyLumeKn-Tp8iTlCFqjIXjo2o119a7UF5SXX86-uoq54fEVZNi-gHj_cJizh74uMvwkpge4ofHxQGUZa6j40S1rHhIQAA6TOie1akBuG-1xAQoyxBoUQSC4unfB9mBhP65kHZ6KqRNM6YQ","place_id":"15c48c4f3684ebd28b4e13fdbf404c2b3b7c3056","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"990 Nicollet Mall, Minneapolis, MN, United States","street_number":"990","route":"Nicollet Mall","zipcode":"55403","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2014-03-07T19:01:25.394-08:00","updated_at":"2014-03-07T19:01:25.394-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"3815099","location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.274755 44.974136)","do_not_connect_to_api":true,"merged_with_place_id":12320})
  end
end
puts "\n\n\n--------------------\n- Recreating Ace's: [12369]"
if Place.where(id: 75).any?
  place = Place.find_by(id: 12369)
  place ||= Place.find_by(place_id: 'ChIJ63DdwJOAhYARX262QiRI8bU')
  if place.present?
    Place.find(75).merge(place)
  else
    place = Place.create!({"id":12369,"name":"Ace's","reference":"CmRZAAAAtzRGVl90tIHPH64oLztVLRM1t69AvjtCtHfFzdwPl6rDLpuYAeT7Wvw4L9s0NrKWpOjzOdL4_MvC1wVZhzw6AnUBJpP9HpugjNAUfetWBYBuWUJLNbY-dz8BVAm3eAj7EhA_m41G4Hr4CAQV9JozmeOAGhRuFLAMpG-iZPDEHKTWDQAYD4emdA","place_id":"ChIJ63DdwJOAhYARX262QiRI8bU","types":["bar","establishment"],"formatted_address":"998 Sutter Street, San Francisco, CA 94109, United States","street_number":"998","route":"Sutter Street","zipcode":"94109","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-16T16:55:15.262-08:00","updated_at":"2015-02-18T10:54:48.226-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":35,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.416794 37.788423)","do_not_connect_to_api":true,"merged_with_place_id":75})
  end
elsif Place.where(id: 12369).any?
  place = Place.find_by(id: 75)
  place ||= Place.find_by(place_id: '1582e71288c4769ccf0bd9b119836ff1d93ff014')
  if place.present?
    Place.find(12369).merge(place)
  else
    place = Place.create!({"id":75,"name":"Ace's","reference":"CnRkAAAAq6CM8pwCu2UVnQgOJ7N5zVrZsevSe6SpiJNpMhOiRi8QQcS0cUjpXJQVAuYUiiHkSH9aGkbBm_FGDcyjvRdtaMUbANPAYMpYl_dvNDJMP7_uBj-cYI2Ofka9p2eTr79apWzkQbKta-Jvk8tunMewNhIQdnZ8TQIt5BiTMw458nf6SBoUUxzsYOXUqxw1idyJ8GVWzJ0bvJQ","place_id":"1582e71288c4769ccf0bd9b119836ff1d93ff014","types":["bar","establishment"],"formatted_address":"998 Sutter Street, San Francisco, CA, United States","street_number":"998","route":"Sutter Street","zipcode":"94109","city":"San Francisco","state":"California","country":"US","created_at":"2013-10-11T13:33:11.320-07:00","updated_at":"2014-02-17T20:03:43.918-08:00","administrative_level_1":"CA","administrative_level_2":"San Francisco","td_linx_code":"5244639","location_id":35,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.416707 37.788283)","do_not_connect_to_api":true,"merged_with_place_id":12369})
  end
end
puts "\n\n\n--------------------\n- Recreating Republic National Distributing Company: [12305]"
if Place.where(id: 5938).any?
  place = Place.find_by(id: 12305)
  place ||= Place.find_by(place_id: 'ChIJEYQOE9iAToYRkAfXHhxPcF8')
  if place.present?
    Place.find(5938).merge(place)
  else
    place = Place.create!({"id":12305,"name":"Republic National Distributing Company","reference":"CpQBhwAAAAvFEYHSxa_JBnMERTsMPe4lVRj2tRGS4bVhflCU63xHeZhGvxPcFetyzrzCH8DgdnrWFyjO5o2rdspx9Tax2Dvjjime80375RananCfQ3NMvuG7SXS9b0hUgsFLd1VXWYpIaVBQavpRPj1HbZIhdT4d8OxGgLe6EoMGI6ozsL_xhuMpW2rMU3w9oeWRZpxikRIQjlaQarjTjp2sYqAAaQ8qexoUDSomqLjW2x-J4D7jEhElF178j2o","place_id":"ChIJEYQOE9iAToYRkAfXHhxPcF8","types":["food","establishment"],"formatted_address":"1010 Isuzu Parkway, Grand Prairie, TX 75050, United States","street_number":"1010","route":"Isuzu Parkway","zipcode":"75050","city":"Grand Prairie","state":"Texas","country":"US","created_at":"2015-02-12T14:11:15.082-08:00","updated_at":"2015-02-18T10:57:48.415-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":549,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.050853 32.80297)","do_not_connect_to_api":true,"merged_with_place_id":5938})
  end
elsif Place.where(id: 12305).any?
  place = Place.find_by(id: 5938)
  place ||= Place.find_by(place_id: '057d8947efc8bc706e412630c7a96dd8ddda5066')
  if place.present?
    Place.find(12305).merge(place)
  else
    place = Place.create!({"id":5938,"name":"Republic National Distributing Company","reference":"CpQBhwAAAP6WFviiVO0XVV0NL513CcQZET0J6BZNXgzbU2VRxZxrbhEEF1Ym1c2CHFEBR9BZ_EZpBgA7jYNpDIScsVvJA3Pqn9RMG_TL1tCnKgv_Zu88kQGajx_xNGERAyYuXPsQSU2zVg6UAOYACJYFO3Z3t8vfVvKcfsr6sPYPkq4qzSCOxamR4Ry0E5fMV24FC9qxYRIQU-V9eUyu6Wg9rSMLYFGiERoU-hOelpVUNXW3dUFh1h22HfX4yoQ","place_id":"057d8947efc8bc706e412630c7a96dd8ddda5066","types":["food","establishment"],"formatted_address":"1010 Isuzu Pkwy, Grand Prairie, TX, United States","street_number":"1010","route":"Isuzu Pkwy","zipcode":"75050","city":"Grand Prairie","state":"Texas","country":"US","created_at":"2014-04-12T11:56:33.967-07:00","updated_at":"2014-04-12T11:56:33.967-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5200641","location_id":549,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.050746 32.802999)","do_not_connect_to_api":true,"merged_with_place_id":12305})
  end
end
puts "\n\n\n--------------------\n- Recreating The London West Hollywood: [12152]"
if Place.where(id: 10700).any?
  place = Place.find_by(id: 12152)
  place ||= Place.find_by(place_id: 'ChIJl9d0lKO-woARCzjfK8vVuyo')
  if place.present?
    Place.find(10700).merge(place)
  else
    place = Place.create!({"id":12152,"name":"The London West Hollywood","reference":"CoQBegAAAMCdI4dmdb59eMC52Bv9DBpRqi2XLrvmsTwMBNYjGrlNNYAJC5mEdqvU0iAlHFVsj2eam2f8-hBEr7rahSv7z9q6dtRboGMwKChX9x_jP1LRozY72SU9eXvY43Ov60qJlDdothO2hOKQy8MWzN_3lvglE6vcmcC8GWDt21FOc_aUEhCAHOBwoGVldo2QqnNZFtNfGhSzkqmkBorULw8-kfg1Npt8_xYoDg","place_id":"ChIJl9d0lKO-woARCzjfK8vVuyo","types":["lodging","establishment"],"formatted_address":"1020 North San Vicente Boulevard, West Hollywood, CA 90069, United States","street_number":"1020","route":"North San Vicente Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2015-02-07T16:26:54.089-08:00","updated_at":"2015-02-18T11:01:19.704-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":21,"is_location":false,"price_level":3,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.38539 34.08979)","do_not_connect_to_api":true,"merged_with_place_id":10700})
  end
elsif Place.where(id: 12152).any?
  place = Place.find_by(id: 10700)
  place ||= Place.find_by(place_id: '34446058ef35cc9e6ca9e1efc61c7d0cbd91ae07')
  if place.present?
    Place.find(12152).merge(place)
  else
    place = Place.create!({"id":10700,"name":"The London West Hollywood","reference":"CoQBegAAAPan4PETxOk8-rIg73jgckkxU0_Q1Qwtg6oudtEH4J-2bByxFge_NJfFeamxuO-S52SqVDg-y46aVRk3ESugsOOWu1OXswKd-ICR-i00pBOjLzuL-y8cKKnHeSPQhJ9zMSkhqmmxZdFAxN8VHOGaLYI72PTc7gQAmNFfAagMeLMZEhBhryxG-iwa6L6ZY8eNBN39GhRXEq2qpIvTjaEGRkAmhpBxjeoUkA","place_id":"34446058ef35cc9e6ca9e1efc61c7d0cbd91ae07","types":["lodging","establishment"],"formatted_address":"1020 N San Vicente Blvd, West Hollywood, CA 90069, United States","street_number":"1020","route":"N San Vicente Blvd","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2014-12-08T11:33:16.363-08:00","updated_at":"2014-12-08T11:33:16.363-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.38539 34.08979)","do_not_connect_to_api":true,"merged_with_place_id":12152})
  end
end
puts "\n\n\n--------------------\n- Recreating Hugo's Frog Bar & Fish House: [12334]"
if Place.where(id: 8026).any?
  place = Place.find_by(id: 12334)
  place ||= Place.find_by(place_id: 'ChIJ641D6FHTD4gRajt2EFh0A5Y')
  if place.present?
    Place.find(8026).merge(place)
  else
    place = Place.create!({"id":12334,"name":"Hugo's Frog Bar \u0026 Fish House","reference":"CnRwAAAAAc2ZweKYUtJ0rF7JVj2SOD8rPN65vKqD_OMK3e7xZZW7lyo3fpgke_MNl7fXUG_5_c3ICzVqFYH-7tGSvoO-XbOqUhDCWb3Si0UhRCwD2AlMBCNXjPEpCUtEMdhaTZcvwmpn2W7q-zue-Js2pmop3BIQ-XhM-SA3HVohnRi6jVlfRxoU-5iysjao1wz-dWv1rUPxV_eam_Y","place_id":"ChIJ641D6FHTD4gRajt2EFh0A5Y","types":["bar","restaurant","food","establishment"],"formatted_address":"1024 North Rush Street, Chicago, IL 60611, United States","street_number":"1024","route":"North Rush Street","zipcode":"60611","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-15T10:13:30.388-08:00","updated_at":"2015-02-18T10:54:55.313-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":nil,"location_id":43,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.628015 41.90116)","do_not_connect_to_api":true,"merged_with_place_id":8026})
  end
elsif Place.where(id: 12334).any?
  place = Place.find_by(id: 8026)
  place ||= Place.find_by(place_id: '52c3d4db3a0835659e2279f285775f449a49c33b')
  if place.present?
    Place.find(12334).merge(place)
  else
    place = Place.create!({"id":8026,"name":"Hugo's Frog Bar \u0026 Fish House","reference":"CoQBfgAAAJn_321aFZ6uS2TnrbY5cyZo7bOb4O4jIWw0LKs5vXudfMtr9XgH-nkJSld7CZAU0Q80OZCkSPYUWh-bOIyw3li1wnylNQV1SHyOHlktwyh7bj1JUTIp6Lhpc89gt3avzOqmgB8r4TfcS27_KmfhH-5t2lEGY0WexiP3WEMapImEEhDZVBGVRdVH2MHDD6qjg7PNGhR2c5_BBhFkVbjY3D4xdgneZ7HOYA","place_id":"52c3d4db3a0835659e2279f285775f449a49c33b","types":["bar","restaurant","food","establishment"],"formatted_address":"1024 N Rush St, Chicago, IL, United States","street_number":"1024","route":"N Rush St","zipcode":"60611","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-09-08T11:02:49.061-07:00","updated_at":"2014-09-08T11:02:49.061-07:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5013762","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.628015 41.90116)","do_not_connect_to_api":true,"merged_with_place_id":12334})
  end
end
puts "\n\n\n--------------------\n- Recreating Carmine's: [12321]"
if Place.where(id: 6706).any?
  place = Place.find_by(id: 12321)
  place ||= Place.find_by(place_id: 'ChIJazmh0FHTD4gRtbe0su4NLxE')
  if place.present?
    Place.find(6706).merge(place)
  else
    place = Place.create!({"id":12321,"name":"Carmine's","reference":"CmRcAAAAafZrNlUB18b2iefCbcr8uk_yBOEDd6oHb0N_YtTr5y1ycX8ldLrY1oetQvsRu0Pk7ergXwFRksr2hvHSqK6YmBUw4ufyvHeKaer6tFgmfHeYCvbCdpdddX0-pG4XtWubEhDySb23sd7KSMqrxBnKopuOGhRmqQgjzqkVws4f3YuO9htlEIMx5w","place_id":"ChIJazmh0FHTD4gRtbe0su4NLxE","types":["bar","restaurant","food","establishment"],"formatted_address":"1043 North Rush Street, Chicago, IL 60611, United States","street_number":"1043","route":"North Rush Street","zipcode":"60611","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-13T14:48:17.616-08:00","updated_at":"2015-02-18T10:54:57.967-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":nil,"location_id":43,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.627761 41.902023)","do_not_connect_to_api":true,"merged_with_place_id":6706})
  end
elsif Place.where(id: 12321).any?
  place = Place.find_by(id: 6706)
  place ||= Place.find_by(place_id: '352414eabe68b3ef4ac70b32b857ee13df6e6f11')
  if place.present?
    Place.find(12321).merge(place)
  else
    place = Place.create!({"id":6706,"name":"Carmine's","reference":"CnRrAAAADeVRDpHso7D1PDhzr4Wt_dRt_5OpuR8oCwESye14U5UQ3kBtHw9NZVTw2A_4m9OmozfXSlilal5WWPzQwG5_kIcdhFtx123Wi057_rPuZYovQy7_sUGytdsRwBSA8jeuIsVNgcCz26CGglKmAplihBIQKOmFHO-b_jkkucry-YEL4hoUC1SejLVMrAIW4eeFNEn3ipb6rSw","place_id":"352414eabe68b3ef4ac70b32b857ee13df6e6f11","types":["restaurant","food","establishment"],"formatted_address":"1043 N Rush St, Chicago, IL, United States","street_number":"1043","route":"N Rush St","zipcode":"60611","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-05-21T15:36:18.260-07:00","updated_at":"2014-05-21T15:36:18.260-07:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5008216","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.627761 41.902023)","do_not_connect_to_api":true,"merged_with_place_id":12321})
  end
end
puts "\n\n\n--------------------\n- Recreating Cabo Cantina: [12167]"
if Place.where(id: 9026).any?
  place = Place.find_by(id: 12167)
  place ||= Place.find_by(place_id: 'ChIJO-fJsewB3IARVn5doAgJd6M')
  if place.present?
    Place.find(9026).merge(place)
  else
    place = Place.create!({"id":12167,"name":"Cabo Cantina","reference":"CnRvAAAAIbZmyyCbvG3oMd7v0AYl4X02DNszvLra406yQ88hA2gt8dSOIBJ9cr1bfpsqvvsd9XsUMKufnPPEY5F8gmmQVW7GB5kb77Pugcq2QfNcIFoSKLk_Ml-MFB0wKJ07PNS6gzOH0sR5haWDK5iWMA6IChIQwtoGHmN4z8MrncKdGzhoHxoUX3U41cE2y_PKUsU6aqK7aG-t-v0","place_id":"ChIJO-fJsewB3IARVn5doAgJd6M","types":["bar","restaurant","food","establishment"],"formatted_address":"1050 Garnet Avenue, San Diego, CA 92109, United States","street_number":"1050","route":"Garnet Avenue","zipcode":"92109","city":"San Diego","state":"California","country":"US","created_at":"2015-02-08T15:51:07.331-08:00","updated_at":"2015-02-18T11:01:17.017-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5506331","location_id":104,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.250812 32.797805)","do_not_connect_to_api":true,"merged_with_place_id":9026})
  end
elsif Place.where(id: 12167).any?
  place = Place.find_by(id: 9026)
  place ||= Place.find_by(place_id: 'f3133c76172c05b26a7a5e8ce487d98890f1074c')
  if place.present?
    Place.find(12167).merge(place)
  else
    place = Place.create!({"id":9026,"name":"Cabo Cantina","reference":"CnRvAAAA_wOPNbFdoJJTfw4gn666IpTs0Cb73FXX_n3ipKM0Ch3vtBzP5zIDrfieHeM1JFbfb9XFwyyA0T_c8ksljxGwwCc5KU0sHzHhuiDjHR6ZugB-hKglOFoc3GR6kOHJjbMRLki3nff4jFOU6jaUR1axuhIQZc4PTJZdEyq7yt65tkYc4BoU_e4Xgr0SEQFuVtRb8m67gJ6Yick","place_id":"f3133c76172c05b26a7a5e8ce487d98890f1074c","types":["bar","restaurant","food","establishment"],"formatted_address":"1050 Garnet Ave, San Diego, CA 92109, United States","street_number":"1050","route":"Garnet Ave","zipcode":"92109","city":"San Diego","state":"California","country":"US","created_at":"2014-10-20T12:32:18.470-07:00","updated_at":"2014-10-20T12:32:18.470-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5506331","location_id":104,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.250812 32.797805)","do_not_connect_to_api":true,"merged_with_place_id":12167})
  end
end
puts "\n\n\n--------------------\n- Recreating Maddy's Taproom: [12163]"
if Place.where(id: 5989).any?
  place = Place.find_by(id: 12163)
  place ||= Place.find_by(place_id: 'ChIJ31trgpO3t4kR29up95RCJNI')
  if place.present?
    Place.find(5989).merge(place)
  else
    place = Place.create!({"id":12163,"name":"Maddy's Taproom","reference":"CoQBcgAAAOqjP9OXBJkIjn80j9ODtQnDJvJ7W0gcYbGvJNZ4xWl-xSivWsUNSCJRpO25_gw2jmI78LpR-4VUyqSczl2Nzq52ziC2SysaT9ohY81bKdTQ2mwQzrGnhhI21XOu7n1ycOR1ikmUjlpXEi-fF0pW2bRES6fOUJZw7Jw_IM8q8B8QEhDIIr3WMHB2Z4Y3QEDEuAfPGhS_COT2rGqojlHRsRfsLvzq5fRX7Q","place_id":"ChIJ31trgpO3t4kR29up95RCJNI","types":["bar","establishment"],"formatted_address":"1100 13th Street Northwest, Washington, DC 20005, United States","street_number":"1100","route":"13th Street Northwest","zipcode":"20005","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-02-08T07:52:16.338-08:00","updated_at":"2015-02-18T11:01:17.811-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":nil,"location_id":538,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.029902 38.903893)","do_not_connect_to_api":true,"merged_with_place_id":5989})
  end
elsif Place.where(id: 12163).any?
  place = Place.find_by(id: 5989)
  place ||= Place.find_by(place_id: '38d3bdbcbd44b44dba71a7b879aa15c7e7627ece')
  if place.present?
    Place.find(12163).merge(place)
  else
    place = Place.create!({"id":5989,"name":"Maddy's Taproom","reference":"CoQBcQAAACWKJnyUgstJHJ_n3_bvCH0Qw5PWhMFGUOFLXo3LTYQhDdOEzw6-9HpwuAVu-depBGhF2t4vWT7zml2lcrdXPfVWYnyrcHYu8o2PZu2KMPzsHy9v4QJLPU8AE3AtAaMSeVLZFRKqeygBgmSbVYhHlbThxp6UcvjoMkXvWuFwncq-EhDvu9ORGD8YqcjXA7X1a8qJGhS9eruOG7J8lfFP-QAw4f3OYUkPsA","place_id":"38d3bdbcbd44b44dba71a7b879aa15c7e7627ece","types":["bar","establishment"],"formatted_address":"1100 13th St NW, Washington, DC, United States","street_number":"1100","route":"13th St NW","zipcode":"20005","city":"Washington","state":"District of Columbia","country":"US","created_at":"2014-04-15T10:36:28.424-07:00","updated_at":"2014-04-15T10:36:28.424-07:00","administrative_level_1":"DC","administrative_level_2":"District of Columbia","td_linx_code":nil,"location_id":538,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.029818 38.903886)","do_not_connect_to_api":true,"merged_with_place_id":12163})
  end
end
puts "\n\n\n--------------------\n- Recreating Mike's in Tigerland: [11649]"
if Place.where(id: 1269).any?
  place = Place.find_by(id: 11649)
  place ||= Place.find_by(place_id: '4d34599928a8952c46b5bb2a399d2a8c172568b9')
  if place.present?
    Place.find(1269).merge(place)
  else
    place = Place.create!({"id":11649,"name":"Mike's in Tigerland","reference":"CoQBdQAAAI3DeSYccJQerQb1Y67leyblNxUCPRphBeTDUZtumXOi4nJ0od9vB3a2zBiJwHpB06T4tNRngocix31q-AKcbXj_AVuM3lbBJNfyf_LHsVf8d4OHdwNSMKStNyH76Z6Zt_L92TSR8NOpV01uZYLaP9LDmWsBnjMBAqQaYhyAyw60EhBqu_jEj2UFb7bx-L0nsl-9GhQTLJiHfMbbZ6himhil-AVkdIm3zg","place_id":"4d34599928a8952c46b5bb2a399d2a8c172568b9","types":["bar","establishment"],"formatted_address":"1121 Bob Pettit Boulevard, Baton Rouge, LA 70820, United States","street_number":"1121","route":"Bob Pettit Boulevard","zipcode":"70820","city":"Baton Rouge","state":"Louisiana","country":"US","created_at":"2015-01-25T14:28:35.861-08:00","updated_at":"2015-01-26T11:31:40.686-08:00","administrative_level_1":"LA","administrative_level_2":nil,"td_linx_code":nil,"location_id":152,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-91.179432 30.395754)","do_not_connect_to_api":true,"merged_with_place_id":1269})
  end
elsif Place.where(id: 11649).any?
  place = Place.find_by(id: 1269)
  place ||= Place.find_by(place_id: '9af3c04e8ebbb26e1f673eca1db10eef00d29fd8')
  if place.present?
    Place.find(11649).merge(place)
  else
    place = Place.create!({"id":1269,"name":"Mike's Daiquiris \u0026 Grill","reference":"CkQxAAAARQiL04ihSQU-3mFcyOV22DMiI4-WUCVFB9kPEF41w8FctIqdRE9glNMJgIha9fk0EI487flbYA3tsKgCVSz9ChIQhWm4biiElRE-9h7MgH2LuhoUEAg5jofX1EmK8ULCPnCrenXco7c","place_id":"9af3c04e8ebbb26e1f673eca1db10eef00d29fd8","types":["bar","establishment"],"formatted_address":"1121 Bob Pettit Blvd, Baton Rouge, LA 70820","street_number":"1128 Bob Pettit","route":"","zipcode":"70820","city":"Baton Rouge","state":"Louisiana","country":"US","created_at":"2013-10-25T08:27:43.719-07:00","updated_at":"2015-01-26T11:32:01.210-08:00","administrative_level_1":nil,"administrative_level_2":nil,"td_linx_code":"5197715","location_id":152,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-91.1792778 30.3962029)","do_not_connect_to_api":true,"merged_with_place_id":11649})
  end
end
puts "\n\n\n--------------------\n- Recreating Three Clubs: [11849]"
if Place.where(id: 1794).any?
  place = Place.find_by(id: 11849)
  place ||= Place.find_by(place_id: 'ChIJayJxQjS_woARavKnsb3Qpn8')
  if place.present?
    Place.find(1794).merge(place)
  else
    place = Place.create!({"id":11849,"name":"Three Clubs","reference":"CnRtAAAABIQpfAT3fS9BhavVVJFmtH351nRTjiN37XKQJoxkRd0_0Kzs0KTnnybemK26oMJNw5XNeoML5LMyEVo9ykBCQl0zC-E3Oz_SDKyIpxczMfAaqRrvwQtrRnAa3PbK1f8_W_utRAPPo0em6j13MIR5KhIQgCdPUmph408YoxLSvIP0_xoUCLCEzwNUusA8NPPRCdaqmk3uxWY","place_id":"ChIJayJxQjS_woARavKnsb3Qpn8","types":["night_club","bar","establishment"],"formatted_address":"1123 Vine Street, Los Angeles, CA 90038, United States","street_number":"1123","route":"Vine Street","zipcode":"90038","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-30T16:21:01.969-08:00","updated_at":"2015-01-30T16:21:01.969-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5262041","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.326718 34.091415)","do_not_connect_to_api":true,"merged_with_place_id":1794})
  end
elsif Place.where(id: 11849).any?
  place = Place.find_by(id: 1794)
  place ||= Place.find_by(place_id: 'e265fee45850a6ab13d032b8f9e1e7d1db2c23c1')
  if place.present?
    Place.find(11849).merge(place)
  else
    place = Place.create!({"id":1794,"name":"Three Clubs","reference":"CnRtAAAAkcLvQDdBbIoq8pL86VQ18rK69mZ0ssip19O2N7V53lNL5cd4ZKMjSIfB4fkazbsScDafGLwhVmeDNkvYAX9L2lZUSK-aS_eQr73yzijdPaKbfQv2r67A5RIKI4zSb16SBAzLJHJuA3TErqRF0YofkxIQ_nfTyUNDYRv0EoHtKLJIHxoUavdAMAJWcmlK-m1aYxqWZKNOfzI","place_id":"e265fee45850a6ab13d032b8f9e1e7d1db2c23c1","types":["night_club","bar","establishment"],"formatted_address":"1123 Vine Street, Hollywood, CA, United States","street_number":"1123","route":"Vine Street","zipcode":"90038","city":"Los Angeles","state":"California","country":"US","created_at":"2013-11-11T00:49:08.662-08:00","updated_at":"2014-02-17T20:12:22.465-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5262041","location_id":20,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.326718 34.091415)","do_not_connect_to_api":true,"merged_with_place_id":11849})
  end
end
puts "\n\n\n--------------------\n- Recreating R Bar: [12370]"
if Place.where(id: 83).any?
  place = Place.find_by(id: 12370)
  place ||= Place.find_by(place_id: 'ChIJxfrQaZSAhYARFZf5-pIu6aI')
  if place.present?
    Place.find(83).merge(place)
  else
    place = Place.create!({"id":12370,"name":"R Bar","reference":"CmRZAAAAEmT2WJ8PfR3bivkcUHLybWkziStG4Fj830Aq392LABAR5tuNyJnLX-dJ3tew1sEyLN6kQh1Itdvn5o2hkaadOE0wTx0TxSI3TYkI1Pse69UIRAhfioNPB7lKjoqR1FYJEhD4BdZMh5NXraPvSuAYxvIpGhQ9f6NAnkqwudoE5Z4OUi6mWh84fw","place_id":"ChIJxfrQaZSAhYARFZf5-pIu6aI","types":["bar","establishment"],"formatted_address":"1176 Sutter Street, San Francisco, CA 94109, United States","street_number":"1176","route":"Sutter Street","zipcode":"94109","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-16T17:02:03.193-08:00","updated_at":"2015-02-18T10:54:47.989-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":35,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.419858 37.787981)","do_not_connect_to_api":true,"merged_with_place_id":83})
  end
elsif Place.where(id: 12370).any?
  place = Place.find_by(id: 83)
  place ||= Place.find_by(place_id: 'b8c8db6d2e5f48ea990c9e2f4649297ec54fd888')
  if place.present?
    Place.find(12370).merge(place)
  else
    place = Place.create!({"id":83,"name":"R Bar","reference":"CnRjAAAAJjvS0Dbs2DxLMJlnlHXw-n5jSalmCFJsdmdLCpVHvSNC6K_kmqorD3eC0AG48fRNWc81hQgvGHUrPuywHlLxGgINbeAoiNvg5QL0z_xsZ5QzRLNIC1AxRb1UH3lzHAR2mL9contU-7acWPT6baylARIQMNa2i5ap84VG6YsBp2onzBoUdBENK2MDz91P8urQYyX4i4xgXlo","place_id":"b8c8db6d2e5f48ea990c9e2f4649297ec54fd888","types":["bar","establishment"],"formatted_address":"1176 Sutter Street, San Francisco, CA, United States","street_number":"1176","route":"Sutter Street","zipcode":"94109","city":"San Francisco","state":"California","country":"US","created_at":"2013-10-11T13:33:15.050-07:00","updated_at":"2014-02-17T20:03:46.546-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5238752","location_id":35,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.419812 37.787896)","do_not_connect_to_api":true,"merged_with_place_id":12370})
  end
end
puts "\n\n\n--------------------\n- Recreating Bank & Bourbon: [11877]"
if Place.where(id: 8553).any?
  place = Place.find_by(id: 11877)
  place ||= Place.find_by(place_id: 'ChIJK9oJLSnGxokRn7uWKXin3Tc')
  if place.present?
    Place.find(8553).merge(place)
  else
    place = Place.create!({"id":11877,"name":"Bank \u0026 Bourbon","reference":"CnRwAAAAPMTX1XuLA7iOFECzJOL-kHw68xJV3hq_Fz1BkPvWOlri5c2GPpABbbp5dAjJniD4DsnGt6ZLBnI1u6VGEktBJgmnYVSWiVhxny8ymP2XeIIVjKs3RA25iKMWaVQBwlgjSQRxMPJxkZSRD5_qlhxEFBIQcTDuIan_j9tLu2qQmktwsRoUAKhzLxf5jv8Hcz9xDDfUoXt9xtg","place_id":"ChIJK9oJLSnGxokRn7uWKXin3Tc","types":["bar","restaurant","food","establishment"],"formatted_address":"1200 Market Street, Philadelphia, PA 19107, United States","street_number":"1200","route":"Market Street","zipcode":"19107","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2015-01-31T10:53:58.567-08:00","updated_at":"2015-01-31T10:53:58.567-08:00","administrative_level_1":"PA","administrative_level_2":nil,"td_linx_code":nil,"location_id":62,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.160182 39.951654)","do_not_connect_to_api":true,"merged_with_place_id":8553})
  end
elsif Place.where(id: 11877).any?
  place = Place.find_by(id: 8553)
  place ||= Place.find_by(place_id: '94b241c9a75ccadb25e9f34eb75c291c6fae7ab7')
  if place.present?
    Place.find(11877).merge(place)
  else
    place = Place.create!({"id":8553,"name":"Bank \u0026 Bourbon","reference":"CnRvAAAApHCKNHOYrCBjeOgI3TU0HJzqQ0wMjtZ2tWCvQxgDx0ZU_nK-XPtZBU6Y8zZbPg6jVDXQuxrgPliOWFm22Oli5-BEUI4tHfMgC90naqQbdAFtM41OoJfMHNB4rU-6FjzBlYta2KZC0c3LkJq6whRcuBIQBL_uohkw5C4Z1pY-e98x6RoU1DP1F-JIoemaMGM3kIcIq8StZhI","place_id":"94b241c9a75ccadb25e9f34eb75c291c6fae7ab7","types":["bar","restaurant","food","establishment"],"formatted_address":"1200 Market St, Philadelphia, PA, United States","street_number":"1200","route":"Market St","zipcode":"19107","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2014-10-01T19:35:16.552-07:00","updated_at":"2014-10-01T19:35:16.552-07:00","administrative_level_1":"PA","administrative_level_2":nil,"td_linx_code":"1865880","location_id":62,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.160217 39.951615)","do_not_connect_to_api":true,"merged_with_place_id":11877})
  end
end
puts "\n\n\n--------------------\n- Recreating The Up and Under Pub INCORRECT: [12342]"
if Place.where(id: 10622).any?
  place = Place.find_by(id: 12342)
  place ||= Place.find_by(place_id: 'ChIJmR-s0R0ZBYgRd4IAduXhnvE')
  if place.present?
    Place.find(10622).merge(place)
  else
    place = Place.create!({"id":12342,"name":"The Up and Under Pub INCORRECT","reference":"CnRoAAAAAbV5BAshO7azRnJWHQntmgaUPGVhZ-68ckxqNtEtmrW07HPomdYCYxkwYb3y49NsbO-vPk2I5OD0vdeZaGJMUQxlovNhvaCMUNU1XyZUODwcgUveR5Yae6jkBDvToQgLXW1g_thDjSNx5S5gb3kfJRIQc7ub5zGiYrQOHxRk6FGxFRoUSEEsV2XV1BAduHy3OxO8XWSLLfc","place_id":"ChIJmR-s0R0ZBYgRd4IAduXhnvE","types":["bar","establishment"],"formatted_address":"1216 East Brady Street, Milwaukee, WI 53202, United States","street_number":"1216","route":"East Brady Street","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2015-02-15T19:56:07.711-08:00","updated_at":"2015-02-27T10:44:05.925-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"","location_id":646,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.896263 43.053062)","do_not_connect_to_api":true,"merged_with_place_id":10622})
  end
elsif Place.where(id: 12342).any?
  place = Place.find_by(id: 10622)
  place ||= Place.find_by(place_id: '28cc1a08c3f59adb0f355dc802684aee4cdbb12f')
  if place.present?
    Place.find(12342).merge(place)
  else
    place = Place.create!({"id":10622,"name":"The Up and Under Pub ","reference":"CoQBdgAAAGUMLzD85EJfqm_BmoZknzkk1V03FvyBdGiX85VDDD3bvR31XP2zhMslr490uvidbEIhnACnUqL9q0uAILwhoAT1UaYcRh-Li4b6_6cFkgp9n_NNet6eet875zzqCYXhZMafOdxZTqKX2AkBBiwZxGbKCRJw-Z1syYpd-mwhQv9bEhB35jqcnbZgeI73OCtr_InwGhThJV4Smh2xfGG1dfxPfUvPdAN7CQ","place_id":"28cc1a08c3f59adb0f355dc802684aee4cdbb12f","types":["bar","establishment"],"formatted_address":"1216 E Brady Street, Milwaukee, WI 53202","street_number":"1216","route":"E Brady St","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2014-12-04T23:03:17.478-08:00","updated_at":"2015-02-27T10:43:30.289-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"5017599","location_id":646,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.896263 43.053062)","do_not_connect_to_api":true,"merged_with_place_id":12342})
  end
end
puts "\n\n\n--------------------\n- Recreating Liq O Rama: [12100]"
if Place.where(id: 9424).any?
  place = Place.find_by(id: 12100)
  place ||= Place.find_by(place_id: 'ChIJFaKMVAx2ToYRYq9ea9-McrY')
  if place.present?
    Place.find(9424).merge(place)
  else
    place = Place.create!({"id":12100,"name":"Liq O Rama","reference":"CnRtAAAARsSmZkOst_lV_Y1zsaGesX8nzvz3dpyZYgpEgS1h8vtZrPKQtZhORJ8rnmRog4DkSehwUGWo1g80NtkXFVZ562J_ZwfbLwr6r64FqwA6onATtQl7TMZa-qHkP8L_GdIhF0odmc5ag1My6GNpZRiX6BIQgkp0Q4l7guQhLBPhmttDdhoUqXye8x_ECGJuJ3y7u9VgxHvIR6Q","place_id":"ChIJFaKMVAx2ToYRYq9ea9-McrY","types":["liquor_store","food","store","establishment"],"formatted_address":"1228 South Blue Mound Road, Fort Worth, TX 76131, United States","street_number":"1228","route":"South Blue Mound Road","zipcode":"76131","city":"Fort Worth","state":"Texas","country":"US","created_at":"2015-02-05T17:59:36.914-08:00","updated_at":"2015-02-18T11:01:30.904-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1865438","location_id":547,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.343694 32.844164)","do_not_connect_to_api":true,"merged_with_place_id":9424})
  end
elsif Place.where(id: 12100).any?
  place = Place.find_by(id: 9424)
  place ||= Place.find_by(place_id: '5285b8481ac6b709aa9568ca5cfb08446ff589b2')
  if place.present?
    Place.find(12100).merge(place)
  else
    place = Place.create!({"id":9424,"name":"Liq O Rama","reference":"CnRtAAAAu3XedgcD6pXRFTMHlmaFYOi1NiTHD2UgBeKTEc5OikOCX64IeWH4zRTVl9Keogm7S2b2CuhxSJxnOAPnIhORrjjTrkNAUd7Ntv0QNVJYApEOij_WtBhwanelLIT7qgZBwMBUTgyzqGc5eEZWYFsR_RIQmOTj1M3ozBmKWZWJ40mZexoU4nvZylpuiWkN1hEoT-Z2xQdaX2o","place_id":"5285b8481ac6b709aa9568ca5cfb08446ff589b2","types":["liquor_store","food","store","establishment"],"formatted_address":"1228 S Blue Mound Rd, Fort Worth, TX 76131, United States","street_number":"1228","route":"S Blue Mound Rd","zipcode":"76131","city":"Fort Worth","state":"Texas","country":"US","created_at":"2014-10-31T11:38:07.240-07:00","updated_at":"2014-10-31T11:38:07.240-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1865438","location_id":547,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.343694 32.844164)","do_not_connect_to_api":true,"merged_with_place_id":12100})
  end
end
puts "\n\n\n--------------------\n- Recreating Grafton St: [2517]"
if Place.where(id: 3023).any?
  place = Place.find_by(id: 2517)
  place ||= Place.find_by(place_id: '199549dbfc007331deb7c4c9c7af786127556516')
  if place.present?
    Place.find(3023).merge(place)
  else
    place = Place.create!({"id":2517,"name":"Grafton St","reference":"CpQBkAAAAEAMQLwC6iCAxhsgT9w-4EkeMUJyIZegr_bmA65djLvY30cRgucr_LQh22dm9xjpJR_dVdvJGOzhxSF4zRS5C1ukIddD2rX_ctBJlTGeHj_fyxfYbWQVjY08XfDYELMZ3weR0xeCUy2nZ5kGYGVwgI3j_c3krVuWnPy6i_9n0DTiJuXw_YxdHTjhzaHFRmMaahIQ97CKV32biq79P5A2BUPoWRoUlfuSXu0uDv4_SHpSroRg4D6Ii8k","place_id":"199549dbfc007331deb7c4c9c7af786127556516","types":["route"],"formatted_address":"1230 Massachusetts Ave, Cambridge, MA","street_number":"1230 Massachusetts Avenue, Cambridge, Massachusetts","route":"","zipcode":"02138","city":"Cambridge","state":"Massachusetts","country":"US","created_at":"2013-11-11T00:55:08.924-08:00","updated_at":"2014-02-17T20:16:09.597-08:00","administrative_level_1":"MA","administrative_level_2":"Middlesex","td_linx_code":"5121616","location_id":161,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.1420382 42.4084625)","do_not_connect_to_api":true,"merged_with_place_id":3023})
  end
elsif Place.where(id: 2517).any?
  place = Place.find_by(id: 3023)
  place ||= Place.find_by(place_id: '06527266fe69684fb6f5d336b53cf61bbcc2baaf')
  if place.present?
    Place.find(2517).merge(place)
  else
    place = Place.create!({"id":3023,"name":"Grafton Street","reference":"CoQBcQAAAC4_ZqiHammDQ6TfxIIcD6epCjqf35JWVM_a1omSkRwSxNOhXQLcKd08tPcSLbhUobUYVIEjt2j_inytxTt3NsHjpYB7M6MtHcU3uPgY9TTF9bhf37b-Akrj02dwbUnCj8T7oN785JpfBjdzGNvLcrZNHeaNaTxH8TlcXjIBSV2TEhD7GzV8r1j6aS3TEmsHr5H3GhQidLo8EBklFeaLHQbYoSOWmW9c6A","place_id":"06527266fe69684fb6f5d336b53cf61bbcc2baaf","types":["bar","restaurant","food","establishment"],"formatted_address":"1230 Mass Avenue, Cambridge, MA, United States","street_number":"1230 Mass Avenue","route":"","zipcode":"02138","city":"Cambridge","state":"Massachusetts","country":"US","created_at":"2013-11-19T11:21:15.567-08:00","updated_at":"2014-02-21T11:10:17.980-08:00","administrative_level_1":"MA","administrative_level_2":"Middlesex County","td_linx_code":"5121616","location_id":1046,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-71.115828 42.372287)","do_not_connect_to_api":true,"merged_with_place_id":2517})
  end
end
puts "\n\n\n--------------------\n- Recreating Sassafras: [1331]"
if Place.where(id: 8825).any?
  place = Place.find_by(id: 1331)
  place ||= Place.find_by(place_id: 'df780cd91e46503828c1da69b1f825ca282cd7e8')
  if place.present?
    Place.find(8825).merge(place)
  else
    place = Place.create!({"id":1331,"name":"Sassafras","reference":"CnRrAAAAK_WmDRjA5FkxCNdfRTalubWdSqXYBtjOBGHnzaD9-bk3edCd1tF_7hsbFr2urFChI1UFSnMHwMLgfRJ8MFT66NxEaKmVt-YDSLH762lzgA1r2MJ-ldYkux9EALJoHXUDPYnpkjLuZQ-K4nADFXIZURIQjtxuUoolIcUiF0eoEVehChoUd5Bdy2OcNhchmP9jNHd--sk4f8c","place_id":"df780cd91e46503828c1da69b1f825ca282cd7e8","types":["bar","establishment"],"formatted_address":"1233 Vine Street, Los Angeles, CA, United States","street_number":"1233","route":"Vine Street","zipcode":"90038","city":"Los Angeles","state":"California","country":"US","created_at":"2013-11-03T11:13:15.363-08:00","updated_at":"2014-02-17T20:09:32.882-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"5519503","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.326894 34.093512)","do_not_connect_to_api":true,"merged_with_place_id":8825})
  end
elsif Place.where(id: 1331).any?
  place = Place.find_by(id: 8825)
  place ||= Place.find_by(place_id: 'e3dc00577dbb23f839667beab1b17567928668e3')
  if place.present?
    Place.find(1331).merge(place)
  else
    place = Place.create!({"id":8825,"name":"Sassafras Saloon","reference":"CoQBcgAAANGtj-t7KO36o0pNSn_VGFSAj45fG8LtGQiHeaDWixZ2znLaacd4k9dYuVc1mWKBkxdpMempZyX6dSH_yVhYvIRydsWEd918cZKklhsdH-IlxXoitkjWNMPuPh501KWnveH79uh-ihjXn0LEQVGBYLJh8Q5MVwG9DDIrtc5FUGiUEhAQ5acKlxC2f_GcIuo4kviSGhRMR7t-ayiAtvl4eO97Tr0WoGqFxQ","place_id":"e3dc00577dbb23f839667beab1b17567928668e3","types":["bar","establishment"],"formatted_address":"1233 Vine St, Los Angeles, CA 90038, United States","street_number":"1233","route":"Vine St","zipcode":"90038","city":"Los Angeles","state":"California","country":"US","created_at":"2014-10-13T11:27:04.148-07:00","updated_at":"2015-02-19T10:02:28.985-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"5519503","location_id":19,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.326957 34.093533)","do_not_connect_to_api":true,"merged_with_place_id":1331})
  end
end
puts "\n\n\n--------------------\n- Recreating Bob's Steak & Chop House: [11973]"
if Place.where(id: 4589).any?
  place = Place.find_by(id: 11973)
  place ||= Place.find_by(place_id: 'ChIJXWuY6yYrTIYRCI0eAU2LzbM')
  if place.present?
    Place.find(4589).merge(place)
  else
    place = Place.create!({"id":11973,"name":"Bob's Steak \u0026 Chop House","reference":"CoQBegAAAGFZ5zewemuFgCG4OJxrfK_EPQ1naP1ZQnkZno1DEqxYHHLma5I3_bTF2NAiUxSaGBx4BtcbP8JfRBtZLdQeqsonCOK1vSGEp3eVfqT1dscNhON-47pHUQj4cMt6xGW1ASfc_XawiuHMNU4ESIhI7aYDz-awktrR4DXW3TwLe4vQEhBbnYwIjqGJH3DExMB-V7Q9GhRGtERkH76wv1deMWLmALoZkSiiZg","place_id":"ChIJXWuY6yYrTIYRCI0eAU2LzbM","types":["bar","restaurant","food","establishment"],"formatted_address":"1255 South Main Street, Grapevine, TX 76051, United States","street_number":"1255","route":"South Main Street","zipcode":"76051","city":"Grapevine","state":"Texas","country":"US","created_at":"2015-02-02T20:55:58.822-08:00","updated_at":"2015-02-02T20:55:58.822-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2191030","location_id":550,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.077664 32.926094)","do_not_connect_to_api":true,"merged_with_place_id":4589})
  end
elsif Place.where(id: 11973).any?
  place = Place.find_by(id: 4589)
  place ||= Place.find_by(place_id: 'ab85b6eb201ceb99beaa7f920d6a68cdf53b8bcf')
  if place.present?
    Place.find(11973).merge(place)
  else
    place = Place.create!({"id":4589,"name":"Bob's Steak \u0026 Chop House","reference":"CoQBegAAADLtDyMLdb-ZV8NnZ2TuHw2YKmzJoNNHtKQ8Sik5wy6B5jslkGGqQhErrNGkQPY7OWr_QGTOljREajCzF2pGQCrc0QcJOKXUuZ6gRFH5f5wKJ9Z4OTlc1oqtp6Z-Qh69zKn87Nm0AHLSOzzNbRTxnClhNob8US6qXEtWtUI_3upTEhDr-E8YgacjaMxrktjYgR-IGhQZuWDD-iZ_9YDA1u1ojo98rLwkew","place_id":"ab85b6eb201ceb99beaa7f920d6a68cdf53b8bcf","types":["restaurant","food","establishment"],"formatted_address":"1255 S Main St, Grapevine, TX, United States","street_number":"1255","route":"S Main St","zipcode":"76051","city":"Grapevine","state":"Texas","country":"US","created_at":"2014-02-09T08:08:04.381-08:00","updated_at":"2014-02-17T20:28:01.205-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2191030","location_id":550,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.077641 32.926202)","do_not_connect_to_api":true,"merged_with_place_id":11973})
  end
end
puts "\n\n\n--------------------\n- Recreating Jo-Cat's Pub: [12340]"
if Place.where(id: 1218).any?
  place = Place.find_by(id: 12340)
  place ||= Place.find_by(place_id: 'ChIJcyRc7h0ZBYgRoBGf8hf9bwY')
  if place.present?
    Place.find(1218).merge(place)
  else
    place = Place.create!({"id":12340,"name":"Jo-Cat's Pub","reference":"CmRfAAAA6pNx3W2T22C68QZtKKREkGa-KWLrLXhHiUny9w29dFQN0HQJV2ujBhOVye6BPxdhn6OyfTLRXCH_MO4PRj-3QxsTzAgtVZ77x2d1_RNDm33KC_yiL7M8R1eiRLuaYjVLEhDO_G4zX8w_Kr_R2QbdjgY0GhRiLVy0X0mcX4qNdshLDs4LZmvSYg","place_id":"ChIJcyRc7h0ZBYgRoBGf8hf9bwY","types":["bar","establishment"],"formatted_address":"1311 East Brady Street, Milwaukee, WI 53202, United States","street_number":"1311","route":"East Brady Street","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2015-02-15T19:30:47.092-08:00","updated_at":"2015-02-18T10:54:54.031-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":nil,"location_id":646,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.89498 43.052829)","do_not_connect_to_api":true,"merged_with_place_id":1218})
  end
elsif Place.where(id: 12340).any?
  place = Place.find_by(id: 1218)
  place ||= Place.find_by(place_id: '3bde6ede483bffdf06ae698441cde8a314578458')
  if place.present?
    Place.find(12340).merge(place)
  else
    place = Place.create!({"id":1218,"name":"Jo-Cat's Pub","reference":"CnRlAAAAqU9_1dkY5ZABu9qb8CTXpF6SfsTET8Kn1DIOCu48KhkTUIe2VOXXuHnPOHTLBzm_C0Sb-YpIQTBVAiV1vuuXcwXceyQun-sBgurXT9LZSRHqEiMcYc_96hodPx46E0dIoev-a-cn-GF3WrEQritVoRIQj_xRlahtdWutJKJC8CygohoUlVxx6hIzquy6_f6JVsEGDCUO8FI","place_id":"3bde6ede483bffdf06ae698441cde8a314578458","types":["bar","establishment"],"formatted_address":"1311 East Brady Street, Milwaukee, WI, United States","street_number":"1311","route":"East Brady Street","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2013-10-21T09:45:34.564-07:00","updated_at":"2014-02-17T20:08:57.512-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"5018073","location_id":646,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.895008 43.05285)","do_not_connect_to_api":true,"merged_with_place_id":12340})
  end
end
puts "\n\n\n--------------------\n- Recreating Semilla Eatery & Bar: [3764]"
if Place.where(id: 3236).any?
  place = Place.find_by(id: 3764)
  place ||= Place.find_by(place_id: '9f2735f8cf409c5b686c226b6c30e87c098047b4')
  if place.present?
    Place.find(3236).merge(place)
  else
    place = Place.create!({"id":3764,"name":"Semilla Eatery \u0026 Bar","reference":"CoQBdgAAAMRc0wUAD7FbIMhpanmXO32kzben40RuBtdR7eGgWEEvNQzQJOd7oE670um9yw4YITBMO6xmuH6BnaJttFMiG8zM9IBZGu2SB0sQ7sdw5SyhEOdmGu71TSVi-yhfLuvatE57AheQdPGyETbINJpmiMHSlj4SMB_xO46BlIK1BcEuEhAFoWmG0pvs1_sJkup3ZiisGhRtLIvRw7tDGw6NIyyFl6VByZTdtA","place_id":"9f2735f8cf409c5b686c226b6c30e87c098047b4","types":["bar","restaurant","food","establishment"],"formatted_address":"1330 Alton Road, Miami Beach, FL, United States","street_number":"1330 Alton Road","route":"","zipcode":"33139","city":"Miami Beach","state":"Florida","country":"US","created_at":"2013-12-23T11:14:26.526-08:00","updated_at":"2014-03-05T09:20:59.572-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"3853344","location_id":700,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.141196 25.784593)","do_not_connect_to_api":true,"merged_with_place_id":3236})
  end
elsif Place.where(id: 3764).any?
  place = Place.find_by(id: 3236)
  place ||= Place.find_by(place_id: 'e7be841835cf93a03345e5c5d664e14b62e6b475')
  if place.present?
    Place.find(3764).merge(place)
  else
    place = Place.create!({"id":3236,"name":"Semilla Eatery \u0026 Bar","reference":"CqQBlgAAAN4a3NWYzVB1d8D3QfWBWacg8MdjyHLbHs3jMZX72j0owJZQMd-Q6Tt6S50OQvWT9YtKbHg6TTEzEKaRsE2XkA1B2zxR_vNxP8W0PDxnnyDkPzsUFND5qeslaT94vCsuvoaGdhoD49AXbDEezp9iAjWgfg734awLcgf8r6BSYMv5FgzL-JaiXi0K0z_Z9Gnumx95t550ZYW87rPHU5xNb20SEOe2oSkgHsQP7hU_OWuOrSMaFGkht-Y9J8kB749Q4fC-6hD2y3r9","place_id":"e7be841835cf93a03345e5c5d664e14b62e6b475","types":["street_address"],"formatted_address":"1330 Alton Rd, Miami Beach, FL 33140, USA","street_number":"1330","route":"Alton Rd","zipcode":"33140","city":"Miami Beach","state":"Florida","country":"US","created_at":"2013-12-02T10:36:19.127-08:00","updated_at":"2014-02-17T20:20:15.383-08:00","administrative_level_1":"FL","administrative_level_2":"Miami-Dade","td_linx_code":"3853344","location_id":1069,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.1411825 25.7845976)","do_not_connect_to_api":true,"merged_with_place_id":3764})
  end
end
puts "\n\n\n--------------------\n- Recreating H Street Country Club: [12317]"
if Place.where(id: 7302).any?
  place = Place.find_by(id: 12317)
  place ||= Place.find_by(place_id: 'ChIJE5FcCUC4t4kRKkuhQvsRpmc')
  if place.present?
    Place.find(7302).merge(place)
  else
    place = Place.create!({"id":12317,"name":"H Street Country Club","reference":"CnRoAAAAgIXhTlfcV5AVqTefBUMR5b5QtRfLM8ezXjgHnF_kBPmab0dLaHxfHqePwN43ZYhdDKlAKWvHXNuRdZ2y32JUyL_mIgNotTYvBg8-Ka-FilOS3WgZ3zHm9KZDlwPVFd9ChQjAsTj8cyoH0-bJ3zxd2BIQ5JHa0plbQyvD_61CG9INrRoUpdGYrVrxS82izR_SyOATGDqhzeQ","place_id":"ChIJE5FcCUC4t4kRKkuhQvsRpmc","types":["bar","restaurant","food","establishment"],"formatted_address":"1335 H Street Northeast, Washington, DC 20002, United States","street_number":"1335","route":"H Street Northeast","zipcode":"20002","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-02-13T10:36:41.242-08:00","updated_at":"2015-02-18T10:54:58.772-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":nil,"location_id":538,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-76.987045 38.899954)","do_not_connect_to_api":true,"merged_with_place_id":7302})
  end
elsif Place.where(id: 12317).any?
  place = Place.find_by(id: 7302)
  place ||= Place.find_by(place_id: '476823114e78a8cc8edb2860b9b4b908f382b9e6')
  if place.present?
    Place.find(12317).merge(place)
  else
    place = Place.create!({"id":7302,"name":"H Street Country Club","reference":"CoQBdgAAAHcDtfC3c9xQQlsgDb5wDsigfKyh4Idkt8P9aYgKL8T-l7qfBHASSU8rpSa1e2uxBSi_-uC7IdsVLe8NHQ5M8dOVG2TdKjP_r3o9-a7u-kg0l9v4Xn9eRSvjB3b14wZ-c7tSF0oS_8HEGzlbLz6isbTJ4UTm1TctrIwIYqqdQtrDEhDbmvq30cK2JThtwftpdMvjGhTIeqkr4Sk7shjzE9amTTbFv8i76w","place_id":"476823114e78a8cc8edb2860b9b4b908f382b9e6","types":["bar","restaurant","food","establishment"],"formatted_address":"1335 H St NE, Washington, DC, United States","street_number":"1335","route":"H St NE","zipcode":"20002","city":"Washington","state":"District of Columbia","country":"US","created_at":"2014-06-30T11:16:03.651-07:00","updated_at":"2015-01-24T13:28:24.437-08:00","administrative_level_1":"DC","administrative_level_2":"District of Columbia","td_linx_code":"3611900","location_id":538,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-76.987045 38.899954)","do_not_connect_to_api":true,"merged_with_place_id":12317})
  end
end
puts "\n\n\n--------------------\n- Recreating Villains Tavern OTHER INCORRECT: [7422]"
if Place.where(id: 295).any?
  place = Place.find_by(id: 7422)
  place ||= Place.find_by(place_id: '17d4bcc8ec73614ff9953032021a3218ceffbd66')
  if place.present?
    Place.find(295).merge(place)
  else
    place = Place.create!({"id":7422,"name":"Villains Tavern OTHER INCORRECT","reference":"CoQBewAAADAPSvrohJheIyMIJvscw0se1F9jGVU3jyPJ0hkPFQq4B3BXS22d_Px4RJpxzwbuOuL7Cj2-A0ZvR6WHnxQD9i9_lX8fO5D1rrDNmFuaMxe1UZYKRqQn8MncRGt4POCWUwlg3-eckM2A6VFsIQk1qY1jJNhLyNloh6NqSTlwLX7CEhDOF9YbOMEESIQLhWxunSruGhTOA-WusNb0IkVeQDCK17aaSKUL6Q","place_id":"17d4bcc8ec73614ff9953032021a3218ceffbd66","types":["bar","point_of_interest","establishment"],"formatted_address":"Villains Tavern, 1356 Palmetto St, Los Angeles, CA 90013, USA","street_number":"1356","route":"Palmetto St","zipcode":"90013","city":"Los Angeles","state":"California","country":"US","created_at":"2014-07-13T13:16:50.336-07:00","updated_at":"2015-02-27T11:11:51.283-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"2006700","location_id":19,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.2309747 34.040165)","do_not_connect_to_api":true,"merged_with_place_id":295})
  end
elsif Place.where(id: 7422).any?
  place = Place.find_by(id: 295)
  place ||= Place.find_by(place_id: '77c3e56ba22b936dd9ac3ef8c948f2387f69680e')
  if place.present?
    Place.find(7422).merge(place)
  else
    place = Place.create!({"id":295,"name":"Villains Tavern","reference":"CnRuAAAAkjhKwjnBcBuxfm6vmMlqC3LPl226iVazuEp4Tx66D6Ba2tApC2wHx40f_nqtbRwt5ngzdgvEI27UfTxokZO5KR8VntgyYxO0Xd_BhgvdLwxYHYLn9rHTtthCZaoOkUY0u7Jf8Wv8qhWVfsMfgvRnkhIQfeUg9BgVUyUlpyoPPtAmKhoU8A92S4_ms2kVDXli8xItCszqV_M","place_id":"77c3e56ba22b936dd9ac3ef8c948f2387f69680e","types":["bar","restaurant","food","establishment"],"formatted_address":"1356 Palmetto Street, Los Angeles, CA 90013","street_number":"1356","route":"Palmetto Street","zipcode":"90013","city":"Los Angeles","state":"California","country":"US","created_at":"2013-10-11T13:35:18.401-07:00","updated_at":"2015-02-27T11:12:18.665-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"2006700","location_id":19,"is_location":false,"price_level":3,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.230938 34.040227)","do_not_connect_to_api":true,"merged_with_place_id":7422})
  end
end
puts "\n\n\n--------------------\n- Recreating Grant & Green Saloon: [12376]"
if Place.where(id: 6693).any?
  place = Place.find_by(id: 12376)
  place ||= Place.find_by(place_id: 'ChIJZ2___fOAhYAROcumI5ra5Ag')
  if place.present?
    Place.find(6693).merge(place)
  else
    place = Place.create!({"id":12376,"name":"Grant \u0026 Green Saloon","reference":"CnRnAAAAU72C7Epw_zyKaJbJ_iseObnbzbyJql8ehV2590PswavPITes-wMqqjCbiio2yhceu82H5Z8AFWp6ZxxL4PzulbYL3zR9gTdbvOkGh9_f2EOhE-2KIcpy4sC81ScX2dRN1d2fALJCx59asa4sY2tMNRIQTuJIIak-EVvHbpoP8WJ0xRoUqXR4FAXAAz8wAOEn3XMldHdvEmo","place_id":"ChIJZ2___fOAhYAROcumI5ra5Ag","types":["bar","establishment"],"formatted_address":"1371 Grant Avenue, San Francisco, CA 94133, United States","street_number":"1371","route":"Grant Avenue","zipcode":"94133","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-16T18:40:12.243-08:00","updated_at":"2015-02-18T10:54:46.787-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":35,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.407514 37.799586)","do_not_connect_to_api":true,"merged_with_place_id":6693})
  end
elsif Place.where(id: 12376).any?
  place = Place.find_by(id: 6693)
  place ||= Place.find_by(place_id: '26ebc6e9970ac9c59c77cf057d5c6ee43f0fd2c0')
  if place.present?
    Place.find(12376).merge(place)
  else
    place = Place.create!({"id":6693,"name":"Grant \u0026 Green Saloon","reference":"CoQBdQAAAI6XII3CKLNEnIteaONKR_ehC0PqpvW47kl1k3xTgXo2JfWs-iDU3bhjO1IqUTyctJQUTsw0M0VgQSC_Pnr-ntdxZhOjfBcpFn558vTslZedJYRzhkyKJCbTHCoB1qSv39vFiKUVDfBe74qg6D3hUF8VPdzQRdxciCHa_AfZrCfCEhDg-YlAUWmKhLIJzFUdCJ_TGhSDlcoomsXgGVdB0I2zURCY9sOnpg","place_id":"26ebc6e9970ac9c59c77cf057d5c6ee43f0fd2c0","types":["bar","establishment"],"formatted_address":"1371 Grant Ave, San Francisco, CA, United States","street_number":"1371","route":"Grant Ave","zipcode":"94133","city":"San Francisco","state":"California","country":"US","created_at":"2014-05-21T12:59:06.759-07:00","updated_at":"2015-02-09T12:02:59.244-08:00","administrative_level_1":"CA","administrative_level_2":"San Francisco County","td_linx_code":"5237238","location_id":35,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.407514 37.799586)","do_not_connect_to_api":true,"merged_with_place_id":12376})
  end
end
puts "\n\n\n--------------------\n- Recreating Hock Farm Craft & Provisions: [12281]"
if Place.where(id: 4449).any?
  place = Place.find_by(id: 12281)
  place ||= Place.find_by(place_id: 'ChIJCTQGLNjQmoARsucOUli5Ne8')
  if place.present?
    Place.find(4449).merge(place)
  else
    place = Place.create!({"id":12281,"name":"Hock Farm Craft \u0026 Provisions","reference":"CoQBfgAAAJm23qFnM36u0gt3PCC1YfZGMHryMwxk_gEn3ER1He58juI7EGDaOmYJp-9BZj2puQ0OUp14XYiOXkBXmBVtEDP4oZIqc8opexCe-ZFi2OR35XhBPLctWPk-3x3fiO8nMT1AWpkeGKrZty_vipUHhB2zxfJbwTXVnQ4c0-psLdXLEhAo-FQr9u8fdjr1gwTMkJQBGhRmk8neST1uCL_mYg6kdoF3s3dLKg","place_id":"ChIJCTQGLNjQmoARsucOUli5Ne8","types":["restaurant","food","establishment"],"formatted_address":"1415 L Street, Sacramento, CA 95814, United States","street_number":"1415","route":"L Street","zipcode":"95814","city":"Sacramento","state":"California","country":"US","created_at":"2015-02-11T18:35:45.838-08:00","updated_at":"2015-02-18T10:57:52.546-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":308,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.488255 38.57668)","do_not_connect_to_api":true,"merged_with_place_id":4449})
  end
elsif Place.where(id: 12281).any?
  place = Place.find_by(id: 4449)
  place ||= Place.find_by(place_id: '2cc3ac9c9478bade6e4c5753a6382e8824f34d00')
  if place.present?
    Place.find(12281).merge(place)
  else
    place = Place.create!({"id":4449,"name":"Hock Farm Craft \u0026 Provisions","reference":"CoQBfgAAALEIjFZ_6lPDopejpH5D-RuoemJpEvH7qJsqYqp3BJqN_yEucKPLq-cTEvt14KSsK78AraipbbDU1WCJS7L-W9rnfBR_q8KwMKLZPfuW9I7yXE1lcgX1Bc3Wu8LwYHpjwEHJKxKIQAE0pe3COeB56bjMeRhLF-UJV43cSfRBYTNPEhA8k4Zl-CWgweFY5jCiJ7thGhSPJ39ebsgmjfKYDRSSw6hWxJg7MQ","place_id":"2cc3ac9c9478bade6e4c5753a6382e8824f34d00","types":["restaurant","food","establishment"],"formatted_address":"1415 L St, Sacramento, CA, United States","street_number":"1415","route":"L St","zipcode":"95814","city":"Sacramento","state":"California","country":"US","created_at":"2014-02-01T09:25:43.971-08:00","updated_at":"2014-02-17T20:27:13.517-08:00","administrative_level_1":"CA","administrative_level_2":"Sacramento","td_linx_code":"1915968","location_id":1044,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.488522 38.576651)","do_not_connect_to_api":true,"merged_with_place_id":12281})
  end
end
puts "\n\n\n--------------------\n- Recreating The Violet Hour: [11991]"
if Place.where(id: 3708).any?
  place = Place.find_by(id: 11991)
  place ||= Place.find_by(place_id: 'ChIJazuRe8fSD4gRJeLBiMM_Izg')
  if place.present?
    Place.find(3708).merge(place)
  else
    place = Place.create!({"id":11991,"name":"The Violet Hour","reference":"CnRwAAAA9gZmCHe5k4jiAkz-Vrnae87EmGLSmbIGaWAGJXIySuKuF7EqAYKYbCtk0jIPPz-w_u5nJGG2-g7cG8jKiyEg21iXDG6gwaJ_8oW7f-EzkJb8dTeLFsUnbbEGIqTzYLEeR5U-oIctLLEKxG7npnvuFRIQitujA5uOo92s43oDgaQfNRoUVKOUBh6LDPy2R0W86Mda4PvcBeI","place_id":"ChIJazuRe8fSD4gRJeLBiMM_Izg","types":["night_club","bar","establishment"],"formatted_address":"1520 North Damen Avenue, Chicago, IL 60622, United States","street_number":"1520","route":"North Damen Avenue","zipcode":"60622","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-03T10:22:18.214-08:00","updated_at":"2015-02-03T10:22:18.214-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5056690","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.67782 41.908964)","do_not_connect_to_api":true,"merged_with_place_id":3708})
  end
elsif Place.where(id: 11991).any?
  place = Place.find_by(id: 3708)
  place ||= Place.find_by(place_id: '3178c058abc3c3550cbb6973b00fdd17abdc3495')
  if place.present?
    Place.find(11991).merge(place)
  else
    place = Place.create!({"id":3708,"name":"The Violet Hour","reference":"CoQBcQAAAP1e8lwgu-honi6CSV2fcAUMapGPMy07pydKiz3Y7-jq3gQexy5MPQczN2cEtZCz2dJx5Ymdx1XjguPuxxkSaY7OTyfgApTfzCTsw0-ZpzCTNez_vy41spF-AES1wFeq2Eh4GteELa-Be0NB0dmZA8trXCGlS8zlMscLRtQnKt_jEhC5rD3LoTQ-T_mE6SNNTsCgGhTp4kpQMYOhS-0SjiJ8bFENE98bLg","place_id":"3178c058abc3c3550cbb6973b00fdd17abdc3495","types":["night_club","bar","establishment"],"formatted_address":"1520 North Damen Avenue, Chicago, IL, United States","street_number":"1520","route":"North Damen Avenue","zipcode":"60622","city":"Chicago","state":"Illinois","country":"US","created_at":"2013-12-19T15:42:00.204-08:00","updated_at":"2014-02-17T20:22:53.646-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5056690","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.677554 41.909107)","do_not_connect_to_api":true,"merged_with_place_id":11991})
  end
end
puts "\n\n\n--------------------\n- Recreating Crocodile: [12265]"
if Place.where(id: 351).any?
  place = Place.find_by(id: 12265)
  place ||= Place.find_by(place_id: 'ChIJbQoeEsfSD4gRCsroMtlEi7w')
  if place.present?
    Place.find(351).merge(place)
  else
    place = Place.create!({"id":12265,"name":"Crocodile","reference":"CnRsAAAAkRDPx9JXXLaaoOeZdjWKzWJo0IN8_Gvv36kZJJSjIVhxJNaISFsOx8WTbz_Ecw6zrg82cUckH-7E54kSyVI4T9j-I7pSgbH-2zfXg-cE5dEOAs3WP0eWoH5wl5iVMCdEMeubyLIpHSH7yjGdmvIQzBIQjcxa91XE34L2G2TJgZpgIBoUEnuxnTVQFaoUtfdYWCZ3GCcRKoo","place_id":"ChIJbQoeEsfSD4gRCsroMtlEi7w","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"1540 North Milwaukee Avenue, Chicago, IL 60622, United States","street_number":"1540","route":"North Milwaukee Avenue","zipcode":"60622","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-10T20:55:24.245-08:00","updated_at":"2015-02-18T10:57:55.718-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5031853","location_id":43,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.676184 41.909403)","do_not_connect_to_api":true,"merged_with_place_id":351})
  end
elsif Place.where(id: 12265).any?
  place = Place.find_by(id: 351)
  place ||= Place.find_by(place_id: 'af290760e787aa9dbe82e08fe2d8fab83ea96be1')
  if place.present?
    Place.find(12265).merge(place)
  else
    place = Place.create!({"id":351,"name":"Crocodile","reference":"CnRnAAAAE-YoQjY8mQg1EyhTL30xXUFFdPVNftbQz5d05D9_f-tHue_BIHa17BKqeLTi-HpSj3aNen2dVVy1GvOTndH3OdSdUvOGVoCm9yT2oAuBJ1OpqESUTL3l0toOOoJjGEPY5nHh2BYCF1cDoTC5oo_HfRIQ_LFxYYjBfbBjPYMWYTLrmRoUtWu5HO44kdtLPor6A7YM9-WH3zo","place_id":"af290760e787aa9dbe82e08fe2d8fab83ea96be1","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"1540 North Milwaukee Avenue, Chicago, IL, United States","street_number":"1540","route":"North Milwaukee Avenue","zipcode":"60622","city":"Chicago","state":"Illinois","country":"US","created_at":"2013-10-11T13:35:50.908-07:00","updated_at":"2014-02-17T20:05:14.476-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5031853","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.676187 41.90944)","do_not_connect_to_api":true,"merged_with_place_id":12265})
  end
end
puts "\n\n\n--------------------\n- Recreating 1714 N Highland Ave: [10031]"
if Place.where(id: 12108).any?
  place = Place.find_by(id: 10031)
  place ||= Place.find_by(place_id: 'e8ec4846e4cfd6f1367ac2ae7605825c1f44def5')
  if place.present?
    Place.find(12108).merge(place)
  else
    place = Place.create!({"id":10031,"name":"1714 N Highland Ave","reference":"CqQBnAAAACUkNySrNElUa_blYk5x3GEVmCLhrvh2cTcQrqzAulRchxzuXAzIBGQ5HpnBNSw5UptevXARSLdU694PET8Y5mA1tbAFf7R1F1lrrUTM5J_7DMVT2-5dAm6RrDhHwqx_e0b1WYNeqSqCIcmBNQ4Pyes4j7chXHVBCqDY_9iL8DSFPNwSI2T3wan_rRSem8UkdTAtY18rlnt95Twl5m_fo9kSEB0t8UoMOeBOzCwHvACrJy0aFBeQZKT_0ZuQouGthBW24WSiU8Oy","place_id":"e8ec4846e4cfd6f1367ac2ae7605825c1f44def5","types":["street_address"],"formatted_address":"1714 N Highland Ave, Los Angeles, CA 90028, USA","street_number":"1714","route":"N Highland Ave","zipcode":"90028","city":"Los Angeles","state":"California","country":"US","created_at":"2014-11-22T18:52:41.875-08:00","updated_at":"2014-11-22T18:52:41.875-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":nil,"location_id":20,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.338414 34.10216)","do_not_connect_to_api":true,"merged_with_place_id":12108})
  end
elsif Place.where(id: 10031).any?
  place = Place.find_by(id: 12108)
  place ||= Place.find_by(place_id: 'ChIJS-ltvCO_woARLsGuVLUOaVA')
  if place.present?
    Place.find(10031).merge(place)
  else
    place = Place.create!({"id":12108,"name":"1714 Highland Ave","reference":"CqQBmQAAANOM2TCnFsSP42K5VWudsIAs2Xtj1b7OlWbDx26vgK-PcEOmfgsT8aMRL0wbttai-pJgdrzVoGn25Fwiexn-n2hUhPPzngrO_p2YWh86lARSoiNZ-hfHXh8F6Qus-HPNEq3R2nurg3M_9jDRKvJsl48Pi4PMS3rw-0aHUFPdv-SIidGYRsPiZGzMADgomFIMSVHNsXmQiFaj4SuYFv2RTawSEBQ4VHcQqvdHBDhHZyoRZiAaFGGMaJSsCqYcsOcDpQsS3QoQ5IQ1","place_id":"ChIJS-ltvCO_woARLsGuVLUOaVA","types":["street_address"],"formatted_address":"1714 Highland Ave, Los Angeles, CA 90028, USA","street_number":"1714","route":"Highland Ave","zipcode":"90028","city":"Los Angeles","state":"California","country":"US","created_at":"2015-02-06T10:24:56.039-08:00","updated_at":"2015-02-10T17:34:10.911-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":nil,"location_id":22,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":["Central LA"],"lonlat":"POINT (-118.338414 34.10216)","do_not_connect_to_api":true,"merged_with_place_id":10031})
  end
end
puts "\n\n\n--------------------\n- Recreating Surfcomber Hotel South Beach, a Kimpton Hotel: [6685]"
if Place.where(id: 3637).any?
  place = Place.find_by(id: 6685)
  place ||= Place.find_by(place_id: '21d8dfe096488d50ba828719231fa9d926931883')
  if place.present?
    Place.find(3637).merge(place)
  else
    place = Place.create!({"id":6685,"name":"Surfcomber Hotel South Beach, a Kimpton Hotel","reference":"CpQBjwAAAAL2i3cUbBpBnJTbRiH3IlUzmU7KmpQR4x-VKTNBdyrRQFXDUqzM91D_s922GKElH_bgCrcez9vVpTHRmyK0dIkv-ubnidhKgvuEQ1teYIFVJaJyKhqYWpLWqliTO6dQ4pk3tg414ksMRRdA4ORBXr7jD9FLZtanuaZ6gCkyU3DF77Y38hFGGdhEUbEvv3AaaRIQJBSa6FWbUiMcfQ33yRjSahoUHQZpoaqcnhAxSxYwSuM46HRwy0Q","place_id":"21d8dfe096488d50ba828719231fa9d926931883","types":["lodging","establishment"],"formatted_address":"1717 Collins Ave, Miami Beach, FL, United States","street_number":"1717","route":"Collins Ave","zipcode":"33139","city":"Miami Beach","state":"Florida","country":"US","created_at":"2014-05-21T08:19:10.255-07:00","updated_at":"2014-05-21T08:19:10.255-07:00","administrative_level_1":"FL","administrative_level_2":"Miami-Dade County","td_linx_code":nil,"location_id":886,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.128789 25.792942)","do_not_connect_to_api":true,"merged_with_place_id":3637})
  end
elsif Place.where(id: 6685).any?
  place = Place.find_by(id: 3637)
  place ||= Place.find_by(place_id: '97999acff6c6ae04f365fe3fd4cc2b54a5c40037')
  if place.present?
    Place.find(6685).merge(place)
  else
    place = Place.create!({"id":3637,"name":"Surfcomber","reference":"CqQBmQAAAG5Bl-8DNpqS_WAmKv5mvQ77CzjplCAC0UJvf-_yBG1-InrEDdGAXYpnjQC6FCUEiutNYUjPcaOZfMt4iu0HZY8NgbAXDNdIHDOd8AvCe7HCywx5Wgp_bZ7x9SpZQ0nQKAjBybn35d6lETgSc58ghOjO3uITeKMCXUsFgC2U6OCb2USxEOsuR9j-lE7BvbTK5sxNa2bggiLX_BEWsmbw4b0SELcXFEGYrJQZTa9zI7L3HtgaFKblYxRo8_Ao5WcRjfuscmpLUxMj","place_id":"97999acff6c6ae04f365fe3fd4cc2b54a5c40037","types":["street_address"],"formatted_address":"1717 Collins Ave, Miami Beach, FL 33139, USA","street_number":"1717","route":"Collins Ave","zipcode":"33139","city":"Miami Beach","state":"Florida","country":"US","created_at":"2013-12-16T11:02:46.830-08:00","updated_at":"2014-02-17T20:22:29.353-08:00","administrative_level_1":"FL","administrative_level_2":"Miami-Dade","td_linx_code":"5156721","location_id":886,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.1295666 25.7928216)","do_not_connect_to_api":true,"merged_with_place_id":6685})
  end
end
puts "\n\n\n--------------------\n- Recreating Binny's Beverage Depot: [11902]"
if Place.where(id: 6319).any?
  place = Place.find_by(id: 11902)
  place ||= Place.find_by(place_id: 'ChIJ-yE7piHTD4gRK9muqgKzLxs')
  if place.present?
    Place.find(6319).merge(place)
  else
    place = Place.create!({"id":11902,"name":"Binny's Beverage Depot","reference":"CoQBdwAAAEc1lKGhpSaKGuEhIND8q8Ia15NGupocnMzmNWqtt0Mk4HCWpQ7NkBxBi4AoyiNN75Np97mbRc05fW2Dkp-hv1M5dSwlUMA7hYwI2Pyor_HJ4S_bFtQt70r3IkZJ3h8XCGgTFJ0qPPTVgrh5gHgP2xCFtHyqddxG0PaBUpGg-HIGEhA9w0k_dHkURNwryqiGtgRKGhRxIKbwGUryX3nj4031HANwumNwaw","place_id":"ChIJ-yE7piHTD4gRK9muqgKzLxs","types":["liquor_store","food","store","establishment"],"formatted_address":"1720 North Marcey Street, Chicago, IL 60614, United States","street_number":"1720","route":"North Marcey Street","zipcode":"60614","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-01T12:15:31.229-08:00","updated_at":"2015-02-01T12:15:31.229-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"1402581","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.655331 41.91302)","do_not_connect_to_api":true,"merged_with_place_id":6319})
  end
elsif Place.where(id: 11902).any?
  place = Place.find_by(id: 6319)
  place ||= Place.find_by(place_id: '093e127e31e3d0bca561dec8e061fc4929569cfc')
  if place.present?
    Place.find(11902).merge(place)
  else
    place = Place.create!({"id":6319,"name":"Binny's Beverage Depot","reference":"CoQBeAAAAAw2_HNSGyL3VbvttGqWQ95d2o4x1KBw483WDOYXIhqxapzc_6D2ZPGvVS-Zf6HfJV4t1k55sTuzuUYXwForAFUqgvNqE2SAppmCHRd7sUlXIF-s21afZUPJ8YJ2jeNce9FLVvoWjfltkdRW0IOyW6rv-RrZKtJjKaN7ZmZunUvjEhBF8U4b1Lq3dKUYqXuBaYenGhSINHPhCvRP-6Y320zuHLyZWcefYA","place_id":"093e127e31e3d0bca561dec8e061fc4929569cfc","types":["liquor_store","store","establishment"],"formatted_address":"1720 N Marcey St, Chicago, IL, United States","street_number":"1720","route":"N Marcey St","zipcode":"60614","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-04-30T15:49:02.729-07:00","updated_at":"2014-04-30T15:49:02.729-07:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"1402581","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.655159 41.912952)","do_not_connect_to_api":true,"merged_with_place_id":11902})
  end
end
puts "\n\n\n--------------------\n- Recreating The Brick Yard: [12135]"
if Place.where(id: 7744).any?
  place = Place.find_by(id: 12135)
  place ||= Place.find_by(place_id: 'ChIJ52GptNyAhYARM3TnDDBKxmQ')
  if place.present?
    Place.find(7744).merge(place)
  else
    place = Place.create!({"id":12135,"name":"The Brick Yard","reference":"CnRwAAAAoQDdG_k0geNsq2Kl0YYoBattypF8jNheyPC1WlkeBnc57d0ZJ56u86yIaglIKBacDg-TPAR-IUfY9qJIGeIz7_e_fQc1h80pb32vg3qCPpfj97H8rj1ykI4s-Faj7A_KBlZ8a8o7K3UYMdwZ_ucp7RIQ1z4yNTsQ2_N1BEmKBcOLDxoU-lGDYsF8XkabwWI29yjQ02cufCw","place_id":"ChIJ52GptNyAhYARM3TnDDBKxmQ","types":["bar","restaurant","food","establishment"],"formatted_address":"1787 Union Street, San Francisco, CA 94123, United States","street_number":"1787","route":"Union Street","zipcode":"94123","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-06T23:03:21.139-08:00","updated_at":"2015-02-18T11:01:23.471-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5238374","location_id":35,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.428644 37.797814)","do_not_connect_to_api":true,"merged_with_place_id":7744})
  end
elsif Place.where(id: 12135).any?
  place = Place.find_by(id: 7744)
  place ||= Place.find_by(place_id: '28f9acab483fb2d9ba00a9b068a92a7dd44a728c')
  if place.present?
    Place.find(12135).merge(place)
  else
    place = Place.create!({"id":7744,"name":"The Brick Yard","reference":"CnRwAAAAywixV824JAH2T_Rg7gFNJHOw1Tb9w33vqIVCCv4aeJ4as2fqXBuTi165LsSyfgIl9XtWJA725M0HCtHnrYiI-d2OyPRFgVrUPqA7M6a6zgNql5N-bX5A_srbD8Jw-QS7ybu29zjX6Y5KchBEfXpeAxIQiU6FCA6ME21Zn9qlZ9iShxoU9aH2XyzeLOSaumChyXQ3zd_c068","place_id":"28f9acab483fb2d9ba00a9b068a92a7dd44a728c","types":["bar","restaurant","food","establishment"],"formatted_address":"1787 Union St, San Francisco, CA, United States","street_number":"1787","route":"Union St","zipcode":"94123","city":"San Francisco","state":"California","country":"US","created_at":"2014-08-13T07:12:52.607-07:00","updated_at":"2014-08-13T07:12:52.607-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5238374","location_id":35,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.428644 37.797814)","do_not_connect_to_api":true,"merged_with_place_id":12135})
  end
end
puts "\n\n\n--------------------\n- Recreating Whisler's: [4610]"
if Place.where(id: 3684).any?
  place = Place.find_by(id: 4610)
  place ||= Place.find_by(place_id: '8a91e0ea931f6bd1db701e4a66e600e044e39ff1')
  if place.present?
    Place.find(3684).merge(place)
  else
    place = Place.create!({"id":4610,"name":"Whisler's","reference":"CnRrAAAARNmfSwszj3yE9I5wwADf7QfrFN2CMA0yQzmFTxcX9JRLbpOYOnPgzASUFPdUgYNrjjwztkwrUf9bxtEgEeayqZc3pKByIZ1WrOCN_ik-nZCpE5cyzhfGHZrrjNyCJsK5dXbhvCW_xIz7RgV2oEHHoBIQ9egHbtuWns1VhB3nE2Go6hoUxdCBR0mzalv0uBUZOdT_VfFyQm0","place_id":"8a91e0ea931f6bd1db701e4a66e600e044e39ff1","types":["bar","restaurant","food","establishment"],"formatted_address":"1814 E 6th St, Austin, TX, United States","street_number":"1814","route":"E 6th St","zipcode":"78702","city":"Austin","state":"Texas","country":"US","created_at":"2014-02-09T20:49:19.105-08:00","updated_at":"2014-02-17T20:28:07.767-08:00","administrative_level_1":"TX","administrative_level_2":"Travis County","td_linx_code":"5627068","location_id":116,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.722689 30.261932)","do_not_connect_to_api":true,"merged_with_place_id":3684})
  end
elsif Place.where(id: 4610).any?
  place = Place.find_by(id: 3684)
  place ||= Place.find_by(place_id: 'fbd1911bd34fc8a544ed6efe73f430f23e203ed2')
  if place.present?
    Place.find(4610).merge(place)
  else
    place = Place.create!({"id":3684,"name":"Whisler's","reference":"CnRrAAAAk7NV9eKUlV5yW7QMjp5kyys3r3NfCnPV91a9uxE28HIgDOE9O_fBa0PaK5jxzhw5zmzkLvmPDp1qcbYzR4xU8Hrh1FD5yUCzbm1ks-GZP6f1ChsB1tUhYHg897TDf-CfMGtZOQ3jYep0MFrgKlE2exIQlRDL-Mby93QbDcShhLhLahoU6etNQr-uWMTZAwg5ygMzO1ln0vY","place_id":"fbd1911bd34fc8a544ed6efe73f430f23e203ed2","types":["food","bar","establishment"],"formatted_address":"1814 East 6th Street, Austin, TX, United States","street_number":"1814","route":"East 6th Street","zipcode":"78702","city":"Austin","state":"Texas","country":"US","created_at":"2013-12-18T13:34:18.071-08:00","updated_at":"2014-02-17T20:22:45.701-08:00","administrative_level_1":"TX","administrative_level_2":"Travis County","td_linx_code":"5627068","location_id":27,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.722907 30.261934)","do_not_connect_to_api":true,"merged_with_place_id":4610})
  end
end
puts "\n\n\n--------------------\n- Recreating School Yard Bar & Grill: [12343]"
if Place.where(id: 8927).any?
  place = Place.find_by(id: 12343)
  place ||= Place.find_by(place_id: 'ChIJnRNao90YBYgRJ6ZBYfQ4jVE')
  if place.present?
    Place.find(8927).merge(place)
  else
    place = Place.create!({"id":12343,"name":"School Yard Bar \u0026 Grill","reference":"CnRqAAAA5PMpNj8upJJEm023vXFEDV0Nq5OyojjIcICy1pe7sM4I6tz6KHTox8hdzQxi0Cc2ti8o28Z0DGVctNxwx3Lbzi5ElXE-Q7fQsa3vBC4zmEyVoA230_C8Beri-h3LnPYGto8-gn1cITJ7tr4HCzx5bhIQ1SxGZnYNy6da1hZtv1GmJRoU36brQRVeR6fBpx8NuektGAgbC7k","place_id":"ChIJnRNao90YBYgRJ6ZBYfQ4jVE","types":["bar","restaurant","food","establishment"],"formatted_address":"1815 East Kenilworth Place, Milwaukee, WI 53202, United States","street_number":"1815","route":"East Kenilworth Place","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2015-02-15T20:11:04.879-08:00","updated_at":"2015-02-18T10:54:53.487-08:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":nil,"location_id":646,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.887497 43.059796)","do_not_connect_to_api":true,"merged_with_place_id":8927})
  end
elsif Place.where(id: 12343).any?
  place = Place.find_by(id: 8927)
  place ||= Place.find_by(place_id: '82423231156fb2fd61920b28d486ba50b76a2da3')
  if place.present?
    Place.find(12343).merge(place)
  else
    place = Place.create!({"id":8927,"name":"School Yard Bar \u0026 Grill","reference":"CoQBeAAAAEMJ_9OFFzk4o6pcekWinBbsb61CDte85oQ6viu7EzdMc94-2qu-_gqtwvdjsjtO3HSY1xoqm71NSbN0474NA8NRlQhPqveZQwAaGJJrieQnzi4VGaGb-9rKEHHDXJsteyRSu3c3GzXVDA2r1bEyH2XV3QP_4GB2CWiKiI7brzzKEhA78UAtki_HKbbGDwYIg8iZGhQpd2yluKSILb_LxKk83uTvCmj_XA","place_id":"82423231156fb2fd61920b28d486ba50b76a2da3","types":["bar","restaurant","food","establishment"],"formatted_address":"1815 E Kenilworth Pl, Milwaukee, WI 53202, United States","street_number":"1815","route":"E Kenilworth Pl","zipcode":"53202","city":"Milwaukee","state":"Wisconsin","country":"US","created_at":"2014-10-15T23:31:20.506-07:00","updated_at":"2014-10-15T23:31:20.506-07:00","administrative_level_1":"WI","administrative_level_2":nil,"td_linx_code":"1860176","location_id":646,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.887335 43.059723)","do_not_connect_to_api":true,"merged_with_place_id":12343})
  end
end
puts "\n\n\n--------------------\n- Recreating Viceroy Santa Monica: [11857]"
if Place.where(id: 3928).any?
  place = Place.find_by(id: 11857)
  place ||= Place.find_by(place_id: 'ChIJw50IuNWkwoAR3fGFM62emXk')
  if place.present?
    Place.find(3928).merge(place)
  else
    place = Place.create!({"id":11857,"name":"Viceroy Santa Monica","reference":"CoQBdQAAAI5ZLRocmoR8ns6gQyuJVSV2auJ5CDC6xnZ6g5rL-O0j0u0ZVKAx7qhvliWzKPU8sMYQYqS9zUwjmykbdBne1fTxxSLDcl21QVMc_Uj_JI8R3siRihYaJXg3flVLuP56WOcr64vxY-BotlFdcp7S_WTpPaKo1P4Xpc8lLERT6ZRUEhC3i4VN-wq2K4EYCT-Yr6xyGhS8WiH9IphLiilASXZ5lFfv-CAhdw","place_id":"ChIJw50IuNWkwoAR3fGFM62emXk","types":["lodging","spa","health","establishment"],"formatted_address":"1819 Ocean Avenue, Santa Monica, CA 90401, United States","street_number":"1819","route":"Ocean Avenue","zipcode":"90401","city":"Santa Monica","state":"California","country":"US","created_at":"2015-01-30T17:48:26.430-08:00","updated_at":"2015-01-30T17:48:26.430-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":67,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.490338 34.008046)","do_not_connect_to_api":true,"merged_with_place_id":3928})
  end
elsif Place.where(id: 11857).any?
  place = Place.find_by(id: 3928)
  place ||= Place.find_by(place_id: 'c3f3c3cd14e4862d4a58f1c2e7e7c82737b913bc')
  if place.present?
    Place.find(11857).merge(place)
  else
    place = Place.create!({"id":3928,"name":"Viceroy Santa Monica","reference":"CoQBdQAAABUO1TUgy_aWGX-UrPcPLU1AU-X_UDe5Kud2oCZQp1J9IaiUJQQK_Kfb1nQhNb-LQ1BNmYW8oe7JPz-eVh5eVc94h67RM0-VHv6EGIpdWuLqRj-aZ4z-OryTyMdYGAvLvi9n_YGPMSTeGSjyzL4krLkID3kBU4fOJFZ_0CEb4ZyuEhDok02FTXeWmhY-H080orqoGhS0u24qiUhhfxwCimEe5z28SXk0Eg","place_id":"c3f3c3cd14e4862d4a58f1c2e7e7c82737b913bc","types":["lodging","spa","health","establishment"],"formatted_address":"1819 Ocean Avenue, Santa Monica, CA, United States","street_number":"1819","route":"Ocean Avenue","zipcode":"90401","city":"Santa Monica","state":"California","country":"US","created_at":"2014-01-07T10:35:16.939-08:00","updated_at":"2014-02-17T20:24:16.780-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5219921","location_id":67,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.490338 34.008046)","do_not_connect_to_api":true,"merged_with_place_id":11857})
  end
end
puts "\n\n\n--------------------\n- Recreating Coventry Panini's Grill: [12178]"
if Place.where(id: 10256).any?
  place = Place.find_by(id: 12178)
  place ||= Place.find_by(place_id: 'ChIJGX_QSED8MIgRVUPkOTPO7AE')
  if place.present?
    Place.find(10256).merge(place)
  else
    place = Place.create!({"id":12178,"name":"Coventry Panini's Grill","reference":"CoQBeAAAAMpuse89wwjn6c6sksLO03s_WoMHxaeOKeVfmnGbPc-NlIoHxbKq0n7OMhveIaRDO3urdFWG8hjg6rLDDp5UtR2s6fQMlNod-S1wFuYBgV-8SrRXIhhjbB9tCmqG3HfGfwL5Thh1qW03ySNCzo40VLqnsuYlTuqUt8I2-jbNLRlxEhByptAjG2LmTGt6geMyq_qUGhSngDTYt4Y3wAZFUgPB62eLHE59GA","place_id":"ChIJGX_QSED8MIgRVUPkOTPO7AE","types":["bar","restaurant","food","establishment"],"formatted_address":"1825 Coventry Road, Cleveland Heights, OH 44118, United States","street_number":"1825","route":"Coventry Road","zipcode":"44118","city":"Cleveland Heights","state":"Ohio","country":"US","created_at":"2015-02-09T05:30:20.048-08:00","updated_at":"2015-02-18T11:01:14.411-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":nil,"location_id":1026,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.579715 41.509899)","do_not_connect_to_api":true,"merged_with_place_id":10256})
  end
elsif Place.where(id: 12178).any?
  place = Place.find_by(id: 10256)
  place ||= Place.find_by(place_id: 'ff4ac4a073162f9694b7998d941f00f907f6a654')
  if place.present?
    Place.find(12178).merge(place)
  else
    place = Place.create!({"id":10256,"name":"Coventry Panini's Grill","reference":"CoQBeAAAAN4PKyjBdmxXHAPXpEp5yHCVvmaTVnLdnet_vNFqnyu_fu6j_QvX2hd57tapUgUwYJKv2EtRwtlE4AxlqcZ8rFnGD8VYXS2-n7aJibO2gWXVJ9SKDpYGsDb8TjVhmtmHSZX_T076qiCpLULyJojoKDap05BbYPtROVsfsCFYLs2tEhAafXQZE0ZkRu6iJx5EfQXaGhQwFfpLwFFqvPO9ZQZdg-lPy6y8NQ","place_id":"ff4ac4a073162f9694b7998d941f00f907f6a654","types":["bar","restaurant","food","establishment"],"formatted_address":"1825 Coventry Rd, Cleveland Heights, OH 44118, United States","street_number":"1825","route":"Coventry Rd","zipcode":"44118","city":"Cleveland Heights","state":"Ohio","country":"US","created_at":"2014-12-01T07:24:15.169-08:00","updated_at":"2014-12-01T07:24:15.169-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":nil,"location_id":1026,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.579715 41.509899)","do_not_connect_to_api":true,"merged_with_place_id":12178})
  end
end
puts "\n\n\n--------------------\n- Recreating Pour House: [11909]"
if Place.where(id: 4451).any?
  place = Place.find_by(id: 11909)
  place ||= Place.find_by(place_id: 'ChIJV-rkit3QmoAR5eQWcCUavZA')
  if place.present?
    Place.find(4451).merge(place)
  else
    place = Place.create!({"id":11909,"name":"Pour House","reference":"CnRsAAAArFgwbfFS3TrBGEyBS6N5AlVK7TW_Tr9kVG8A3nm7BleXZ7g7a8n1OJANTJ8-PxDsW3HKawiY1TClI9ZyFs8wdOMND5ZEBiLv4xC-gS3Fy4F6xsiNtSZ7XozqdskK8m12O3xxbpPgu8hwDhDG2nAUlBIQRDlN8EtKwD7NyK7sBcrgOBoUYG-2bGoVBVwdsbfpdTOJ7FB788c","place_id":"ChIJV-rkit3QmoAR5eQWcCUavZA","types":["bar","restaurant","food","establishment"],"formatted_address":"1910 Q Street, Sacramento, CA 95811, United States","street_number":"1910","route":"Q Street","zipcode":"95811","city":"Sacramento","state":"California","country":"US","created_at":"2015-02-01T13:54:07.591-08:00","updated_at":"2015-02-01T13:54:07.591-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"2267276","location_id":308,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.484062 38.56901)","do_not_connect_to_api":true,"merged_with_place_id":4451})
  end
elsif Place.where(id: 11909).any?
  place = Place.find_by(id: 4451)
  place ||= Place.find_by(place_id: '02b5aec54e801eda5f9dbc238e09aff6b8d085d8')
  if place.present?
    Place.find(11909).merge(place)
  else
    place = Place.create!({"id":4451,"name":"Pour House","reference":"CnRtAAAAPMOipGqvLQ4dbDPvMGdSnoCc8RxipxoNEmfq0AG4amq0VgGqHwg0V50vgglY3YhWKF0DZGuckK__gWhMx36yV6wPMG6UZSogOz67xrG2IPDQNHp1jTfVtW-lDFmGVi36GJBoyt8bY82bnfbFhPTYyRIQe6H12m-d2Ey6LM2PViCUjxoUtg4ROeiu8zUycDmyFgyUVY3fqhE","place_id":"02b5aec54e801eda5f9dbc238e09aff6b8d085d8","types":["bar","restaurant","food","establishment"],"formatted_address":"1910 Q St, Sacramento, CA, United States","street_number":"1910","route":"Q St","zipcode":"95811","city":"Sacramento","state":"California","country":"US","created_at":"2014-02-01T09:55:53.958-08:00","updated_at":"2014-02-17T20:27:14.111-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"2267276","location_id":308,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.484042 38.569062)","do_not_connect_to_api":true,"merged_with_place_id":11909})
  end
end
puts "\n\n\n--------------------\n- Recreating Mickey Byrne's Irish Pub & Restaurant: [12208]"
if Place.where(id: 2353).any?
  place = Place.find_by(id: 12208)
  place ||= Place.find_by(place_id: 'ChIJP7a11aGr2YgRFjYb1xRdHE8')
  if place.present?
    Place.find(2353).merge(place)
  else
    place = Place.create!({"id":12208,"name":"Mickey Byrne's Irish Pub \u0026 Restaurant","reference":"CpQBhwAAAKf-0-RtCZZ0KX66iFOJR8-eVrXB3JoPkkfWTUhjsbbwko4c2DwDBCjpwRRFODF9nzKt74rD6uXdWZP7XgkL1f7O1a1f1jlpFdN838Ff0sEqHU-0FyZJzIL8zWwGagRrJk2uNTGlwzqsHg9SmjFzioktMAxxBUBvpw3QtMM_SzOkgvojf5JXH7dAAbv41l1DEBIQBnxE5qdUwVukW3V6uZJpWBoUuATh9qTl5Hr39COKWtEu_Zt9W30","place_id":"ChIJP7a11aGr2YgRFjYb1xRdHE8","types":["bar","restaurant","food","establishment"],"formatted_address":"1921 Hollywood Boulevard, Hollywood, FL 33020, United States","street_number":"1921","route":"Hollywood Boulevard","zipcode":"33020","city":"Hollywood","state":"Florida","country":"US","created_at":"2015-02-09T11:12:34.740-08:00","updated_at":"2015-02-18T10:58:08.265-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"3191005","location_id":622,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.145831 26.011764)","do_not_connect_to_api":true,"merged_with_place_id":2353})
  end
elsif Place.where(id: 12208).any?
  place = Place.find_by(id: 2353)
  place ||= Place.find_by(place_id: 'e323f124a278fed1ce95ac53889e1b6d5239ab08')
  if place.present?
    Place.find(12208).merge(place)
  else
    place = Place.create!({"id":2353,"name":"Mickey Byrne's Irish Pub \u0026 Restaurant","reference":"CpQBhwAAAASov4BucYYstvTHecbroNiPTXJHOjjJO7z43RXmR-jBvNYfgesXR14QAL3TzEPqMDDq3zbSUOteT9c06eER3s_qv4VgSvaEK0Gl5iCDL-fOwkVPi9lamJZdArCOliX8WgKEU63HyLF1P69DgP2VKCrAMMwyRplUcsHJihh-JiNO4BdpXChvMUsiMg-C7oIgaBIQUK3qPgHmQdnGZIGmcIFUqxoUZGXuTbji5LCeYUB6CLnaazq7p5w","place_id":"e323f124a278fed1ce95ac53889e1b6d5239ab08","types":["bar","restaurant","food","establishment"],"formatted_address":"1921 Hollywood Boulevard, Hollywood, FL, United States","street_number":"1921","route":"Hollywood Boulevard","zipcode":"33020","city":"Hollywood","state":"Florida","country":"US","created_at":"2013-11-11T00:53:34.580-08:00","updated_at":"2014-02-17T20:15:19.975-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"3191005","location_id":622,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.145902 26.011555)","do_not_connect_to_api":true,"merged_with_place_id":12208})
  end
end
puts "\n\n\n--------------------\n- Recreating Stanley's Kitchen & Tap: [12326]"
if Place.where(id: 1275).any?
  place = Place.find_by(id: 12326)
  place ||= Place.find_by(place_id: 'ChIJHdqJzxTTD4gR5IY287MugIo')
  if place.present?
    Place.find(1275).merge(place)
  else
    place = Place.create!({"id":12326,"name":"Stanley's Kitchen \u0026 Tap","reference":"CnRrAAAABKr6Ehsi6wSuELBBPiD94K0aAaGAj828QhTHEwaO42HoLNGKt4AuC0u9OkBOKeiFA2XawgfzhQGFOjpu6PpVfkBbelEcGcTwMteO2yzls4FALXRP-40oFEmHiiXskDHu9jE6Tfoz24_8lkZGUIrwuBIQ07KJobGT0JG9WGOYYy2PmhoUCr22HP03eo2Ai8NBZiSVx6dAiPM","place_id":"ChIJHdqJzxTTD4gR5IY287MugIo","types":["bar","restaurant","food","establishment"],"formatted_address":"1970 North Lincoln Avenue, Chicago, IL 60614, United States","street_number":"1970","route":"North Lincoln Avenue","zipcode":"60614","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-14T11:43:46.965-08:00","updated_at":"2015-02-18T10:54:57.013-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":nil,"location_id":43,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.638607 41.917924)","do_not_connect_to_api":true,"merged_with_place_id":1275})
  end
elsif Place.where(id: 12326).any?
  place = Place.find_by(id: 1275)
  place ||= Place.find_by(place_id: 'fd60ed3751670f5d279f7cb7997e723f21e36952')
  if place.present?
    Place.find(12326).merge(place)
  else
    place = Place.create!({"id":1275,"name":"Stanley's Kitchen \u0026 Tap","reference":"CoQBeQAAACOKVc8dyfu26lRt7LvriCtP-9CM6k01WN5GPeM24oCzWtPkQ421GWC7fbY0nVcgJjfmcNEuvzvVE2PuFM7VuJTIOmU9Cc2F0cOqT2VJm21-xqEvvqhQokw0bavpY4JRAQG8pETUGkFlcblh3a5HvWi2Y-bdfy1b3NU0B-eTBLUbEhDWswqBN9yOhymC7M2HoIoSGhRF4wit3vnlJJFsY8vdJj7HcXoIGQ","place_id":"fd60ed3751670f5d279f7cb7997e723f21e36952","types":["bar","restaurant","food","establishment"],"formatted_address":"1970 North Lincoln Avenue, Chicago, IL, United States","street_number":"1970","route":"North Lincoln Avenue","zipcode":"60614","city":"Chicago","state":"Illinois","country":"US","created_at":"2013-10-25T18:06:02.639-07:00","updated_at":"2014-02-17T20:09:15.253-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5003004","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.638662 41.918081)","do_not_connect_to_api":true,"merged_with_place_id":12326})
  end
end
puts "\n\n\n--------------------\n- Recreating 1 Tippling Place: [11878]"
if Place.where(id: 3969).any?
  place = Place.find_by(id: 11878)
  place ||= Place.find_by(place_id: 'ChIJiV8LFDfGxokRUPrVhS6gQZY')
  if place.present?
    Place.find(3969).merge(place)
  else
    place = Place.create!({"id":11878,"name":"1 Tippling Place","reference":"CoQBcgAAANhRw09iPXUM76wwWTk_FS2sZy4bweatu0C2RKGqwo-IL2cfbnrOeGPRmJDfEQRwzV23asZjQWGwKek5jifv3oPXIyl36aSZGE_djbrJWNBjonD--cbCn5Uvi7nTZVuDv8h94ZgFyldGlZP--tyE-6g13XiaFVNoWvCSUSwxBiGgEhDDZ23kKJtBBB_2bJC9fMvrGhSpC7Z05yfDe39acvdd6l0aLBiDiQ","place_id":"ChIJiV8LFDfGxokRUPrVhS6gQZY","types":["bar","establishment"],"formatted_address":"2006 Chestnut Street, Philadelphia, PA 19103, United States","street_number":"2006","route":"Chestnut Street","zipcode":"19103","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2015-01-31T10:58:00.311-08:00","updated_at":"2015-02-04T09:05:58.811-08:00","administrative_level_1":"PA","administrative_level_2":nil,"td_linx_code":"3695301","location_id":62,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.173869 39.951893)","do_not_connect_to_api":true,"merged_with_place_id":3969})
  end
elsif Place.where(id: 11878).any?
  place = Place.find_by(id: 3969)
  place ||= Place.find_by(place_id: 'a31dbb9012373719009bcf5c4a0a9bdb3446817e')
  if place.present?
    Place.find(11878).merge(place)
  else
    place = Place.create!({"id":3969,"name":"1 Tippling Place","reference":"CoQBcwAAADMNhmflb2w5oM8TEtn9bED8xtRZE6gmwSp6ZHpestroFk12fpvgtxnfB9P2H6n3q1FQ_QAAos44zcBGisyPQcW5fIjH7k_hC7Wh-7D8GJzOnEvcNFaRfS2SmUn0SPncGXfEes9a7THDZBAsBiGcE8yKnc6iAFP5niZR1Ze2n_kSEhCMZYDL6huHfYbwBWXlUxhSGhSkqkZCBrBZVPzFJHV-5yp45L1y_g","place_id":"a31dbb9012373719009bcf5c4a0a9bdb3446817e","types":["bar","establishment"],"formatted_address":"2006 Chestnut Street, Philadelphia, PA, United States","street_number":"2006","route":"Chestnut Street","zipcode":"19103","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2014-01-10T01:09:25.097-08:00","updated_at":"2014-02-17T20:24:30.840-08:00","administrative_level_1":"PA","administrative_level_2":"Philadelphia County","td_linx_code":"3695301","location_id":63,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.173879 39.95204)","do_not_connect_to_api":true,"merged_with_place_id":11878})
  end
end
puts "\n\n\n--------------------\n- Recreating Q Street Bar & Grill: [12256]"
if Place.where(id: 1891).any?
  place = Place.find_by(id: 12256)
  place ||= Place.find_by(place_id: 'ChIJQ3a5gefQmoARkVldGlqeTTo')
  if place.present?
    Place.find(1891).merge(place)
  else
    place = Place.create!({"id":12256,"name":"Q Street Bar \u0026 Grill","reference":"CoQBdQAAAAv1thVEWGee7_wgHqZZkf-s8NXno4Y3kKJevW40IeV7gm2Zy_3B3bdHBdFMq8GPGquiat_LkMwKyeu8BS7aChOolVrzxPMqcs_K71fqY4TZnCoQaaEOCRytR0QHGAfWQgpuy7glf5xfjj0lfvL2ObEIqjfZC9DKvbw0w0e4LlghEhCEK_Q4YfmeShgdunPFWyGtGhRkFUkFFDkmCRRewUm_-X9io5IXkA","place_id":"ChIJQ3a5gefQmoARkVldGlqeTTo","types":["bar","establishment"],"formatted_address":"2013 Q Street, Sacramento, CA 95811, United States","street_number":"2013","route":"Q Street","zipcode":"95811","city":"Sacramento","state":"California","country":"US","created_at":"2015-02-10T14:44:04.181-08:00","updated_at":"2015-02-18T10:57:57.914-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5234986","location_id":308,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.482716 38.568994)","do_not_connect_to_api":true,"merged_with_place_id":1891})
  end
elsif Place.where(id: 12256).any?
  place = Place.find_by(id: 1891)
  place ||= Place.find_by(place_id: '6fb0c3a75dbf1488ec15ae47a96d6696b5b0296d')
  if place.present?
    Place.find(12256).merge(place)
  else
    place = Place.create!({"id":1891,"name":"Q Street Bar \u0026 Grill","reference":"CoQBdgAAAA2Lvi4TDHxinjwQCVxxAiA8JLXfjsODONTD7hnrVR6a3UxFe1OfsaXyBbUUeZwJMM-xgkVZJTb8cH5xK7gw1pFFJdKK-T4cnV3xX0Det1XVqgqNB-bBGEEwXIKgRBuMYEJihSUSymZy652swUnKX0gf5wJZf-g7bAtXoO_3MHgjEhB1RUTKI2QdTs-0F3koBoVTGhRpfcK29u1NZ_MjEicH2Gh9_2ezZg","place_id":"6fb0c3a75dbf1488ec15ae47a96d6696b5b0296d","types":["bar","establishment"],"formatted_address":"2013 Q Street, Sacramento, CA, United States","street_number":"2013","route":"Q Street","zipcode":"95811","city":"Sacramento","state":"California","country":"US","created_at":"2013-11-11T00:49:31.302-08:00","updated_at":"2014-02-17T20:12:56.569-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5234986","location_id":308,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.482734 38.568934)","do_not_connect_to_api":true,"merged_with_place_id":12256})
  end
end
puts "\n\n\n--------------------\n- Recreating Liquor Lyle's: [11924]"
if Place.where(id: 381).any?
  place = Place.find_by(id: 11924)
  place ||= Place.find_by(place_id: 'ChIJhWddgtoys1IR-58mn5Cq3lw')
  if place.present?
    Place.find(381).merge(place)
  else
    place = Place.create!({"id":11924,"name":"Liquor Lyle's","reference":"CnRuAAAAo2iyXDeGl_V0wMJBg7rQvHSGuKD8iUVt5LFmpJ_aECgmSRqQ9AKSvujyf4je5sFYonW-_ky-_Y9ARV6QYumSbES1ifWQCAV9MBD2YsL6viHJT7IHUjYeVBGrwR84ii_gy56jlYPVkiKqwbnphJ8DcxIQAugQIQfIhNAXg_uIczJpSRoUO3Djt5T3xojm36rYyNPno7yoAtk","place_id":"ChIJhWddgtoys1IR-58mn5Cq3lw","types":["bar","establishment"],"formatted_address":"2021 Hennepin Avenue, Minneapolis, MN 55405, United States","street_number":"2021","route":"Hennepin Avenue","zipcode":"55405","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2015-02-02T08:08:33.464-08:00","updated_at":"2015-02-02T08:08:33.464-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":nil,"location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.29155 44.96213)","do_not_connect_to_api":true,"merged_with_place_id":381})
  end
elsif Place.where(id: 11924).any?
  place = Place.find_by(id: 381)
  place ||= Place.find_by(place_id: 'd3b66fade7987714cf5c1ff4149e1d3384b241e2')
  if place.present?
    Place.find(11924).merge(place)
  else
    place = Place.create!({"id":381,"name":"Liquor Lyle's","reference":"CnRrAAAAtdROJs_kxK1IWBxZnieORTBTUxtL3L9ah_9Xxyd7fw-56gUObe6_M505C598svWpadPzPgpPwERIgqGVlOO8LJSpy1Wyq6dJWBrQzeOLcvsV_uQZWg_0n5C6dSqN_sUvzratqtHMtyignyD0HTgwdBIQ8XbUM9FnN_HtAv5JDp-IoxoUR6z6sM4B7yQqrm4yzrStEyJqPtI","place_id":"d3b66fade7987714cf5c1ff4149e1d3384b241e2","types":["bar","establishment"],"formatted_address":"2021 Hennepin Avenue, Minneapolis, MN, United States","street_number":"2021","route":"Hennepin Avenue","zipcode":"55405","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2013-10-11T13:36:07.184-07:00","updated_at":"2014-02-17T20:05:26.702-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"1616621","location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.291652 44.962149)","do_not_connect_to_api":true,"merged_with_place_id":11924})
  end
end
puts "\n\n\n--------------------\n- Recreating Stock in Trade: [12372]"
if Place.where(id: 77).any?
  place = Place.find_by(id: 12372)
  place ||= Place.find_by(place_id: 'ChIJfVUaqdCAhYAR-sBJn3ZxSu8')
  if place.present?
    Place.find(77).merge(place)
  else
    place = Place.create!({"id":12372,"name":"Stock in Trade","reference":"CnRiAAAAej5lMaLMQXSjyoDFGCXNJWqpFMV7OxCuBrBOXWaZKk51N10MgBi8GDxaVgR8EtxscTbFL0lP7WTLl8BdAFN4_tMRs6yJvHWp-eQmgmicDbSvvYXnCq0Zc66NMd5jQc307KswQ5p4h7DKpVCsO6WRCBIQFLTr4dD8BjaxMiJGKOwLgRoUGAugogDvxQA2VnFDXfKXuoMxriA","place_id":"ChIJfVUaqdCAhYAR-sBJn3ZxSu8","types":["bar","restaurant","food","establishment"],"formatted_address":"2036 Lombard Street, San Francisco, CA 94123, United States","street_number":"2036","route":"Lombard Street","zipcode":"94123","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-16T17:33:39.225-08:00","updated_at":"2015-02-18T10:54:47.508-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":35,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.435632 37.800041)","do_not_connect_to_api":true,"merged_with_place_id":77})
  end
elsif Place.where(id: 12372).any?
  place = Place.find_by(id: 77)
  place ||= Place.find_by(place_id: '23d46434dc1ff9e68864df91b03b0f369b61d71c')
  if place.present?
    Place.find(12372).merge(place)
  else
    place = Place.create!({"id":77,"name":"Stock in Trade","reference":"CnRtAAAAJYTOB2bWpkSk7ilG5TG8bvisEmO28m2qWjV-e9HSYRGRCWRR4KPAYKZqQrBK1Gi2dE4_J7Xpu_nlxEMHcK2tEkB1qM-Ssac_R3iNYm8G7GajOYVvLvsRdGtouMIad7-Nrs7x4nNaanw-1cjPet1HeBIQBR1SaZC5v8EXhAdIrbHonxoUaaMf2unruPF0q63rdNx67AFdECs","place_id":"23d46434dc1ff9e68864df91b03b0f369b61d71c","types":["bar","restaurant","food","establishment"],"formatted_address":"2036 Lombard Street, San Francisco, CA, United States","street_number":"2036","route":"Lombard Street","zipcode":"94123","city":"San Francisco","state":"California","country":"US","created_at":"2013-10-11T13:33:12.291-07:00","updated_at":"2014-02-17T20:03:44.544-08:00","administrative_level_1":"CA","administrative_level_2":"San Francisco","td_linx_code":"5237078","location_id":36,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.435632 37.800041)","do_not_connect_to_api":true,"merged_with_place_id":12372})
  end
end
puts "\n\n\n--------------------\n- Recreating Black Sheep Lodge INCORRECT: [7861]"
if Place.where(id: 11769).any?
  place = Place.find_by(id: 7861)
  place ||= Place.find_by(place_id: '62b10a619b0850d893fdc50ee5db42ab8d244db7')
  if place.present?
    Place.find(11769).merge(place)
  else
    place = Place.create!({"id":7861,"name":"Black Sheep Lodge INCORRECT","reference":"CoQBdAAAACuk2_aaSkKMHLDE-tDRiYN3TwupsLh0dnBYueSQZX101RJSPLlzxHLEwdogNoBaeknWN8tVeoFxqgdqfyGHs4OwI8OU02uHGXTaXOHcZp6oMf9cw8_nekRp-tEE3xds05vOvlWT5P5MTfmnLPkon7NOKuEa8rNUOcLFZWX8io0sEhCTz15m1Zs0Erghnz96XEJ4GhSH3awWk8L5R4sGmK7zRiHYMETLLg","place_id":"62b10a619b0850d893fdc50ee5db42ab8d244db7","types":["bar","restaurant","food","establishment"],"formatted_address":"2108 S Lamar Blvd, Austin, TX, United States","street_number":"2108","route":"S Lamar Blvd","zipcode":"78704","city":"Austin","state":"Texas","country":"US","created_at":"2014-08-24T23:14:23.506-07:00","updated_at":"2015-02-27T11:54:30.349-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"3631110","location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.771158 30.248408)","do_not_connect_to_api":true,"merged_with_place_id":11769})
  end
elsif Place.where(id: 7861).any?
  place = Place.find_by(id: 11769)
  place ||= Place.find_by(place_id: 'ChIJV4Bx_di0RIYRypD5mgDrIoA')
  if place.present?
    Place.find(7861).merge(place)
  else
    place = Place.create!({"id":11769,"name":"Black Sheep Lodge","reference":"CoQBcwAAANwmkphjNM3NMtKhXWdpNTj3uXLP_YMyricDHeX8WKk3YMiEePPDKPWwaMQy5Hp81285YGi5Yz3-BmLmS5HRdjL5922kbPNCrZpl-9c9jktsssZRA8hX7lAJl9vgv-xl3knPWLczaPLYwNWfZTLDiDdga026P_C81ltZvFaU7AU3EhDwHe-SAzUx61iUEV2egXCGGhTks8wXfhrAMrnUvvpg7hrhI0Wk3Q","place_id":"ChIJV4Bx_di0RIYRypD5mgDrIoA","types":["bar","restaurant","food","establishment"],"formatted_address":"2108 South Lamar Boulevard, Austin, TX 78704","street_number":"2108","route":"South Lamar Boulevard","zipcode":"78704","city":"Austin","state":"Texas","country":"US","created_at":"2015-01-28T08:37:09.702-08:00","updated_at":"2015-02-27T11:54:55.897-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"3631110","location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.771158 30.248408)","do_not_connect_to_api":true,"merged_with_place_id":7861})
  end
end
puts "\n\n\n--------------------\n- Recreating Fearing's Restaurant: [12080]"
if Place.where(id: 5556).any?
  place = Place.find_by(id: 12080)
  place ||= Place.find_by(place_id: 'ChIJ2wxVsjqZToYRFuIJD9uQt74')
  if place.present?
    Place.find(5556).merge(place)
  else
    place = Place.create!({"id":12080,"name":"Fearing's Restaurant","reference":"CoQBdwAAAPzPU2knJuI5kZk4t7LptPXf-l8AOtvYUNE6qBE0F_AggHHjDi6itQpxn38OYOkDQDVD31YGEWegM3IsWteh6c2vDtvRnYPQXgQXkSE8Xl02wAJP16B72PnOKNULv4MfvMk4GU4Qcxlwtsm0VMs5fJxYElyN0dw0aU_tVs09SgRVEhCOY6YckfDvj0ySKFUey5P7GhQbsoGNKvjCdj-miLIj4OekExUvHA","place_id":"ChIJ2wxVsjqZToYRFuIJD9uQt74","types":["bar","restaurant","food","establishment"],"formatted_address":"2121 McKinney Avenue, Dallas, TX 75201, United States","street_number":"2121","route":"McKinney Avenue","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2015-02-05T10:46:36.047-08:00","updated_at":"2015-02-18T11:01:34.408-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2229311","location_id":544,"is_location":false,"price_level":3,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.803324 32.792239)","do_not_connect_to_api":true,"merged_with_place_id":5556})
  end
elsif Place.where(id: 12080).any?
  place = Place.find_by(id: 5556)
  place ||= Place.find_by(place_id: '61441c36987b08d8d9a94752386d2a8e535f1ce3')
  if place.present?
    Place.find(12080).merge(place)
  else
    place = Place.create!({"id":5556,"name":"Fearing's Restaurant","reference":"CoQBdgAAAM0jlHi3aqTDwSJ92MvvEVORfAVpymXs6GtXUfPWLgpP-8zxZuGKO6iASNb97lcYJv7cMEvXD2DYDBIOMz-XqZHL9MvnSUm__VFm_DnUIIsNR4WDQGYR_oIKRWhdpAxrOomAkDijtj-zQDB0pPIlvK3Z9Rq6ppmEONGfDMqic-e9EhCDpuIPnhcIm9OopL0CrByRGhQ0SXPFmqCjT3QgQBwJm_sAQTmz4A","place_id":"61441c36987b08d8d9a94752386d2a8e535f1ce3","types":["restaurant","food","establishment"],"formatted_address":"2121 McKinney Ave, Dallas, TX, United States","street_number":"2121","route":"McKinney Ave","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2014-03-21T15:24:35.599-07:00","updated_at":"2014-03-21T15:24:35.599-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2229311","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.803324 32.792239)","do_not_connect_to_api":true,"merged_with_place_id":12080})
  end
end
puts "\n\n\n--------------------\n- Recreating Little Dom's: [12453]"
if Place.where(id: 1325).any?
  place = Place.find_by(id: 12453)
  place ||= Place.find_by(place_id: 'ChIJJd_jKbvAwoARfexmBv-1ZV0')
  if place.present?
    Place.find(1325).merge(place)
  else
    place = Place.create!({"id":12453,"name":"Little Dom's","reference":"CmRfAAAAEmA9v5wXtnQs7mmfuZtiXcCPrhfENP2ThTz4NiLqf7zlYBUUzJWh_aI2kuRYnsxpCLTCUWvzSLmQgoiukhMdgNmir-ONSwol9MZY8mxfdwJCa4HtVT1TXS8d2db_Fj8DEhBb2y_r6fLjQN9nkaiaFwqCGhRFZe7Je9E5D-w6ZA6pq29EU82kug","place_id":"ChIJJd_jKbvAwoARfexmBv-1ZV0","types":["store","bar","restaurant","food","establishment"],"formatted_address":"2128 Hillhurst Avenue, Los Angeles, CA 90027, United States","street_number":"2128","route":"Hillhurst Avenue","zipcode":"90027","city":"Los Angeles","state":"California","country":"US","created_at":"2015-02-18T12:09:21.795-08:00","updated_at":"2015-02-18T12:09:21.795-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.287193 34.110969)","do_not_connect_to_api":true,"merged_with_place_id":1325})
  end
elsif Place.where(id: 12453).any?
  place = Place.find_by(id: 1325)
  place ||= Place.find_by(place_id: '5f1e035754bc269b51c1c05eccdeefa166d4a7b6')
  if place.present?
    Place.find(12453).merge(place)
  else
    place = Place.create!({"id":1325,"name":"Little Dom's","reference":"CnRtAAAAgKSZV-Q9A6GJqVuRh9-jI1PS9EU7A3a_xBTe0F9O04nLxBa36TskM-eZWfbjHkf0fp0oadl5g_nMSO6DXsWP8ZGSrvYb85F2ATWJmESg3Vxj8tvMXmgKHlMQGS6QVo4We7pYOII6rZshwE0IlUj3GxIQ6EnY6Hj9NrFZYfnzWIdEZRoUGlAnglmCk4DigxWYizKQi7ux-Sg","place_id":"5f1e035754bc269b51c1c05eccdeefa166d4a7b6","types":["restaurant","food","establishment"],"formatted_address":"2128 Hillhurst Avenue, Los Angeles, CA, United States","street_number":"2128","route":"Hillhurst Avenue","zipcode":"90027","city":"Los Angeles","state":"California","country":"US","created_at":"2013-11-03T10:49:37.626-08:00","updated_at":"2014-02-17T20:09:30.742-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5246890","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.287268 34.11087)","do_not_connect_to_api":true,"merged_with_place_id":12453})
  end
end
puts "\n\n\n--------------------\n- Recreating Halligan Bar: [11758]"
if Place.where(id: 3955).any?
  place = Place.find_by(id: 11758)
  place ||= Place.find_by(place_id: 'ChIJ3QxcUhDTD4gR_HTruxpDDso')
  if place.present?
    Place.find(3955).merge(place)
  else
    place = Place.create!({"id":11758,"name":"Halligan Bar","reference":"CnRvAAAAOlTEySxrZbvId5h1Ka6JRQS-oMzSkboUKZWY8fgB_lxS6Yi2VP1-3JZrH8sVn_DO2pFxyoH1cnQb8BzJSAhUOCHqh93-PI4k13zqyVKWGVO3a2X-8hZptzstb8pVHjTRMBIBcs-JK156gZCnCLaPqhIQ_8JfFbsLm9X100E3ZkHmlhoUPdCR7zniv8W6nfIXBIwucTL8o2A","place_id":"ChIJ3QxcUhDTD4gR_HTruxpDDso","types":["bar","establishment"],"formatted_address":"2274 North Lincoln Avenue, Chicago, IL 60614, United States","street_number":"2274","route":"North Lincoln Avenue","zipcode":"60614","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-01-27T23:15:54.777-08:00","updated_at":"2015-01-27T23:15:54.777-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5019606","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.646082 41.923315)","do_not_connect_to_api":true,"merged_with_place_id":3955})
  end
elsif Place.where(id: 11758).any?
  place = Place.find_by(id: 3955)
  place ||= Place.find_by(place_id: '5efc8602d6b7bc92038f35df09f9219530d87f68')
  if place.present?
    Place.find(11758).merge(place)
  else
    place = Place.create!({"id":3955,"name":"Halligan Bar","reference":"CnRuAAAAAp84zL2L0GboJxM4pyPA9TjZcBSGjLnz6zlyGu4_NXWP9m1A4u9GlCJJBjgQ5NlXA5NGXeUYi3PNFDT-2U6FVnvya2IWIEnekfyN7NDsGzC38erxE-auqOhI96GzIkvD56rsHKOgT68zjH8D8_N2kRIQL9TLBvRT6cfd5WVwqlLp5hoU5KJCqgNsMaOH_nRfWdUCEdujbCg","place_id":"5efc8602d6b7bc92038f35df09f9219530d87f68","types":["bar","establishment"],"formatted_address":"2274 North Lincoln Avenue, Chicago, IL, United States","street_number":"2274","route":"North Lincoln Avenue","zipcode":"60614","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-01-08T18:24:02.540-08:00","updated_at":"2014-02-17T20:24:25.923-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":"5019606","location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.646113 41.923394)","do_not_connect_to_api":true,"merged_with_place_id":11758})
  end
end
puts "\n\n\n--------------------\n- Recreating Hendoc's Pub INCORRECT: [2217]"
if Place.where(id: 12402).any?
  place = Place.find_by(id: 2217)
  place ||= Place.find_by(place_id: '80a786489fc380e234de14a0c3434eb9996c7dbc')
  if place.present?
    Place.find(12402).merge(place)
  else
    place = Place.create!({"id":2217,"name":"Hendoc's Pub INCORRECT","reference":"CnRvAAAAvdWzF8igBXBbBXimvv5uIVltUVCfijY4ZkwUtZ-AyNHuaaG3jJ0XFiawu9Nhn1eynK3AX-sIWvYbQvvgNv3BwS0xEEKEltOymPhk0vW0CWFfiZ7uSNC3d1mD2Jz4HICwOKedS2SmZKjaIWDAdfhvBRIQP7nhp4JM0e9sHmp9KvkQxhoUdROdH7m2VnRwek-U58nuF7G9ByI","place_id":"80a786489fc380e234de14a0c3434eb9996c7dbc","types":["bar","establishment"],"formatted_address":"2375 North High Street, Columbus, OH, United States","street_number":"2375","route":"North High Street","zipcode":"43202","city":"Columbus","state":"Ohio","country":"US","created_at":"2013-11-11T00:52:38.551-08:00","updated_at":"2015-02-27T10:18:34.689-08:00","administrative_level_1":"OH","administrative_level_2":"Franklin County","td_linx_code":"5559749","location_id":528,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.010457 40.01071)","do_not_connect_to_api":true,"merged_with_place_id":12402})
  end
elsif Place.where(id: 2217).any?
  place = Place.find_by(id: 12402)
  place ||= Place.find_by(place_id: 'ChIJYfZv6KOOOIgRSkNoWPVz3dw')
  if place.present?
    Place.find(2217).merge(place)
  else
    place = Place.create!({"id":12402,"name":"Hendoc's Pub ","reference":"CmRgAAAA5NcDXIwvW-PG8qeGpODKSTHkrePmvb9dsRGgB9AIUmrndA-Z0auENXT5WkP4aV6JVBlJ5AWo2Q-ly4riSH-L09HyHfmmJo0syhnLMf5afquk5ouYOvr3FHnINI3x23KOEhCIz_NB5LnWcim37GUVTN-sGhSQ4PwFYOCS3R5ocj8eu0kxvGD7lw","place_id":"ChIJYfZv6KOOOIgRSkNoWPVz3dw","types":["bar","establishment"],"formatted_address":"2375 North High Street, Columbus, OH 43202, United States","street_number":"2375","route":"North High Street","zipcode":"43202","city":"Columbus","state":"Ohio","country":"US","created_at":"2015-02-17T07:49:42.763-08:00","updated_at":"2015-02-27T10:18:48.843-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":"5559749","location_id":528,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-83.010457 40.01071)","do_not_connect_to_api":true,"merged_with_place_id":2217})
  end
end
puts "\n\n\n--------------------\n- Recreating J. BLACK'S Feel Good Kitchen & Lounge: [11944]"
if Place.where(id: 2019).any?
  place = Place.find_by(id: 11944)
  place ||= Place.find_by(place_id: 'ChIJFbEsXzCfToYRcz6aJEQrUPI')
  if place.present?
    Place.find(2019).merge(place)
  else
    place = Place.create!({"id":11944,"name":"J. BLACK'S Feel Good Kitchen \u0026 Lounge","reference":"CpQBhwAAAOb0dvqBJRzeOJsWOP5HvGU46ne58UTp6sdZNhp8QkAVMGCPb3_DrK0vsj_-vFr-_Sfb2cXnIr9kktvr0zOqVJvuYzuaKhqb6odVoax1TaCyWpKOcvG6P6owmdJgMnjiOEmnNWRpntmMc48yB3g0QUpKtcy2AMfSPZbiZXFnegx92tXpfxc3qxyuz2JiefabVhIQtKTlB-5sDS4DEYtrJ1z6txoUKOnTbnVTCgr0sXLcWIgDNYZ9s3k","place_id":"ChIJFbEsXzCfToYRcz6aJEQrUPI","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"2409 North Henderson Avenue, Dallas, TX 75206, United States","street_number":"2409","route":"North Henderson Avenue","zipcode":"75206","city":"Dallas","state":"Texas","country":"US","created_at":"2015-02-02T11:02:30.091-08:00","updated_at":"2015-02-02T11:02:30.091-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.778988 32.815036)","do_not_connect_to_api":true,"merged_with_place_id":2019})
  end
elsif Place.where(id: 11944).any?
  place = Place.find_by(id: 2019)
  place ||= Place.find_by(place_id: 'ff52790aa8f06ce063a9541a1d10b59c1a95566a')
  if place.present?
    Place.find(11944).merge(place)
  else
    place = Place.create!({"id":2019,"name":"J. BLACK'S Feel Good Kitchen \u0026 Lounge","reference":"CpQBhwAAAOXs-i6o9fn0uO8BooaNdTKLNBURHHzVR1BhXWTxDPj0xiIUUGxzHr3j4ZOqbVs1fBDE-ttzJJsrVw9NCoqMKVEKmCV8D7FXHV4uKKAw1Avy6FnN6c-pxXoWY8Z14d8ymJ70kU9g0tiJqPW6aNhvX1AjaF5s0C5LHsfD4hJ_fUriFsu88Z28n-VzCHdhQIee9RIQEZbFdxuu14ZoPApvUmhc5hoUyPzIO5P7CYTr3MoxrRpbShrqwZM","place_id":"ff52790aa8f06ce063a9541a1d10b59c1a95566a","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"2409 North Henderson Avenue, Dallas, TX, United States","street_number":"2409","route":"North Henderson Avenue","zipcode":"75206","city":"Dallas","state":"Texas","country":"US","created_at":"2013-11-11T00:50:22.115-08:00","updated_at":"2014-02-17T20:13:39.537-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1674330","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.778924 32.815136)","do_not_connect_to_api":true,"merged_with_place_id":11944})
  end
end
puts "\n\n\n--------------------\n- Recreating Madam's Organ: [11910]"
if Place.where(id: 3524).any?
  place = Place.find_by(id: 11910)
  place ||= Place.find_by(place_id: 'ChIJHaWHK9q3t4kRxJy0xNHc0gE')
  if place.present?
    Place.find(3524).merge(place)
  else
    place = Place.create!({"id":11910,"name":"Madam's Organ","reference":"CnRuAAAA8HPArkwOiVkyYtBcO_3fEs5K-jmwFnzoa43-A3cusun6Uz3HdAxUoQO0y4pJsJ9vhHScbjEYY6AxtFBIW_1y8mv_0vQXICoNrBoubUQOZzM3CKxdpOQ5KHmT2XTp33OwlXNq2191-6r9z5HmK-MYIxIQ1vOcrqc5v5AAuUfH0oMM3xoUQV9toP4zZzRfWACor4ZPPZVz89M","place_id":"ChIJHaWHK9q3t4kRxJy0xNHc0gE","types":["night_club","bar","establishment"],"formatted_address":"2461 18th Street Northwest, Washington, DC 20009, United States","street_number":"2461","route":"18th Street Northwest","zipcode":"20009","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-02-01T13:58:42.491-08:00","updated_at":"2015-02-19T04:41:42.703-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"5067509","location_id":538,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.042157 38.92203)","do_not_connect_to_api":true,"merged_with_place_id":3524})
  end
elsif Place.where(id: 11910).any?
  place = Place.find_by(id: 3524)
  place ||= Place.find_by(place_id: 'fb45f644fabaf526e328e004abedac5cd792f9d7')
  if place.present?
    Place.find(11910).merge(place)
  else
    place = Place.create!({"id":3524,"name":"Madam's Organ","reference":"CnRvAAAAZ9NzRCb1iDV9oLDHOmRxY1HJf1ggNLdPu3jRqmj3PGZS5fzQ-hQ5BnuPv-cVgGLwNUIe1fzvbObBx2d8Bb7Znfdpk009AJ9abqKlZqpsfz5tHFOXtb9ROkMidR3d0ggdiXFeFuu35eoJoKgNacw0XBIQNNVIL5-HjRT5a7Akii5arBoUexglJNtRzcDF_douIk2uajcMgjI","place_id":"fb45f644fabaf526e328e004abedac5cd792f9d7","types":["night_club","bar","establishment"],"formatted_address":"2461 18th Street Northwest, Washington, DC, United States","street_number":"2461","route":"18th Street Northwest","zipcode":"20009","city":"Washington","state":"District of Columbia","country":"US","created_at":"2013-12-10T14:19:17.281-08:00","updated_at":"2015-01-26T11:09:30.331-08:00","administrative_level_1":"DC","administrative_level_2":"District of Columbia","td_linx_code":"5067509","location_id":538,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.042299 38.922004)","do_not_connect_to_api":true,"merged_with_place_id":11910})
  end
end
puts "\n\n\n--------------------\n- Recreating Nickel And Rye: [12088]"
if Place.where(id: 5119).any?
  place = Place.find_by(id: 12088)
  place ||= Place.find_by(place_id: 'ChIJG1YXMi6ZToYRw7FmN3YBD9c')
  if place.present?
    Place.find(5119).merge(place)
  else
    place = Place.create!({"id":12088,"name":"Nickel And Rye","reference":"CnRwAAAAByBHIXIdf4nE5-p2sd2J0oBXUXzT6lUjzSS0P4zs0z_TnZjhnl01PWIn88AKadltrnrV1G89H2agqwbU5y-ayKgZD9ohHhTs25HAy3AQ8kK5kDdw7y9TzNzu5G_v9K1TOrAyS9hV9-lQOjmsccU1yBIQhq_MoG6mif4V_9h1ldeedxoU6KS7QbUqsTEarbX4faUV-8wKzuQ","place_id":"ChIJG1YXMi6ZToYRw7FmN3YBD9c","types":["bar","restaurant","food","establishment"],"formatted_address":"2523 McKinney Avenue, Dallas, TX 75201, United States","street_number":"2523","route":"McKinney Avenue","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2015-02-05T11:54:13.073-08:00","updated_at":"2015-02-18T11:01:33.159-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1936249","location_id":544,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.802195 32.796101)","do_not_connect_to_api":true,"merged_with_place_id":5119})
  end
elsif Place.where(id: 12088).any?
  place = Place.find_by(id: 5119)
  place ||= Place.find_by(place_id: 'a0c97bf500a20305adb7233359353c6ec1d4acb0')
  if place.present?
    Place.find(12088).merge(place)
  else
    place = Place.create!({"id":5119,"name":"Nickel And Rye","reference":"CnRwAAAA_RuVu1FFDJ7eJ6pYv0fN-21hwpocpKvZ5XcS3xlIATrBpurGOLd_8JjCJaSuoYPnA5-jEQjgZFvJ8Z39pFguNVMrZB1TvF1fRzIiNNUHYhTdFUTTGVSn1VUyIgf9sGfJwHcAOmTfdpXwiY1TVzCxJxIQfryPxKbi4Pr8Inm6KZH4MxoUGlcKcifkbo5pwSr_STCrIpPcbx4","place_id":"a0c97bf500a20305adb7233359353c6ec1d4acb0","types":["restaurant","food","establishment"],"formatted_address":"2523 McKinney Ave, Dallas, TX, United States","street_number":"2523","route":"McKinney Ave","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2014-03-10T13:52:59.747-07:00","updated_at":"2015-02-17T18:16:43.697-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1936249","location_id":544,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.802215 32.796142)","do_not_connect_to_api":true,"merged_with_place_id":12088})
  end
end
puts "\n\n\n--------------------\n- Recreating C C Club: [7287]"
if Place.where(id: 373).any?
  place = Place.find_by(id: 7287)
  place ||= Place.find_by(place_id: '4b7b0dd73c9da5518afeab1e2fa8f2f7cf521981')
  if place.present?
    Place.find(373).merge(place)
  else
    place = Place.create!({"id":7287,"name":"C C Club","reference":"CoQBcwAAAB2HdPSl--ok94HbH7JpGItEVcRU8EpKkMJEL1gx6CH1A11LHYXVYdxaN5oBi8dLhlG0NzyRXZQNqVoGvLTO4x_odQ3jls2fXgs_YDyVLdN5dlO2lDlbevHOXNCLs0SM7t09P-PwGIbM5hFOV4907sqe0tYPLRtrdLx7FTaAX-U3EhDm6sh2CcGp3xA7Vgriv4nQGhTM66XdntmP-opY4s4uSA1ydNJ9sg","place_id":"4b7b0dd73c9da5518afeab1e2fa8f2f7cf521981","types":["bar","point_of_interest","establishment"],"formatted_address":"C C Club, 2600 Lyndale Ave S, Minneapolis, MN 55408, USA","street_number":"2600","route":"Lyndale Ave S","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2014-06-29T22:55:24.524-07:00","updated_at":"2014-06-29T22:55:24.524-07:00","administrative_level_1":"MN","administrative_level_2":"Hennepin County","td_linx_code":"5646401","location_id":111,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.2884438 44.955388)","do_not_connect_to_api":true,"merged_with_place_id":373})
  end
elsif Place.where(id: 7287).any?
  place = Place.find_by(id: 373)
  place ||= Place.find_by(place_id: '083e0e94322a21701bef5beda2562b9056dceebb')
  if place.present?
    Place.find(7287).merge(place)
  else
    place = Place.create!({"id":373,"name":"C C Club","reference":"CnRmAAAAL86iYevjSoHrzzdQZElpM6DyOoL3Fu6Pj-ZzEsZEYKa9tr4qd-jyGUTeZgJaIpf6OXPE-XYc0h-5OITb0oSBtSJw_xnSMkbyRg-uQtcu9FOSRDys1Ph16Gy6_6cZ7j9tzcfMw77n18ESjn5SrWIjkRIQsTtVBYfSveA6fDsctQGXUhoUXmIe47xvwvi3-KuIaiCTNErHB7w","place_id":"083e0e94322a21701bef5beda2562b9056dceebb","types":["bar","restaurant","food","establishment"],"formatted_address":"2600 Lyndale Avenue South, Minneapolis, MN, United States","street_number":"2600","route":"Lyndale Avenue South","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2013-10-11T13:36:01.884-07:00","updated_at":"2014-02-17T20:05:23.845-08:00","administrative_level_1":"MN","administrative_level_2":"Hennepin","td_linx_code":"5646401","location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.288257 44.95543)","do_not_connect_to_api":true,"merged_with_place_id":7287})
  end
end
puts "\n\n\n--------------------\n- Recreating The Lyndale Tap House: [12020]"
if Place.where(id: 369).any?
  place = Place.find_by(id: 12020)
  place ||= Place.find_by(place_id: 'ChIJJT1Lo4gn9ocRhtnA1GoSP6E')
  if place.present?
    Place.find(369).merge(place)
  else
    place = Place.create!({"id":12020,"name":"The Lyndale Tap House","reference":"CoQBeAAAAFVBCJQOcYmkso0619-mMgYJ2hVauEM_wzxkFQReKJjR1ypUmg0ZykjXfbl-D4Kj9qwk17BgTWPBQ2T4z7rkNfY5lS4cM5G576uJV_lZFY8YlcWCpgiN4JlHAQgvSSgWdUZcKvIKi4W3tLdl-lz-GuVABZGiDmq7PvO5_j44pAetEhDLXpT9awnHtCZ-sz2lddTFGhSrNaDZNp2secbcIYJLD40-l85GQg","place_id":"ChIJJT1Lo4gn9ocRhtnA1GoSP6E","types":["bar","restaurant","food","establishment"],"formatted_address":"2937 Lyndale Avenue South, Minneapolis, MN 55408, United States","street_number":"2937","route":"Lyndale Avenue South","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2015-02-03T19:32:54.820-08:00","updated_at":"2015-02-03T19:32:54.820-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"1865887","location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.287626 44.949128)","do_not_connect_to_api":true,"merged_with_place_id":369})
  end
elsif Place.where(id: 12020).any?
  place = Place.find_by(id: 369)
  place ||= Place.find_by(place_id: '20a7e5c30d683f29b057a39ee40540ca0f727a58')
  if place.present?
    Place.find(12020).merge(place)
  else
    place = Place.create!({"id":369,"name":"The Lyndale Tap House","reference":"CoQBdAAAACfPO8FckXSo16FSZBNMrf-0eUsJ7pNrS_kJ3I29DWLKpmii_MJUSbqFHenhNVMM2I3kWX1-X5eqs1XBuBmwtU0kfbnqgHZfPSs2YW0S3-ciKQhrQEpcq396eW2gm5obkD9MhnGIBUTh5W_EhxWCufMBT-Azfvb_Cg7BHSEPUaGBEhCnITCZ4BW-eT-pgGzNqjN7GhS9kC6NHvwraCuv_EVG7lH_oSrypg","place_id":"20a7e5c30d683f29b057a39ee40540ca0f727a58","types":["bar","restaurant","food","establishment"],"formatted_address":"2937 Lyndale Avenue South, Minneapolis, MN, United States","street_number":"2937","route":"Lyndale Avenue South","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2013-10-11T13:35:59.666-07:00","updated_at":"2014-02-17T20:05:22.185-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"1865887","location_id":12,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.28794 44.94912)","do_not_connect_to_api":true,"merged_with_place_id":12020})
  end
end
puts "\n\n\n--------------------\n- Recreating 6th Street Bar: [8116]"
if Place.where(id: 2303).any?
  place = Place.find_by(id: 8116)
  place ||= Place.find_by(place_id: '46977208dacd1566ebfe6e373b3da87bec05e3f4')
  if place.present?
    Place.find(2303).merge(place)
  else
    place = Place.create!({"id":8116,"name":"6th Street Bar","reference":"CnRvAAAAJUwOdGvjnzm0_btfU6WK11WKYqboW4vBtK0RJI0yp_rXt-esacblOTUltR5x6lf_u5zKuDI0_dhU1ue3i390QOZJK0ly66MaWssW-TC6x7dKD5MZqx7S7sZh8DtIGh9BC6NS0hzQl_DF-witW0SsjRIQB7AbMOdNOiVg4QAcahhBmRoUi2ylh3Jw0cw19O3Tvi2_FI_-2qU","place_id":"46977208dacd1566ebfe6e373b3da87bec05e3f4","types":["bar","restaurant","food","establishment"],"formatted_address":"3005 Routh St, Dallas, TX, United States","street_number":"3005","route":"Routh St","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2014-09-15T06:23:27.067-07:00","updated_at":"2014-09-15T06:23:27.067-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1625181","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.805644 32.799396)","do_not_connect_to_api":true,"merged_with_place_id":2303})
  end
elsif Place.where(id: 8116).any?
  place = Place.find_by(id: 2303)
  place ||= Place.find_by(place_id: '5f8b96d900e6754b11f8864ca0b65aa7ddbefd6f')
  if place.present?
    Place.find(8116).merge(place)
  else
    place = Place.create!({"id":2303,"name":"6th Street Bar","reference":"CnRwAAAAEeKn66m5OCQ2UcKtBZGxOG-I9b9XEHcIvgUZuw6E6-qq0LesscJj-GFv-60nruBPhxsiHa_vQB_Rv7dkgkQiWECYan2QFv_kqlxLSR45VirSHrBQlJOnqY-NBeA0XE6ZCDOmtJfO9XP2W78iBZ2TRBIQKqlmA2P614OwZ0DUUWm3OhoUNcpr0I3h7EcUiEu07z1j1YPksa8","place_id":"5f8b96d900e6754b11f8864ca0b65aa7ddbefd6f","types":["bar","establishment"],"formatted_address":"3005 Routh Street, Dallas, TX, United States","street_number":"3005 Routh Street","route":"","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2013-11-11T00:53:18.678-08:00","updated_at":"2014-02-17T20:15:02.666-08:00","administrative_level_1":"TX","administrative_level_2":"Dallas County","td_linx_code":"1625181","location_id":883,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.805512 32.799402)","do_not_connect_to_api":true,"merged_with_place_id":8116})
  end
end
puts "\n\n\n--------------------\n- Recreating Nick & Sam's: [11971]"
if Place.where(id: 3607).any?
  place = Place.find_by(id: 11971)
  place ||= Place.find_by(place_id: 'ChIJg_4v_TOZToYRiL6IItIqa1E')
  if place.present?
    Place.find(3607).merge(place)
  else
    place = Place.create!({"id":11971,"name":"Nick \u0026 Sam's","reference":"CnRuAAAA9VuUM4Iry6zFGr3KG_O3viRqSlXZMKYOzRSRTk2yN9dBDWRfaaAubKhqXF2zZxVmAON0VDZpcYsJY5TfS5U5UJWhBdnRdsd0GZlfAt1U6DjzG8swmTN3CB6LNhCVUh-XA9McCVT4W_HCdba5TSGvoRIQANm5rjfdrVB-rl7pkVskhhoUWgCGzFrvlVlLInuajOvpsKBeFfM","place_id":"ChIJg_4v_TOZToYRiL6IItIqa1E","types":["bar","restaurant","food","establishment"],"formatted_address":"3008 Maple Avenue, Dallas, TX 75201, United States","street_number":"3008","route":"Maple Avenue","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2015-02-02T20:36:38.462-08:00","updated_at":"2015-02-02T20:36:38.462-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5202545","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.80745 32.798496)","do_not_connect_to_api":true,"merged_with_place_id":3607})
  end
elsif Place.where(id: 11971).any?
  place = Place.find_by(id: 3607)
  place ||= Place.find_by(place_id: '18ee885a4b088431fc1abcdc30cb63f6205b44e4')
  if place.present?
    Place.find(11971).merge(place)
  else
    place = Place.create!({"id":3607,"name":"Nick \u0026 Sam's","reference":"CnRtAAAAZf5WdKfJ6f5sS9imBtjiYlvdqMwjyY4yfsqQKd0EnlU5gM5BWUHXcoKOzipno_Le6Fm6y8ClX8OTV9ewlfvMPxRt1_EwJtOiLi68RzlSNqfG0w1mfwBCIqOna_GK_Ogs53Ut8NixzghtJcNh4dgruRIQxip91p4ssVHYo63GZb7XYBoUvlM_Q91Im4yEDsxPNVh9QFrirUA","place_id":"18ee885a4b088431fc1abcdc30cb63f6205b44e4","types":["restaurant","food","establishment"],"formatted_address":"3008 Maple Avenue, Dallas, TX, United States","street_number":"3008","route":"Maple Avenue","zipcode":"75201","city":"Dallas","state":"Texas","country":"US","created_at":"2013-12-13T13:47:23.153-08:00","updated_at":"2014-02-17T20:22:16.561-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5202545","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.807712 32.798445)","do_not_connect_to_api":true,"merged_with_place_id":11971})
  end
end
puts "\n\n\n--------------------\n- Recreating Sapphire Pool Parties: [7364]"
if Place.where(id: 9835).any?
  place = Place.find_by(id: 7364)
  place ||= Place.find_by(place_id: '77004e2f0369bb7db069cbe55de6aab29db6e58b')
  if place.present?
    Place.find(9835).merge(place)
  else
    place = Place.create!({"id":7364,"name":"Sapphire Pool Parties","reference":"CoQBdwAAAGfe-YaqzO9Synj1ijbWNw9Q2F3rZ_3YM1JUie4jxedTAX6IA0pDsO6LpdsjbK-ok5VezkpHTmTHeK5tsCOTAmDs-3DtERdDfDzgMnYkD8BTwGWymyfWEapVJfxpFVJAb7ZMjrMeKVO5oBPDpHhLXB3uHtD9etXIBhutIir6gYUTEhDCydbH-fHfdJ_Nf-UUb70RGhQJbaTUkUOQeA6J0lmmIN96OfPRjw","place_id":"77004e2f0369bb7db069cbe55de6aab29db6e58b","types":["store","night_club","spa","establishment"],"formatted_address":"3025 S Industrial Rd, Las Vegas, NV, United States","street_number":"3025","route":"S Industrial Rd","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-07-07T10:33:37.680-07:00","updated_at":"2014-07-07T10:33:37.680-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.1715 36.134747)","do_not_connect_to_api":true,"merged_with_place_id":9835})
  end
elsif Place.where(id: 7364).any?
  place = Place.find_by(id: 9835)
  place ||= Place.find_by(place_id: 'a941d7b19928711d1c3303929449bb84dabd7059')
  if place.present?
    Place.find(7364).merge(place)
  else
    place = Place.create!({"id":9835,"name":"Sapphire Gentlemen's Club","reference":"CoQBewAAALro5qM5gGOkMlYH6dPcbBirYjfVcR-vmyHGRsrQe8PPKBB_i_oNfHNfDT-NsJGV8aj9LD-7vl6Ca7w9flWR_XJ43oUawQTu5nTHQiIfpFhDJkJG9BDaihVNwDYXvlmzY552x1uGIb1fSpp0XC7dAp63e7yG06mvanycF44HjyteEhBEC7PKKkiRozL_dcQzNroWGhQ4-HBgI5_lGGq2pxcH9TDS72g90g","place_id":"a941d7b19928711d1c3303929449bb84dabd7059","types":["establishment"],"formatted_address":"3025 S Industrial Rd #200, Las Vegas, NV 89109, United States","street_number":"3025","route":"S Industrial Rd","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-11-15T11:45:51.155-08:00","updated_at":"2014-11-15T11:45:51.155-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"5264925","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.171593 36.134752)","do_not_connect_to_api":true,"merged_with_place_id":7364})
  end
end
puts "\n\n\n--------------------\n- Recreating Sandbar Sports Grill: [12198]"
if Place.where(id: 1812).any?
  place = Place.find_by(id: 12198)
  place ||= Place.find_by(place_id: 'ChIJrbIIns-32YgRDPBCD3UxY14')
  if place.present?
    Place.find(1812).merge(place)
  else
    place = Place.create!({"id":12198,"name":"Sandbar Sports Grill","reference":"CoQBdQAAAJ8SnESnR9cgBzxOcYZaXoUbQS80jLg6n12WhoaTy8h7ZvX7S0g0ZxnZCG3B7H8rFSnj5aTLjz-71QSlHXttUT_5sR3yHbhIl98ba2E_h2aIbkXG3JFoLavw8xWXAVzEJLGdnOzMIs7oxXeeCGBAFurDR_wNnQWAmKGpHd-0sW5VEhBa5pTEPAQqwTDB73DHXqilGhTzcHJTsp3U6sHztXYD2TEYfORaBQ","place_id":"ChIJrbIIns-32YgRDPBCD3UxY14","types":["bar","establishment"],"formatted_address":"3064 Grand Avenue, Miami, FL 33133, United States","street_number":"3064","route":"Grand Avenue","zipcode":"33133","city":"Miami","state":"Florida","country":"US","created_at":"2015-02-09T09:47:25.945-08:00","updated_at":"2015-02-18T10:58:09.984-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"5189501","location_id":690,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.242984 25.727922)","do_not_connect_to_api":true,"merged_with_place_id":1812})
  end
elsif Place.where(id: 12198).any?
  place = Place.find_by(id: 1812)
  place ||= Place.find_by(place_id: '3dcbbb81f093d5d75e26a4a7ec1063b8c011b432')
  if place.present?
    Place.find(12198).merge(place)
  else
    place = Place.create!({"id":1812,"name":"Sandbar Sports Grill","reference":"CoQBdQAAAPiRig-O9aLM7jtKflBftxljO3wmCx1NlUZlsT0E76Zd6RM67zejbXWh-FIfjvE5-2hvqSiYVRUAkLTkvp5abhvMQkm19A0PzMKNSvoaDuCaCkaffo4x237_dedDhyK2aYl9w5skLT6vqenrkpcCJ4CezqtzjMyJ-3pE7loZXZHDEhDx_c53ne1DL22dKNMgZJXbGhTmd4VbxcMUpB3A-jCyp7TesJyOEA","place_id":"3dcbbb81f093d5d75e26a4a7ec1063b8c011b432","types":["bar","establishment"],"formatted_address":"3064 Grand Avenue, Miami, FL, United States","street_number":"3064","route":"Grand Avenue","zipcode":"33133","city":"Miami","state":"Florida","country":"US","created_at":"2013-11-11T00:49:15.056-08:00","updated_at":"2014-02-17T20:12:29.307-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"5189501","location_id":690,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.242994 25.72796)","do_not_connect_to_api":true,"merged_with_place_id":12198})
  end
end
puts "\n\n\n--------------------\n- Recreating Encore Beach Club: [5701]"
if Place.where(id: 7756).any?
  place = Place.find_by(id: 5701)
  place ||= Place.find_by(place_id: 'c5f5abeced741b6c670af578835e3ea251fc06c7')
  if place.present?
    Place.find(7756).merge(place)
  else
    place = Place.create!({"id":5701,"name":"Encore Beach Club","reference":"CoQBcgAAAFso-m9Jy9Z-aqwqnh-ugdTJn7PObIejIIleN7zKSzMx2PFnzmb8_1d6nw2_LA6f9nSX9r63wV-X1rNO3SW3HoGVaz7UOEwiVBTuaZxcjOvjS6fwT1sg_LtKmKgJOReq0OQfbgWjG3JUHob15lPRs9-HJ0O1UpRx_evvkQGrrcVfEhCRQKXmRcGFWGzt0N9gUD7YGhQ1b61tXpN4ZDJGFq3OwTzUzTv01w","place_id":"c5f5abeced741b6c670af578835e3ea251fc06c7","types":["night_club","establishment"],"formatted_address":"3121 S Las Vegas Blvd, Las Vegas, NV, United States","street_number":"3121","route":"S Las Vegas Blvd","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-03-29T11:11:42.620-07:00","updated_at":"2014-03-29T11:11:42.620-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"1928113","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.165843 36.12991)","do_not_connect_to_api":true,"merged_with_place_id":7756})
  end
elsif Place.where(id: 5701).any?
  place = Place.find_by(id: 7756)
  place ||= Place.find_by(place_id: '9d8d26d5f788ea87f5f29d8806aedc68d117e53b')
  if place.present?
    Place.find(5701).merge(place)
  else
    place = Place.create!({"id":7756,"name":"Encore At Wynn Las Vegas","reference":"CoQBegAAALnt4HHk0D10MOHoojbT9kdt9ULrWpFwa4ts1A95rsxxRTWti6sKMd9o--rPWR2HW1vqlHZIeblrB77MdP6Tk9wpKvRftCnKocKFyOs2TIzPEtTFsYKlPef0hc5gFRmFLHSL2_eS_NUFwVWWBFloe4sLbmsjU-VvO9cf-D63NdHGEhDYg-QilLSLjUrTvwOTagEsGhRLOjK70UK1oONLkWD6083yWTIFWA","place_id":"9d8d26d5f788ea87f5f29d8806aedc68d117e53b","types":["lodging","establishment"],"formatted_address":"3121 Las Vegas Blvd S, Las Vegas, NV, United States","street_number":nil,"route":nil,"zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-08-15T08:37:52.817-07:00","updated_at":"2014-08-15T08:37:52.817-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.164836 36.128864)","do_not_connect_to_api":true,"merged_with_place_id":5701})
  end
end
puts "\n\n\n--------------------\n- Recreating Brookland's Finest Bar and Kitchen: [12259]"
if Place.where(id: 10609).any?
  place = Place.find_by(id: 12259)
  place ||= Place.find_by(place_id: 'ChIJYw5VrfPHt4kRCvZTX1soQYk')
  if place.present?
    Place.find(10609).merge(place)
  else
    place = Place.create!({"id":12259,"name":"Brookland's Finest Bar and Kitchen","reference":"CpQBhAAAAF91IZYUN-xh1P7qGagNboZeX_oMdaRdqF4pxSCyi3DtNtPRgkDATOZQOe9-rbJzT6zp-2ky3AaoSGhYVr8yn1qX-hfwDNSI6242-KM2Dv4HR3ZdlXOsV7ZIC_sWD00z-OHw4UQgTbw4N4nLlmSx8F4mL-Dg7aAZXRrFp2ow9nnJMHu8iaD0wRZjOm37eyUCJxIQHIZC4SUxxfyNHGHkfbn7QBoU2eSprSo5btHZfErh1z2n-A9pJN0","place_id":"ChIJYw5VrfPHt4kRCvZTX1soQYk","types":["bar","restaurant","food","establishment"],"formatted_address":"3126 12th Street Northeast, Washington, DC 20017, United States","street_number":"3126","route":"12th Street Northeast","zipcode":"20017","city":"Washington","state":"District of Columbia","country":"US","created_at":"2015-02-10T18:51:41.025-08:00","updated_at":"2015-02-18T10:57:57.056-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"7330175","location_id":538,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-76.991015 38.929421)","do_not_connect_to_api":true,"merged_with_place_id":10609})
  end
elsif Place.where(id: 12259).any?
  place = Place.find_by(id: 10609)
  place ||= Place.find_by(place_id: '3f64f6cf729c96e62b8d650db4d6967db48bf107')
  if place.present?
    Place.find(12259).merge(place)
  else
    place = Place.create!({"id":10609,"name":"Brookland's Finest Bar and Kitchen","reference":"CpQBhQAAAIdzHcFoXD0DiXDFt7KOFAnJGct-riWo4wsqy7LQaHrF9ZFocemDQRLpBW7sawYfNQLd7rqQNyUwl0VDR1IPPB5W9BMTvMaw5-JD6ata_5iPBvPVB26yTCLji9z7lg6FRScBaMw6deq4hdKepaW1FxJFKX3XX1gh3ACvniggO2nptAHjUwrroHGhpQKAhW-tkRIQccxCdOqhdaWzPvvSUFibJBoUMCPkbnfLVI5xIg7dNOad5OwFRtA","place_id":"3f64f6cf729c96e62b8d650db4d6967db48bf107","types":["bar","restaurant","food","establishment"],"formatted_address":"3126 12th St NE, Washington, DC 20017, United States","street_number":"3126","route":"12th St NE","zipcode":"20017","city":"Washington","state":"District of Columbia","country":"US","created_at":"2014-12-04T16:43:34.063-08:00","updated_at":"2014-12-04T16:43:34.063-08:00","administrative_level_1":"DC","administrative_level_2":nil,"td_linx_code":"7330175","location_id":172909,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-76.991015 38.929421)","do_not_connect_to_api":true,"merged_with_place_id":12259})
  end
end
puts "\n\n\n--------------------\n- Recreating Kramer's: [12247]"
if Place.where(id: 9136).any?
  place = Place.find_by(id: 12247)
  place ||= Place.find_by(place_id: 'ChIJPQYgdowF9YgRENfKmZWBiNs')
  if place.present?
    Place.find(9136).merge(place)
  else
    place = Place.create!({"id":12247,"name":"Kramer's","reference":"CnRqAAAAWHTLSQi65x0v3MMxjiixZTF2-tsNioMwcATtbnrtRThJoNEDhDFW_7G2HHsZx8_s_lj0mxroyDdhHB4pHFNQcnJyJuXtnaZO46mVWFJkTi_IKX76h0jsVGVmon7KkY7BKNoSBQi5dx1EaY1pbg7oMBIQqIiKPT1C9prSZB6ugYY5LBoUSA3oj-fk8uQH8jKRbqSlpWUJ4t0","place_id":"ChIJPQYgdowF9YgRENfKmZWBiNs","types":["bar","establishment"],"formatted_address":"3167 Roswell Road, Atlanta, GA 30305, United States","street_number":"3167","route":"Roswell Road","zipcode":"30305","city":"Atlanta","state":"Georgia","country":"US","created_at":"2015-02-10T09:36:01.803-08:00","updated_at":"2015-02-18T10:57:58.831-08:00","administrative_level_1":"GA","administrative_level_2":nil,"td_linx_code":nil,"location_id":466,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-84.378594 33.841566)","do_not_connect_to_api":true,"merged_with_place_id":9136})
  end
elsif Place.where(id: 12247).any?
  place = Place.find_by(id: 9136)
  place ||= Place.find_by(place_id: '37938bc830ed53c2b117173b38a81e287c8fde66')
  if place.present?
    Place.find(12247).merge(place)
  else
    place = Place.create!({"id":9136,"name":"Kramer's","reference":"CnRrAAAADk9YgdNNa9iBfPcIxbpCXmZFjp3Z-DzKzGB-n4REHxihW4j0_NiCMnlb1LDhNoZRhUTI9wlqu6NOxbIyJts9ejOs4-aII9CsBIIoU8lF0Mj5yDSpuN9j8mDv4uj-GIjGxtqlXHOWlKkkdqo7owlqxxIQPUCTt14OipK0Pf6MUg4I_hoUTGe_77hwad85sLqSlX0LBgg6ZJA","place_id":"37938bc830ed53c2b117173b38a81e287c8fde66","types":["bar","establishment"],"formatted_address":"3167 Roswell Rd, Atlanta, GA 30305, United States","street_number":"3167","route":"Roswell Rd","zipcode":"30305","city":"Atlanta","state":"Georgia","country":"US","created_at":"2014-10-23T06:56:48.732-07:00","updated_at":"2014-10-23T06:56:48.732-07:00","administrative_level_1":"GA","administrative_level_2":"Fulton County","td_linx_code":nil,"location_id":97228,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-84.378594 33.841566)","do_not_connect_to_api":true,"merged_with_place_id":12247})
  end
end
puts "\n\n\n--------------------\n- Recreating BARÚ Urbano: [12206]"
if Place.where(id: 4342).any?
  place = Place.find_by(id: 12206)
  place ||= Place.find_by(place_id: 'ChIJZztIhlOx2YgR-Ds0CYHPwnc')
  if place.present?
    Place.find(4342).merge(place)
  else
    place = Place.create!({"id":12206,"name":"BARÚ Urbano","reference":"CnRtAAAACfOi8lhkbJ-oSWMS0OmCd_sxBkfZLCB5zSkrjLo_sqDIfUFcancaCuWwRDWYXVeBwS87mYTpTkS9mkVDvIS3S4O-maLgMqAote_oB2QNQBF-m9fGm8ishJWeCMEq-ijt9uUmkuwAekkkFVcZaRWiMBIQBAwwsjD88B0NLSofnDYr9xoU8CXi3mcmaLyXZbFLYH0JDEvfwTg","place_id":"ChIJZztIhlOx2YgR-Ds0CYHPwnc","types":["bar","restaurant","food","establishment"],"formatted_address":"3252 Northeast 1st Avenue, Miami, FL 33137, United States","street_number":"3252","route":"Northeast 1st Avenue","zipcode":"33137","city":"Miami","state":"Florida","country":"US","created_at":"2015-02-09T10:46:34.618-08:00","updated_at":"2015-02-18T10:58:08.664-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":nil,"location_id":690,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.193708 25.806918)","do_not_connect_to_api":true,"merged_with_place_id":4342})
  end
elsif Place.where(id: 12206).any?
  place = Place.find_by(id: 4342)
  place ||= Place.find_by(place_id: 'e86cdac90d4a38d378cb1bd0fd2853f4771890fd')
  if place.present?
    Place.find(12206).merge(place)
  else
    place = Place.create!({"id":4342,"name":"BARÚ Urbano Midtown","reference":"CoQBdQAAALbszJcin5OVQh08Qu0vhLoGs6gwpfhswhWetAu2j38QsX1vGTL_XwZ8hxRJAGENwnPNLGd6qCQbkz6zVPJj8D1YZtfxxKSyOSj19b-LujBjSOqGCctEd-jGwYP-ZmppAppKKf2gMtZAWnbn3aGEH1xyaYLSJiBScyqw53PeuZQpEhAQjjNkrtozlTMsUc3vcfwbGhSFJmljS1Dv6VHOWJ61R51VjLnzjw","place_id":"e86cdac90d4a38d378cb1bd0fd2853f4771890fd","types":["bar","restaurant","food","establishment"],"formatted_address":"3252 NE 1st Ave #124, Miami, FL, United States","street_number":"3252","route":"NE 1st Ave","zipcode":"33137","city":"Miami","state":"Florida","country":"US","created_at":"2014-01-29T12:57:06.357-08:00","updated_at":"2014-02-17T20:26:39.942-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"7229438","location_id":690,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.193297 25.807487)","do_not_connect_to_api":true,"merged_with_place_id":12206})
  end
end
puts "\n\n\n--------------------\n- Recreating Remedy's Tavern: [6204]"
if Place.where(id: 5115).any?
  place = Place.find_by(id: 6204)
  place ||= Place.find_by(place_id: 'faa6b035ae240e209f4a9ac29b404dd56bcc1217')
  if place.present?
    Place.find(5115).merge(place)
  else
    place = Place.create!({"id":6204,"name":"Remedy's Tavern","reference":"CnRwAAAAUM-8nFI5UOQlubLF-nEwDcgYztXF7zskUpWR1bFLXM-5Xl_ZiQHABp9DHVZ_W-4BgctKnfL2tVzYY2UYiWvFLrv9ERmCf9YktMYC-O4cZg--9u2FKKzHNdMEM9Iyw0yzBOY_GHPHNdzwPj-UAPVeiBIQNBIyeR8RIwpNpXKPtjY15xoUW2eSIEAT9er-pQS4TvQDm13A3F0","place_id":"faa6b035ae240e209f4a9ac29b404dd56bcc1217","types":["bar","restaurant","food","establishment"],"formatted_address":"3265 St Rose Pkwy, Henderson, NV, United States","street_number":"3265","route":"St Rose Pkwy","zipcode":"89052","city":"Henderson","state":"Nevada","country":"US","created_at":"2014-04-24T14:14:01.104-07:00","updated_at":"2014-04-24T14:14:01.104-07:00","administrative_level_1":"NV","administrative_level_2":"Clark County","td_linx_code":"2194905","location_id":1651,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.126376 35.997821)","do_not_connect_to_api":true,"merged_with_place_id":5115})
  end
elsif Place.where(id: 6204).any?
  place = Place.find_by(id: 5115)
  place ||= Place.find_by(place_id: 'd73148e7d4d83be22edea0f30ced008cbced8254')
  if place.present?
    Place.find(6204).merge(place)
  else
    place = Place.create!({"id":5115,"name":"Remedy's Tavern","reference":"CoQBcQAAAI91rj8k_INw-SoDS8eYRRko0nzQOxyXnYZAtkbICSz_CNtKpRQL2HZSZ3hSD8pLTX8P8QslejDEFkffZCaqCK3qzDvvxiOXMrB0uF96CC5cK4TQJad0wuGOZiL1feReTMEVa50driYUWi21l4sDR67GmRyOx4nOC-V7sFZyoojcEhDcWFv0tH9UAICeVETjKvVGGhQVcDwIh-EfDYEdU4-6RMcpyzGEvQ","place_id":"d73148e7d4d83be22edea0f30ced008cbced8254","types":["bar","restaurant","food","establishment"],"formatted_address":"3265 St Rose Parkway Trail, Henderson, NV, United States","street_number":"3265","route":"St Rose Parkway Trail","zipcode":"89052","city":"Henderson","state":"Nevada","country":"US","created_at":"2014-03-10T12:47:55.707-07:00","updated_at":"2014-03-10T12:47:55.707-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":671,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.126372 35.997646)","do_not_connect_to_api":true,"merged_with_place_id":6204})
  end
end
puts "\n\n\n--------------------\n- Recreating So & So's: [11847]"
if Place.where(id: 7417).any?
  place = Place.find_by(id: 11847)
  place ||= Place.find_by(place_id: 'ChIJQVYBNNOeToYR8HX6SZa-ApE')
  if place.present?
    Place.find(7417).merge(place)
  else
    place = Place.create!({"id":11847,"name":"So \u0026 So's","reference":"CnRsAAAA0oG1wjHRzBc7EQRmb-8_hys20qejD2TsYgZ-zWPE-zU1oGjqm-cLn6qp2pl2Dwhshs6sIV47W0aQjepwL_sZumDGZeCoSvTGu5R0Ppxcyfc1zwzo16crBFnkAzdDDElZzvz7EiqBQEiAqzfFuwxaXxIQoj7h0A2R-lpn_1JBDX0THBoU4qJLkoRcdIYzR-FQMSI7YKsYl3w","place_id":"ChIJQVYBNNOeToYR8HX6SZa-ApE","types":["bar","restaurant","food","establishment"],"formatted_address":"3309 McKinney Avenue, Dallas, TX 75204, United States","street_number":"3309","route":"McKinney Avenue","zipcode":"75204","city":"Dallas","state":"Texas","country":"US","created_at":"2015-01-30T14:42:09.998-08:00","updated_at":"2015-01-30T14:42:09.998-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5597996","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.799303 32.804824)","do_not_connect_to_api":true,"merged_with_place_id":7417})
  end
elsif Place.where(id: 11847).any?
  place = Place.find_by(id: 7417)
  place ||= Place.find_by(place_id: '4e45e91268b87677a84fad5ba43af86285dedd46')
  if place.present?
    Place.find(11847).merge(place)
  else
    place = Place.create!({"id":7417,"name":"So \u0026 So's","reference":"CnRrAAAAmy3bXdMrsq9PPZB0mK6T14AdF_Hg5ZyiSsJDJeadsg1ABxNYWgkb2nNy4MOrb93ttbm8iEZSE_Eqjbq22G7yDq5VId--NoBImAUvqRNkUU_Hpp6z8YaDk-Q9RN2cSOFuQN0ZlYW405q0i1n0UZHOQxIQ3NT3yOZEQxElbTgXVWfiFRoUd8imK986Uau4i_1LvFKBISyKxF4","place_id":"4e45e91268b87677a84fad5ba43af86285dedd46","types":["restaurant","food","establishment"],"formatted_address":"3309 McKinney Ave, Dallas, TX, United States","street_number":"3309","route":"McKinney Ave","zipcode":"75204","city":"Dallas","state":"Texas","country":"US","created_at":"2014-07-12T16:16:11.418-07:00","updated_at":"2014-07-12T16:16:11.418-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5597996","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.799296 32.804814)","do_not_connect_to_api":true,"merged_with_place_id":11847})
  end
end
puts "\n\n\n--------------------\n- Recreating B&B Ristorante: [9766]"
if Place.where(id: 3982).any?
  place = Place.find_by(id: 9766)
  place ||= Place.find_by(place_id: 'a50642f7287cf1ba1e675491ed8718ae97f2d185')
  if place.present?
    Place.find(3982).merge(place)
  else
    place = Place.create!({"id":9766,"name":"B\u0026B Ristorante","reference":"CoQBeQAAAOa5F-POwuRG_n1JJ_T7PuDUZYEX1nuMhNPTcRZ-7x5zjRp6V9F2ZzGcsoMmXQc1_X1PhQ7DTMnAqPWqTX20sU_zxWQ5jM-QHDnwVgMYAD2oXU5H-BDsD9rJB4lxxWglbTEtgceh_SQN0Ir0CxG_QW8oz5VSZTtme8sj2UXKDDbJEhBDHcsM9jLTWlcxxwobE84hGhRndEtLjkUxh_No22KdlF-8QwkRSA","place_id":"a50642f7287cf1ba1e675491ed8718ae97f2d185","types":["restaurant","food","point_of_interest","establishment"],"formatted_address":"B\u0026B Ristorante, 3355 S Las Vegas Blvd, Las Vegas, NV 89109, USA","street_number":"3355","route":"S Las Vegas Blvd","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-11-12T11:18:53.170-08:00","updated_at":"2014-11-12T11:18:53.170-08:00","administrative_level_1":"NV","administrative_level_2":"Clark County","td_linx_code":"5265180","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.168717 36.1229979)","do_not_connect_to_api":true,"merged_with_place_id":3982})
  end
elsif Place.where(id: 9766).any?
  place = Place.find_by(id: 3982)
  place ||= Place.find_by(place_id: '10b73a46fae94d1de39aaf5a2fe2395e4d23b570')
  if place.present?
    Place.find(9766).merge(place)
  else
    place = Place.create!({"id":3982,"name":"B\u0026B Ristorante","reference":"CnRwAAAA0nK8P-SsWD6cFG8e68psGnQkqIrWTJ6b1gDLRgsz4FGcdXoN4xu0mtXXUgEiUymwT11YOldPF40510x_kuQBtoSnCZ-QcQ85FLH-NZ8AWX-i9xQqoLjpb6nxMkB1i3S96k0FcfvnYEGC5mNkNJHUBBIQWR0DSqHDnzpKTUmApDSf_RoUdZ_uGtWyuh4OZiy3M-HDlBvT-6Q","place_id":"10b73a46fae94d1de39aaf5a2fe2395e4d23b570","types":["restaurant","food","establishment"],"formatted_address":"3355 South Las Vegas Boulevard, Las Vegas, NV, United States","street_number":"3355","route":"South Las Vegas Boulevard","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-01-10T17:53:40.594-08:00","updated_at":"2014-02-17T20:24:36.999-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"5265180","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.168717 36.122998)","do_not_connect_to_api":true,"merged_with_place_id":9766})
  end
end
puts "\n\n\n--------------------\n- Recreating Pat's Tap: [12171]"
if Place.where(id: 9906).any?
  place = Place.find_by(id: 12171)
  place ||= Place.find_by(place_id: 'ChIJqYmRqewn9ocRxCZompgPsCs')
  if place.present?
    Place.find(9906).merge(place)
  else
    place = Place.create!({"id":12171,"name":"Pat's Tap","reference":"CnRrAAAAHwmb-hKMx2zY1I71GFtsu2gurqkuW6kqJSLMoN7lxYis_WKBC05pKpNf0fqMqYG_LG9eIF5FvoEIisRhRIctQr5RT0GSSv1ICjzDL61kSlHOG9DEmT1lRf7G9tvDdNTXmU85zx9FpFYjNG4ZpSgCShIQjM0JQsVXSzfp_TkV3tB3-xoUSkXBTOdfKdD95gkuJlTT3oi32tU","place_id":"ChIJqYmRqewn9ocRxCZompgPsCs","types":["bar","restaurant","food","establishment"],"formatted_address":"3510 Nicollet Avenue South, Minneapolis, MN 55408, United States","street_number":"3510","route":"Nicollet Avenue South","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2015-02-08T16:46:15.896-08:00","updated_at":"2015-02-18T11:01:16.238-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"1851198","location_id":12,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.278252 44.939226)","do_not_connect_to_api":true,"merged_with_place_id":9906})
  end
elsif Place.where(id: 12171).any?
  place = Place.find_by(id: 9906)
  place ||= Place.find_by(place_id: 'e07a4ea00ca1862118d0460150630941617711ac')
  if place.present?
    Place.find(12171).merge(place)
  else
    place = Place.create!({"id":9906,"name":"Pat's Tap","reference":"CnRqAAAAheC6dwCCMlsI3bcD_oUrSajf-km7IOP2ZU3YASn-kyuTSW9qL-fqoRi1Y9ya247wgCF65AC5-GlhpklMY2hvcNUD5gyMxvS_NHxyqEM1Dtf66EicXF8R8eCaIaGPImTT7iPpy2yD6cPG0jF-UKmjKhIQEzuSj_x8SUrM3Pz2V7aLFxoUMEYdEoT9G3RM0ZUGFcQGGs-pmwA","place_id":"e07a4ea00ca1862118d0460150630941617711ac","types":["bar","restaurant","food","establishment"],"formatted_address":"3510 Nicollet Ave, Minneapolis, MN 55408, United States","street_number":"3510","route":"Nicollet Ave","zipcode":"55408","city":"Minneapolis","state":"Minnesota","country":"US","created_at":"2014-11-17T13:05:34.735-08:00","updated_at":"2015-02-23T14:22:06.693-08:00","administrative_level_1":"MN","administrative_level_2":nil,"td_linx_code":"1851198","location_id":12,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-93.278252 44.939226)","do_not_connect_to_api":true,"merged_with_place_id":12171})
  end
end
puts "\n\n\n--------------------\n- Recreating Herbs and Rye INCORRECT: [12104]"
if Place.where(id: 4268).any?
  place = Place.find_by(id: 12104)
  place ||= Place.find_by(place_id: 'ChIJNcVs1VXByIARaX7ykQPgpuQ')
  if place.present?
    Place.find(4268).merge(place)
  else
    place = Place.create!({"id":12104,"name":"Herbs and Rye INCORRECT","reference":"CnRvAAAAH4C-OuM5ViJ6nkCN_ipCGozhwEgl13vOMgFlKcyGmdXa0iHG_gIknQBNxMCjB6IuuyIEOPY9qrDPGto__8CbJfmcVQku1FnD8WD_WwkwFzn6fUPQc5tL_1PsNTdcp7hqmylXNG5mLEzXLVbiZ7iqoBIQxRq8VcCUE3MWxp_vcdBDwBoUw0pZrLQQzMEelz3xKWjLWTl2tP4","place_id":"ChIJNcVs1VXByIARaX7ykQPgpuQ","types":["bar","restaurant","food","establishment"],"formatted_address":"3713 West Sahara Avenue, Las Vegas, NV 89102, United States","street_number":"3713","route":"West Sahara Avenue","zipcode":"89102","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-02-06T03:24:36.082-08:00","updated_at":"2015-02-27T11:28:01.781-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"5227617","location_id":672,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.191692 36.143975)","do_not_connect_to_api":true,"merged_with_place_id":4268})
  end
elsif Place.where(id: 12104).any?
  place = Place.find_by(id: 4268)
  place ||= Place.find_by(place_id: '8c1fe827c1b8787d2da7b6aac6ae5e43a8984336')
  if place.present?
    Place.find(12104).merge(place)
  else
    place = Place.create!({"id":4268,"name":"Herbs and Rye ","reference":"CnRwAAAAyh9EFNEpfakdULHuu98LoS4dSVqRqTND8CWCsCQpT-7xcaM9-_4lULtUdhVjYRHEvX3VkWjUIVTSkNGud09JykKAV5u8acKUa0Cvz2_zENQdNesLs7ldPWghkSDNjKTX1DVP4birvnNMRetOXq-ATRIQr0m8uVreu8xN7qX5CWSNZRoUC7HEUl_RKll3o3cmN9uuynvspm8","place_id":"8c1fe827c1b8787d2da7b6aac6ae5e43a8984336","types":["bar","restaurant","food","establishment"],"formatted_address":"3713 West Sahara Avenue, Las Vegas, NV 89102","street_number":"3713","route":"W Sahara Ave","zipcode":"89102","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-01-28T12:31:58.071-08:00","updated_at":"2015-02-27T11:27:49.716-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"5227617","location_id":672,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.191761 36.144252)","do_not_connect_to_api":true,"merged_with_place_id":12104})
  end
end
puts "\n\n\n--------------------\n- Recreating ARIA Resort & Casino Las Vegas: [12289]"
if Place.where(id: 7973).any?
  place = Place.find_by(id: 12289)
  place ||= Place.find_by(place_id: 'ChIJhWQVHS7EyIARbwWzRC-I8y4')
  if place.present?
    Place.find(7973).merge(place)
  else
    place = Place.create!({"id":12289,"name":"ARIA Resort \u0026 Casino Las Vegas","reference":"CoQBgAAAAB7JSpAkgaB8K7xkLt3kAdo4Ta-qNmtrLbWFq8s2WYr3LaK4EPtRE9A047pEN3Oyajvy-JsDrT0OtQJ-5AP09qFZgtY00J63tRTbBgmRDGrlVUbsuTQ6TUzcuIzYkIaMD-ZwPH2ghT-K1cBbuFtSHBix4ZZoTrkNrVc9byAaZTsQEhCUWqwGNGNr3lu38qfsDeB_GhQ_u38ewI5hxsirYmlchc7tZtoBKg","place_id":"ChIJhWQVHS7EyIARbwWzRC-I8y4","types":["lodging","casino","spa","health","establishment"],"formatted_address":"3730 South Las Vegas Boulevard, Las Vegas, NV 89109, United States","street_number":"3730","route":"South Las Vegas Boulevard","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-02-12T00:49:12.804-08:00","updated_at":"2015-02-18T10:57:50.908-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":3,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.177707 36.107048)","do_not_connect_to_api":true,"merged_with_place_id":7973})
  end
elsif Place.where(id: 12289).any?
  place = Place.find_by(id: 7973)
  place ||= Place.find_by(place_id: '0bc91d8e96bb85559848a7c53ca7474d26424cf6')
  if place.present?
    Place.find(12289).merge(place)
  else
    place = Place.create!({"id":7973,"name":"ARIA Resort \u0026 Casino Las Vegas","reference":"CoQBgAAAAJA6v46pXcUBnuXp_pa4zBl2T6M0LKa1bQtL-hGQb6qVhz5iqCo4lIfDJp9t46J7QItXdk6sAWuVzZqNweQ-_o3_SP7O5_8kzctJn8SIEFeypMLffqDVsEfkFF4IoPSrmfc6_71sXR9BK9_oi4VVtz2UM4ThnhfMRgSUNf4-IE2vEhBkzMmfTeJCrmqIKNxUcQo8GhRhWu88U-xsYJapkZOKa5r2hTvZAw","place_id":"0bc91d8e96bb85559848a7c53ca7474d26424cf6","types":["lodging","spa","health","establishment"],"formatted_address":"3730 S Las Vegas Blvd, Las Vegas, NV, United States","street_number":"3730","route":"S Las Vegas Blvd","zipcode":"89109","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-09-05T10:55:46.859-07:00","updated_at":"2014-09-05T10:55:46.859-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"3682771","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.176989 36.1074)","do_not_connect_to_api":true,"merged_with_place_id":12289})
  end
end
puts "\n\n\n--------------------\n- Recreating RnR Restaurant and Bar: [11831]"
if Place.where(id: 2846).any?
  place = Place.find_by(id: 11831)
  place ||= Place.find_by(place_id: 'ChIJ94G6ZsALK4cRTStbk_peg7g')
  if place.present?
    Place.find(2846).merge(place)
  else
    place = Place.create!({"id":11831,"name":"RnR Restaurant and Bar","reference":"CoQBeAAAAISlTNT9r8DZltLCTWZyp3HsXjQ36DUDnv4mxUFRafZgAauLiZWcvyzS2e0c-_VhYUNW6kVM-kKXlH4ZLv422kkqoCqpSSY8WlJd_XZiAF44I4k4Zcg2OyWomlrfs5fiDszQKFrIAjKhm2yOT7NB60jdTA7IxD6dBSOU1BUCKsC7EhDWotwbkCGLc_yZ_VSJ0bobGhQBv2NjV3mYPvwIkJ_pALE7weHzLw","place_id":"ChIJ94G6ZsALK4cRTStbk_peg7g","types":["bar","restaurant","food","establishment"],"formatted_address":"3737 North Scottsdale Road, Scottsdale, AZ 85251, United States","street_number":"3737","route":"North Scottsdale Road","zipcode":"85251","city":"Scottsdale","state":"Arizona","country":"US","created_at":"2015-01-30T09:33:54.406-08:00","updated_at":"2015-01-30T09:33:54.406-08:00","administrative_level_1":"AZ","administrative_level_2":nil,"td_linx_code":"0573023","location_id":733,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-111.925928 33.491632)","do_not_connect_to_api":true,"merged_with_place_id":2846})
  end
elsif Place.where(id: 11831).any?
  place = Place.find_by(id: 2846)
  place ||= Place.find_by(place_id: 'a879818951702e357b8ea637dd58e0d97f087298')
  if place.present?
    Place.find(11831).merge(place)
  else
    place = Place.create!({"id":2846,"name":"RnR Restaurant and Bar","reference":"CoQBeQAAAF5urh6Tyub6GJv4dA7sk5gsXSZeImikGgmAtKYA--yd602FeJGbKLKbfcLToXk2SWWMOBDNgr-yJ3lgPoaD6bHxcABXRyrHwpbqahS2tQOH0hps_bgQ6IggDTsa8IgoCQnak5Z567LFzJoyVWK2zwwhvkNmqzojPzhSQPzBNAhFEhBzQU_2e3QFnR4fG4ElJXjkGhTSDyjzyq6s4TbuDkm8Vg_42s7-_w","place_id":"a879818951702e357b8ea637dd58e0d97f087298","types":["bar","restaurant","food","establishment"],"formatted_address":"3737 North Scottsdale Road, Scottsdale, AZ, United States","street_number":"3737","route":"North Scottsdale Road","zipcode":"85251","city":"Scottsdale","state":"Arizona","country":"US","created_at":"2013-11-12T16:24:56.808-08:00","updated_at":"2014-02-17T20:17:52.705-08:00","administrative_level_1":"AZ","administrative_level_2":nil,"td_linx_code":"0573023","location_id":733,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-111.925928 33.491632)","do_not_connect_to_api":true,"merged_with_place_id":11831})
  end
end
puts "\n\n\n--------------------\n- Recreating Mandarin Bar (inside Mandarin Oriental): [12283]"
if Place.where(id: 3407).any?
  place = Place.find_by(id: 12283)
  place ||= Place.find_by(place_id: 'ChIJXQm6NTLEyIARpe4Vbm3TPtc')
  if place.present?
    Place.find(3407).merge(place)
  else
    place = Place.create!({"id":12283,"name":"Mandarin Bar (inside Mandarin Oriental)","reference":"CpQBigAAAB8WJKWFq0NJuA5Ntt2u_qVrS5hE7J7Hg6f36uAmZOKyBiovjN3upiD9G71bQ_mNMJgpzwp-BFNXiRZj7RM66hXgi68TYEfO_xxZl07HDGlaZT8MxAr_-gOxI_ytUowrzaOZdMc9034T4ZcP4zCZT2CwToyi3ZRiMPkAbnIcuH8dmc-viTfrRjnoh6HUyhw0chIQQPizdcZjrO32DNZYNLVS7RoUjW5HxdeSHP4BulrffknUMiTQnKg","place_id":"ChIJXQm6NTLEyIARpe4Vbm3TPtc","types":["bar","establishment"],"formatted_address":"3752 South Las Vegas Boulevard, Las Vegas, NV 89158, United States","street_number":"3752","route":"South Las Vegas Boulevard","zipcode":"89158","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-02-12T00:22:17.376-08:00","updated_at":"2015-02-18T10:57:52.172-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":4,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.174313 36.106008)","do_not_connect_to_api":true,"merged_with_place_id":3407})
  end
elsif Place.where(id: 12283).any?
  place = Place.find_by(id: 3407)
  place ||= Place.find_by(place_id: 'b9c90b12d3ec5eed72813e67acb3d990fe57fd19')
  if place.present?
    Place.find(12283).merge(place)
  else
    place = Place.create!({"id":3407,"name":"Mandarin Oriental, Las Vegas","reference":"CoQBfQAAAM5nIcve6tvK0_mQZHYavH6RCSYrQj5018Csfkvo24kgl1AHkBYHfEoxKCCP9nxYS1ATEq38gHQsUjG6dhy6hT9GkhrOdE5_sf-_YV08Z2NZnM45bYmhihigz53NeMvSa8wHA_dvLpqEWSj7jHrNAfCsBW8a_7joKsyxbbZ8NECBEhAEvY8tJqfLGOojva2F7JdaGhQlCNsw0BgB37jbguJIBXYP66J6Nw","place_id":"b9c90b12d3ec5eed72813e67acb3d990fe57fd19","types":["lodging","spa","establishment"],"formatted_address":"3752 S Las Vegas Blvd, Las Vegas, NV, United States","street_number":"3752","route":"S Las Vegas Blvd","zipcode":"89158","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2013-12-07T10:33:27.739-08:00","updated_at":"2014-02-17T20:21:09.088-08:00","administrative_level_1":"NV","administrative_level_2":"Clark","td_linx_code":"3673844","location_id":824,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.174213 36.106212)","do_not_connect_to_api":true,"merged_with_place_id":12283})
  end
end
puts "\n\n\n--------------------\n- Recreating Ireland's 32: [12235]"
if Place.where(id: 339).any?
  place = Place.find_by(id: 12235)
  place ||= Place.find_by(place_id: 'ChIJMTazDzmHhYARC1oskRCDPVM')
  if place.present?
    Place.find(339).merge(place)
  else
    place = Place.create!({"id":12235,"name":"Ireland's 32","reference":"CnRtAAAAwkLbLYKmDmEuOzvMihveFSynAW35J-dawlk-52ofV8ZwN8zZq5ZhPT4SYfNOc8QEhRu6VgSHVxSrlF6IVhGwCKpfIWUONODdsJANC4fx1pn6UuPWgmHUFk1K65vCNd06cCqQCxXN7OWdGI2xn52zfxIQNmJgpEWOi8YVJPWEzyJO_BoUr8f054613PB9DVuT4xjfzgWf6jk","place_id":"ChIJMTazDzmHhYARC1oskRCDPVM","types":["bar","restaurant","food","establishment"],"formatted_address":"3920 Geary Boulevard, San Francisco, CA 94118, United States","street_number":"3920","route":"Geary Boulevard","zipcode":"94118","city":"San Francisco","state":"California","country":"US","created_at":"2015-02-09T16:33:27.602-08:00","updated_at":"2015-02-18T10:58:01.444-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5237490","location_id":35,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.461447 37.781388)","do_not_connect_to_api":true,"merged_with_place_id":339})
  end
elsif Place.where(id: 12235).any?
  place = Place.find_by(id: 339)
  place ||= Place.find_by(place_id: '556793bacc0f5d581607ecc25d958b5418791579')
  if place.present?
    Place.find(12235).merge(place)
  else
    place = Place.create!({"id":339,"name":"Ireland's 32","reference":"CnRqAAAACul-x6q-_LYT6OA9lLjxxw2lj-g0nnS0scjzI3aMtLA2qUyQDRpZSOLt_vs_oYNEzT6cFu1scM4BaojxniLjoNfUZ_4gXTgbT8shvsGLv67E9RyH44JkQwBXJ4NLmW9R2uCn58befx2lRs4JZOCFTRIQu94VylnbYusjmQEwBPcrZRoURgC6hRmWCaokyDzM5GOsZkbeZP4","place_id":"556793bacc0f5d581607ecc25d958b5418791579","types":["bar","restaurant","food","establishment"],"formatted_address":"3920 Geary Boulevard, San Francisco, CA, United States","street_number":"3920","route":"Geary Boulevard","zipcode":"94118","city":"San Francisco","state":"California","country":"US","created_at":"2013-10-11T13:35:41.599-07:00","updated_at":"2014-02-17T20:05:08.821-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5237490","location_id":35,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.461466 37.781326)","do_not_connect_to_api":true,"merged_with_place_id":12235})
  end
end
puts "\n\n\n--------------------\n- Recreating Delano Las Vegas: [11934]"
if Place.where(id: 10040).any?
  place = Place.find_by(id: 11934)
  place ||= Place.find_by(place_id: 'ChIJ18Y7ZM_FyIARVLjHndpGo_Y')
  if place.present?
    Place.find(10040).merge(place)
  else
    place = Place.create!({"id":11934,"name":"Delano Las Vegas","reference":"CoQBcwAAAByXg0CCUzLcy_OKNN_HHRDOWQn-TUcjbEWq9IQGzM6aIvysEdDrSdJgucSnRNyCZH7uVk143W5Tm9Qedap4PIE668BBCfoMIW1snj3tmjG3wD0lMiQJxKjyGC83iJsCfXJfi2Nq0P_hW-sNdZWzHAP-URCiABuifb6Uw-QI-17UEhCn3xGmjKnXlF9vETbHq2X_GhTsWyJoJt9A_OomqYMiHkWjUwWe2w","place_id":"ChIJ18Y7ZM_FyIARVLjHndpGo_Y","types":["lodging","establishment"],"formatted_address":"3940 South Las Vegas Blvd, Las Vegas, NV 89119, United States","street_number":"3940","route":"South Las Vegas Blvd","zipcode":"89119","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-02-02T09:09:51.752-08:00","updated_at":"2015-02-02T09:09:51.752-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.176813 36.090124)","do_not_connect_to_api":true,"merged_with_place_id":10040})
  end
elsif Place.where(id: 11934).any?
  place = Place.find_by(id: 10040)
  place ||= Place.find_by(place_id: 'a8fc051a6b22e18806f26d1bc770667ca87d336b')
  if place.present?
    Place.find(11934).merge(place)
  else
    place = Place.create!({"id":10040,"name":"Delano Las Vegas","reference":"CoQBcwAAAHUFxBBen7dIuAjxNPUN_l9iWtvjbFfJ2ZBJ5fceUlHphGhbKY_JkYA75fCZqOXlPlifRL29ejSEbWsZQyKX8v8vTRQEVdtBT69NqZu9u_ZAIhduYi2I538Oz2QXZL_o75Z98gFJtOuG27kGdvTFIVOrZJckmgIagvq38Xt-95B5EhCMK15lbAy2YXJx1Y3TEVFAGhTWWLEanWwr7GVWH9urm9AQw3MaOA","place_id":"a8fc051a6b22e18806f26d1bc770667ca87d336b","types":["lodging","establishment"],"formatted_address":"3940 S Las Vegas Blvd, Las Vegas, NV 89119, United States","street_number":"3940","route":"S Las Vegas Blvd","zipcode":"89119","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-11-23T12:41:58.834-08:00","updated_at":"2014-11-23T12:41:58.834-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.175182 36.091858)","do_not_connect_to_api":true,"merged_with_place_id":11934})
  end
end
puts "\n\n\n--------------------\n- Recreating Interurban: [12362]"
if Place.where(id: 3200).any?
  place = Place.find_by(id: 12362)
  place ||= Place.find_by(place_id: 'ChIJBSVTC2unlVQRqtsxJLQjX5I')
  if place.present?
    Place.find(3200).merge(place)
  else
    place = Place.create!({"id":12362,"name":"Interurban","reference":"CmReAAAAt9761oCcLtDjVKHHRtvTpM2U9E_HkwvbTXVwy9pfW_0oHFTm8c6tvv3woHQKYSIJI5ecmDMpw0gv6jckUPG5OHCcofgB4U_6WB7gPH3ZH5tXZK4ViHr7SEJmj9zSjGyeEhBPIljed39kSHPS1_x3yYKHGhTsn9CPGjfmrfJ7m0IG2dG-A34Wdg","place_id":"ChIJBSVTC2unlVQRqtsxJLQjX5I","types":["bar","restaurant","food","establishment"],"formatted_address":"4057 North Mississippi Avenue, Portland, OR 97227, United States","street_number":"4057","route":"North Mississippi Avenue","zipcode":"97227","city":"Portland","state":"Oregon","country":"US","created_at":"2015-02-16T11:42:10.414-08:00","updated_at":"2015-02-18T10:54:49.650-08:00","administrative_level_1":"OR","administrative_level_2":nil,"td_linx_code":nil,"location_id":738,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.675647 45.552972)","do_not_connect_to_api":true,"merged_with_place_id":3200})
  end
elsif Place.where(id: 12362).any?
  place = Place.find_by(id: 3200)
  place ||= Place.find_by(place_id: '07eac34486a0082252e61bc2919b7cfcbf4caef6')
  if place.present?
    Place.find(12362).merge(place)
  else
    place = Place.create!({"id":3200,"name":"Interurban","reference":"CnRsAAAAi0mm-x7LP9zYf6J-4srYagIdxhSGN8xpGMnYS-6LDWIKZ4DK-KTq5OHihBUfLyafqPgrzR5KA4N6z9GrTYS5IJVoOW02q4THwEFn4cZCsJN-pUNMVZbzdlsh8f98VNZzRqKEZ5_HBvaHJPlrLtmKwhIQWHw5Wdyf5tkUTL-pGN7K2RoUyd8wkDSkCdl8cCwjyH93C_UhyFQ","place_id":"07eac34486a0082252e61bc2919b7cfcbf4caef6","types":["bar","restaurant","food","establishment"],"formatted_address":"4057 North Mississippi Avenue, Portland, OR, United States","street_number":"4057","route":"North Mississippi Avenue","zipcode":"97227","city":"Portland","state":"Oregon","country":"US","created_at":"2013-11-30T20:04:06.974-08:00","updated_at":"2014-02-17T20:20:03.901-08:00","administrative_level_1":"OR","administrative_level_2":"Multnomah","td_linx_code":"2290836","location_id":738,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-122.675647 45.552972)","do_not_connect_to_api":true,"merged_with_place_id":12362})
  end
end
puts "\n\n\n--------------------\n- Recreating Tommy Rocker's: [11818]"
if Place.where(id: 8767).any?
  place = Place.find_by(id: 11818)
  place ||= Place.find_by(place_id: 'ChIJ_doeQCLEyIARjYL4kY3BMfc')
  if place.present?
    Place.find(8767).merge(place)
  else
    place = Place.create!({"id":11818,"name":"Tommy Rocker's","reference":"CnRwAAAAwhG7FO-58Sn11rsb-N1oBhqgTmov7XLe1dM_lpMLEYr4hqB7PFseL1e7RiMiEch2kHxlB9BBFt_W0HB602eycvXC9xamz7_ZWOlUAwkEiVsqVDt1QCwcRT1VWG-JO-8QKtpQoxuJWCVgha0Az1iRRBIQom7lU0U8jqcUXdErQZF-WRoUtKqesphwOsD5HIiNiu0GBNXXdKA","place_id":"ChIJ_doeQCLEyIARjYL4kY3BMfc","types":["bar","restaurant","food","establishment"],"formatted_address":"4275 Dean Martin Drive, Las Vegas, NV 89103, United States","street_number":"4275","route":"Dean Martin Drive","zipcode":"89103","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-01-29T18:48:19.759-08:00","updated_at":"2015-01-29T18:48:19.759-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":nil,"location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.182313 36.11213)","do_not_connect_to_api":true,"merged_with_place_id":8767})
  end
elsif Place.where(id: 11818).any?
  place = Place.find_by(id: 8767)
  place ||= Place.find_by(place_id: '98a38b57adb93f5505e3fa8f46107c9f2552563c')
  if place.present?
    Place.find(11818).merge(place)
  else
    place = Place.create!({"id":8767,"name":"Tommy Rocker's","reference":"CnRwAAAAhIV2qajL09Wc57B5qIu_Yece5ezZHpYM2AaTl5BlKL5snPN4vZuyNLFI42GYfOPk_ZkCtLbmvkoForRoY1RvekqmfKxUFpIuIlzY9WV1sc1-KaPFMVJ7H-rvo6W86sbzclW1y9iXwc1cEGc-EIsfixIQbuXvItl1L0reJuVce67xnhoUJCsDqbxS06CBfUXy9XddGy9Q9HE","place_id":"98a38b57adb93f5505e3fa8f46107c9f2552563c","types":["bar","restaurant","food","establishment"],"formatted_address":"4275 Dean Martin Dr, Las Vegas, NV 89103, United States","street_number":"4275","route":"Dean Martin Dr","zipcode":"89103","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-10-08T13:21:11.617-07:00","updated_at":"2014-10-08T13:21:11.617-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"5264723","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.182313 36.11213)","do_not_connect_to_api":true,"merged_with_place_id":11818})
  end
end
puts "\n\n\n--------------------\n- Recreating Liquor Barn: [9304]"
if Place.where(id: 5197).any?
  place = Place.find_by(id: 9304)
  place ||= Place.find_by(place_id: 'a3f6818525587a78731a9d55b8bdfd8116489b95')
  if place.present?
    Place.find(5197).merge(place)
  else
    place = Place.create!({"id":9304,"name":"Liquor Barn","reference":"CnRsAAAAsErUm-ipBWUaGZaco8QZD_IGE4IzVeyjS1Rwv_1wvgGrekSVCNthg3XKuc8dBggjvblajKd8nsCciBSmiTFx6SrC6-9gPlqRlv710BsP5-ySPSBFeHzkf1Us4xAbdumiVrq4cLVaxE2HCZ9LhETQKhIQX2IQdEOD2mi1T2CdL15HfhoUbqmwHO97MOwPsBr1JPdsypAXNb8","place_id":"a3f6818525587a78731a9d55b8bdfd8116489b95","types":["liquor_store","store","establishment"],"formatted_address":"4301 Shelbyville Rd, Louisville, KY 40207, United States","street_number":"4301","route":"Shelbyville Rd","zipcode":"40207","city":"Louisville","state":"Kentucky","country":"US","created_at":"2014-10-28T20:44:14.006-07:00","updated_at":"2014-10-28T20:44:14.006-07:00","administrative_level_1":"KY","administrative_level_2":nil,"td_linx_code":"3690091","location_id":1240,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-85.636632 38.251952)","do_not_connect_to_api":true,"merged_with_place_id":5197})
  end
elsif Place.where(id: 9304).any?
  place = Place.find_by(id: 5197)
  place ||= Place.find_by(place_id: '70c2aff088e821ea0e928c89e16bffce4370802a')
  if place.present?
    Place.find(9304).merge(place)
  else
    place = Place.create!({"id":5197,"name":"Liquor Barn","reference":"CnRtAAAAfd0ZnxXlI0D2f7moa2l2M_efzve8eoYLKAMvhP5YnpHhJYPmkK4wKzJPcS3HQVhYssgehtBJGNQv3TfmYtMxN0qXrTfMpzexQtdRr8QWeyQWNVuO4iO0kAejeJj7Sk3J-YWb18lUXml1Red_TlFtihIQKddwejXjeaI89VWFGSqfJxoU6CofE8n5FIsvo1B-JaLzcjTC-48","place_id":"70c2aff088e821ea0e928c89e16bffce4370802a","types":["liquor_store","food","store","establishment"],"formatted_address":"4301 Towne Center Dr, Louisville, KY, United States","street_number":"4301","route":"Towne Center Dr","zipcode":"40241","city":"Louisville","state":"Kentucky","country":"US","created_at":"2014-03-12T13:01:37.269-07:00","updated_at":"2014-03-12T13:01:37.269-07:00","administrative_level_1":"KY","administrative_level_2":nil,"td_linx_code":"1000730","location_id":1240,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-85.558444 38.299376)","do_not_connect_to_api":true,"merged_with_place_id":9304})
  end
end
puts "\n\n\n--------------------\n- Recreating Kildare's Manayunk: [12226]"
if Place.where(id: 190).any?
  place = Place.find_by(id: 12226)
  place ||= Place.find_by(place_id: 'ChIJ11I05r-4xokRQC_JH8-725g')
  if place.present?
    Place.find(190).merge(place)
  else
    place = Place.create!({"id":12226,"name":"Kildare's Manayunk","reference":"CoQBdQAAAHsgHpomrvbZy9fDPzwVO3tTp3sbb5Ebm8oZf-lIBrBsatwMTygXIyvsRfILHZBHoisBCL5ZCP4ZLdeZLNpp13R120pknqwi3eBx0Ki-0sNESCKumcXuf0q7zAHfgBrbXTZ_ZViYkSm_2auth4C3uHAlycZ7ABVPzGf3oRFSmgx8EhAOHbJGsprIQoje8JgSodDvGhR0QNJMM6_wpiHDPg3bGLzcCBoPIw","place_id":"ChIJ11I05r-4xokRQC_JH8-725g","types":["bar","restaurant","food","establishment"],"formatted_address":"4417 Main Street, Philadelphia, PA 19127, United States","street_number":"4417","route":"Main Street","zipcode":"19127","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2015-02-09T14:09:31.086-08:00","updated_at":"2015-02-18T10:58:03.416-08:00","administrative_level_1":"PA","administrative_level_2":nil,"td_linx_code":nil,"location_id":62,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.225357 40.026282)","do_not_connect_to_api":true,"merged_with_place_id":190})
  end
elsif Place.where(id: 12226).any?
  place = Place.find_by(id: 190)
  place ||= Place.find_by(place_id: '2e066a7813ab3517e685c1a5809f2fe679eb5255')
  if place.present?
    Place.find(12226).merge(place)
  else
    place = Place.create!({"id":190,"name":"Kildare's Manayunk","reference":"CnRwAAAAjCeEUxswCuqPq-qf5M_TMmBsAXXFOkQ2iuiNGXm9GEWiwwAu_yjimjE9GJAdp31i8poeLCy_q2kRiLMjuLOzrT4XOAYIyWHX2oFKVS1U8dCBOiLNOgV7YIHePl1jBwWiabiE2PBTU0G0UhyIU9FzEBIQHaScu36YbT-uFKZnOl6R3BoUqUM38WveNg8x_u754xDAK6qr9vk","place_id":"2e066a7813ab3517e685c1a5809f2fe679eb5255","types":["bar","restaurant","food","establishment"],"formatted_address":"4417 Main Street, Philadelphia, PA, United States","street_number":"4417","route":"Main Street","zipcode":"19127","city":"Philadelphia","state":"Pennsylvania","country":"US","created_at":"2013-10-11T13:34:14.936-07:00","updated_at":"2014-02-17T20:04:24.198-08:00","administrative_level_1":"PA","administrative_level_2":"Philadelphia County","td_linx_code":"5569862","location_id":62,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-75.225238 40.026405)","do_not_connect_to_api":true,"merged_with_place_id":12226})
  end
end
puts "\n\n\n--------------------\n- Recreating Sullivan's Steakhouse: [11755]"
if Place.where(id: 3512).any?
  place = Place.find_by(id: 11755)
  place ||= Place.find_by(place_id: 'ChIJY5YRlBTBQIYRbe5fbP7AV1I')
  if place.present?
    Place.find(3512).merge(place)
  else
    place = Place.create!({"id":11755,"name":"Sullivan's Steakhouse","reference":"CoQBdgAAAO16I62RgXNAFqPRFKAp-J3qhLpnb7EQ2W93y3UgtPyKqNjrfn24d9ik2c5TsTKrJZvTDGUgJ6iMzwi7Mhok8jqj_FyNHBMJ4IFrH8xQWPD0Figpk7ueeXA_nAvMuJAV2Q39hpnSBYLngnJdS6QCodgjpiLC28gYS4Bp206sF7KmEhDlmZYEoWY7mnPSGa-jF9idGhTntlKKMrY6USQHNChjes5aFwSIMg","place_id":"ChIJY5YRlBTBQIYRbe5fbP7AV1I","types":["bar","restaurant","food","establishment"],"formatted_address":"4608 Westheimer Rd, Houston, TX 77027, United States","street_number":nil,"route":nil,"zipcode":"77027","city":"Houston","state":"Texas","country":"US","created_at":"2015-01-27T21:00:57.101-08:00","updated_at":"2015-01-27T21:00:57.101-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":655,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-95.455145 29.741482)","do_not_connect_to_api":true,"merged_with_place_id":3512})
  end
elsif Place.where(id: 11755).any?
  place = Place.find_by(id: 3512)
  place ||= Place.find_by(place_id: 'b37ae613df03e7b8ec56a6ae4a14cf194df7bb6c')
  if place.present?
    Place.find(11755).merge(place)
  else
    place = Place.create!({"id":3512,"name":"Sullivan's Steakhouse","reference":"CoQBdgAAACYdpssgYmd6G_2L0gi1WiW3DCDL9Y1A2_NBQJCbNSyDgRT8L-ynsOz-WRbHoIO-GFj7eFpboN6Sa4yxvJqnfYM2NFxZzvkE-oBnPn7nSTh0jH7Gl6kyfiooadfyUefbIOLLskE7sJAkaLqhkAwMLldvS2sCs6PbvQjjGFV9_wH0EhCmq1xPSRSWAl9Rmhl_zgJfGhSMyXp3uv6RqlgR6eaNnQPBIn5FDA","place_id":"b37ae613df03e7b8ec56a6ae4a14cf194df7bb6c","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"4608 Westheimer Road, Houston, TX, United States","street_number":"4608","route":"Westheimer Road","zipcode":"77027","city":"Houston","state":"Texas","country":"US","created_at":"2013-12-10T13:50:01.532-08:00","updated_at":"2014-02-17T20:21:44.344-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"5597730","location_id":655,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-95.455222 29.741576)","do_not_connect_to_api":true,"merged_with_place_id":11755})
  end
end
puts "\n\n\n--------------------\n- Recreating Sunshine Saloon: [11783]"
if Place.where(id: 314).any?
  place = Place.find_by(id: 11783)
  place ||= Place.find_by(place_id: 'ChIJjyidFjqq3oARBqq_8RATP_U')
  if place.present?
    Place.find(314).merge(place)
  else
    place = Place.create!({"id":11783,"name":"Sunshine Saloon","reference":"CoQBcQAAANfViq2WJYmqjRLrSIyeFsIUKPiWMz8WfLlbWGL99PC9i6kvIXQ6817jWKcaoFqdQRefl2O89ccpBd3UtKFvDzukhSHScwiVxgZhcNisuWAwVDIVYcRQoECREQCCVZvQHmB4MGRXb-KFsyvD4MSVFwP8atjDhVcSofc8EHPO76LcEhAUdZa0VXCY37aHYLeUs7w7GhRtXpnvRvu5SvuCWwo1Ig_hNimPeQ","place_id":"ChIJjyidFjqq3oARBqq_8RATP_U","types":["bar","establishment"],"formatted_address":"5028 Newport Avenue, San Diego, CA 92107, United States","street_number":"5028","route":"Newport Avenue","zipcode":"92107","city":"San Diego","state":"California","country":"US","created_at":"2015-01-28T11:35:56.990-08:00","updated_at":"2015-01-28T11:35:56.990-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5235379","location_id":104,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.251527 32.747363)","do_not_connect_to_api":true,"merged_with_place_id":314})
  end
elsif Place.where(id: 11783).any?
  place = Place.find_by(id: 314)
  place ||= Place.find_by(place_id: '0c37733cd4bcc9a4c6d74f80cd4e2c7a3d4bbe2f')
  if place.present?
    Place.find(11783).merge(place)
  else
    place = Place.create!({"id":314,"name":"Sunshine Saloon","reference":"CnRuAAAACTRe7PeSqM3N-JYDQgHsEeDTKwxQpiFU95x1CuMHZ0AZHBcoZB6EI8WxCpEuXUkWurQKI8ll2Nxa8wOvKvRibR8M_-qfetuY7Or8nWsEW1gkNTe8iRWmW4zQR4EEwKDEmMUyf7wms0v9JeRWN9nrURIQxofQHPgNO-ww7RecxHlSmRoUtTbgsbQd2myUYXOTCIp27ETQH5A","place_id":"0c37733cd4bcc9a4c6d74f80cd4e2c7a3d4bbe2f","types":["bar","establishment"],"formatted_address":"5028 Newport Avenue, San Diego, CA, United States","street_number":"5028","route":"Newport Avenue","zipcode":"92107","city":"San Diego","state":"California","country":"US","created_at":"2013-10-11T13:35:27.535-07:00","updated_at":"2015-01-27T15:20:55.375-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5235379","location_id":104,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.25156 32.747311)","do_not_connect_to_api":true,"merged_with_place_id":11783})
  end
end
puts "\n\n\n--------------------\n- Recreating Gallagher's Irish Pub: [11782]"
if Place.where(id: 325).any?
  place = Place.find_by(id: 11782)
  place ||= Place.find_by(place_id: 'ChIJV4wYRDqq3oAR24WXXiHHJtE')
  if place.present?
    Place.find(325).merge(place)
  else
    place = Place.create!({"id":11782,"name":"Gallagher's Irish Pub","reference":"CoQBdwAAAEgT4wpyv9Ni4w82pEmj5z-QhkajTsmnxM7ZHxeoIKKFEiJC4G5fy_8YAanuwnJYfnFPTYnrs8sDk27YYE7QT9lDUhk1NrsXLP953uWlrBt5oUutZSJdodWc16ZZssniK5f1ymAuKktawL0stem3Yh3JEdP-Qy40pOTpvCKaYmjPEhDrs7cce1PGK1VCGwcyc-TLGhQsmXaJJQp6SPttlKSyXz-0WSiyCQ","place_id":"ChIJV4wYRDqq3oAR24WXXiHHJtE","types":["bar","restaurant","food","establishment"],"formatted_address":"5046 Newport Avenue, San Diego, CA 92107, United States","street_number":"5046","route":"Newport Avenue","zipcode":"92107","city":"San Diego","state":"California","country":"US","created_at":"2015-01-28T11:35:19.268-08:00","updated_at":"2015-01-28T11:35:19.268-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":104,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.251804 32.74756)","do_not_connect_to_api":true,"merged_with_place_id":325})
  end
elsif Place.where(id: 11782).any?
  place = Place.find_by(id: 325)
  place ||= Place.find_by(place_id: '87f99358330da16db561ce9cb5f09f4cb708139f')
  if place.present?
    Place.find(11782).merge(place)
  else
    place = Place.create!({"id":325,"name":"Gallagher's Irish Pub","reference":"CoQBdAAAAOK63gkZ096V9AYLFeO6ryvOXYE3i-eZ2LqFVnsy3QFYu6z-9XH4SXApsOVve93m63vDcg5ygwIWzRBATJrtM2Cf3SbNhnTou-yiFne7efnbXltRiposEemVmijG9g7cKossZUDJIkRgU6CEIni_4eUM6LnA5sEYpJOrq4KH5SyXEhDXrGuWfYrJcLodyKrEvMpAGhSM4Lg_2nH5s5OF0wCx6MStmRC7Tg","place_id":"87f99358330da16db561ce9cb5f09f4cb708139f","types":["bar","restaurant","food","establishment"],"formatted_address":"5046 Newport Avenue, San Diego, CA, United States","street_number":"5046","route":"Newport Avenue","zipcode":"92107","city":"San Diego","state":"California","country":"US","created_at":"2013-10-11T13:35:33.202-07:00","updated_at":"2014-02-17T20:05:04.105-08:00","administrative_level_1":"CA","administrative_level_2":"San Diego","td_linx_code":"5236212","location_id":104,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.251845 32.747474)","do_not_connect_to_api":true,"merged_with_place_id":11782})
  end
end
puts "\n\n\n--------------------\n- Recreating Dipiazza's: [11814]"
if Place.where(id: 2069).any?
  place = Place.find_by(id: 11814)
  place ||= Place.find_by(place_id: 'ChIJX5Sz1MYx3YAR--_xng4SZB0')
  if place.present?
    Place.find(2069).merge(place)
  else
    place = Place.create!({"id":11814,"name":"Dipiazza's","reference":"CnRrAAAA9HVdyQ0VxI-Xpq8FHFoQJMUketzsy8w7eBNYIZs9MIen49eyCtuqQb7hiw7f_-XEqOfX1FDJI0I21_hfYQUJYQ-pseoS6eZ8zVEHBc2BnTVQi-QaCsct_Xj32MMNCZAQmp-mMbRJNcQRKOMfbhi2_BIQWrhSYeUPqtGTVKl63gAy8hoUfoFrVwXsygEgfIvukPzIepurevM","place_id":"ChIJX5Sz1MYx3YAR--_xng4SZB0","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"5205 East Pacific Coast Highway, Long Beach, CA 90804, United States","street_number":"5205","route":"East Pacific Coast Highway","zipcode":"90804","city":"Long Beach","state":"California","country":"US","created_at":"2015-01-29T16:44:19.990-08:00","updated_at":"2015-01-29T16:44:19.990-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":83,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.131887 33.782726)","do_not_connect_to_api":true,"merged_with_place_id":2069})
  end
elsif Place.where(id: 11814).any?
  place = Place.find_by(id: 2069)
  place ||= Place.find_by(place_id: '0eb4d62a4392951f0592a43bd4e84e6c9fb5fe3c')
  if place.present?
    Place.find(11814).merge(place)
  else
    place = Place.create!({"id":2069,"name":"Dipiazza's","reference":"CnRsAAAAElBblZWcZZuh9ntqO_R3g00gg_17Cps0ded0u4r5Y8X7fNDm0wxM4ZQvuHHKf8F2KmLcEAMJ74m27qx1rKpxMZKn--wuXe2sGq9x7IUU4gnQnwvi69iu-Vg3dqJ-C6TljCx44vc_TrB6tgJWFwXalhIQXoFrGV5XYdtAqYFKTp1SiBoUej6FLIIntMGB5FT18e0GSlTx-AY","place_id":"0eb4d62a4392951f0592a43bd4e84e6c9fb5fe3c","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"5205 East Pacific Coast Highway, Long Beach, CA, United States","street_number":"5205","route":"East Pacific Coast Highway","zipcode":"90804","city":"Long Beach","state":"California","country":"US","created_at":"2013-11-11T00:51:03.152-08:00","updated_at":"2014-02-17T20:13:53.579-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5222141","location_id":83,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.131989 33.782654)","do_not_connect_to_api":true,"merged_with_place_id":11814})
  end
end
puts "\n\n\n--------------------\n- Recreating The Promontory: [12333]"
if Place.where(id: 7800).any?
  place = Place.find_by(id: 12333)
  place ||= Place.find_by(place_id: 'ChIJM1VPPXIpDogRAmuJmblNUcY')
  if place.present?
    Place.find(7800).merge(place)
  else
    place = Place.create!({"id":12333,"name":"The Promontory","reference":"CnRiAAAAYviOsaVdj-vgIMAIzEZRIIepLN6AvMZTQrre2Af9dgLezHFcT7YxD03CCVM-S4vDuJRBbvpJyHCcc3hPGyiUTNq7ZeOgtWlJKlKb68oGcFKfPR55w1_jSMSUy4EGM8PDGPAclKSrF-vStkpyM1EfVxIQO17hpj7fB-DuaeIAGXTJBxoUUeeRPdblnRQimVHwHLVGTkUhbEw","place_id":"ChIJM1VPPXIpDogRAmuJmblNUcY","types":["bar","restaurant","food","establishment"],"formatted_address":"5311 South Lake Park Avenue West, Chicago, IL 60615, United States","street_number":nil,"route":nil,"zipcode":"60615","city":"Chicago","state":"Illinois","country":"US","created_at":"2015-02-15T09:44:40.589-08:00","updated_at":"2015-02-18T10:54:55.505-08:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":nil,"location_id":43,"is_location":false,"price_level":3,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.587558 41.799188)","do_not_connect_to_api":true,"merged_with_place_id":7800})
  end
elsif Place.where(id: 12333).any?
  place = Place.find_by(id: 7800)
  place ||= Place.find_by(place_id: '089af20a4b5ce7ca9d038b2da3bd60d783c13856')
  if place.present?
    Place.find(12333).merge(place)
  else
    place = Place.create!({"id":7800,"name":"The Promontory","reference":"CoQBcQAAAFcmY2DSKI9gQgg56ra8PdvdtUMxUaIB-nr6_IRt9qfqs_9W0DjGMEHHMeQhhQe3eITmmn3O30vG4-Ty38IdiGyjIvGebucawqel7_2MWAf0gY_qUpUfoVlI96nZgPOBxJKf0bsOM-mOvWjglTdF6c8zOcmCehc9iWOae7l5I3ZrEhCJRba5DNvH6eD0JQY7QHxOGhSAahseWFwieBAtS-k3_iABEYMm7A","place_id":"089af20a4b5ce7ca9d038b2da3bd60d783c13856","types":["bar","restaurant","food","establishment"],"formatted_address":"5311 South Lake Park Avenue West, Chicago, IL, United States","street_number":nil,"route":nil,"zipcode":"60615","city":"Chicago","state":"Illinois","country":"US","created_at":"2014-08-18T11:08:01.385-07:00","updated_at":"2014-08-18T11:08:01.385-07:00","administrative_level_1":"IL","administrative_level_2":nil,"td_linx_code":nil,"location_id":43,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-87.587558 41.799188)","do_not_connect_to_api":true,"merged_with_place_id":12333})
  end
end
puts "\n\n\n--------------------\n- Recreating Effin's Pub & Grill: [12006]"
if Place.where(id: 327).any?
  place = Place.find_by(id: 12006)
  place ||= Place.find_by(place_id: 'ChIJc4EkKpdW2YARetNJ1I3iy8E')
  if place.present?
    Place.find(327).merge(place)
  else
    place = Place.create!({"id":12006,"name":"Effin's Pub \u0026 Grill","reference":"CoQBdgAAAK4l5jkt3YNGIaed6wJw08qvnbvX4ak2QZLAlOskBXvJrrRLGaheBQX1BpA6t7jcw3qW-IMHTL7locmazISh4mpdfdjfAyXpTMyxwrJFyEoZdMMOj5G03ZejPa8vmE1f6bO9fs9Ds8SSC2_VZkRepJIa6l686xrE5H04VgS0pJiKEhAX4f6gBIlbri8fqhf_PlGjGhT-r2Sdpo1EKSjEz_fhN56F0kLYIg","place_id":"ChIJc4EkKpdW2YARetNJ1I3iy8E","types":["bar","restaurant","food","establishment"],"formatted_address":"6164 El Cajon Boulevard, San Diego, CA 92115, United States","street_number":"6164","route":"El Cajon Boulevard","zipcode":"92115","city":"San Diego","state":"California","country":"US","created_at":"2015-02-03T14:41:41.875-08:00","updated_at":"2015-02-03T14:41:41.875-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5506172","location_id":104,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.064819 32.763098)","do_not_connect_to_api":true,"merged_with_place_id":327})
  end
elsif Place.where(id: 12006).any?
  place = Place.find_by(id: 327)
  place ||= Place.find_by(place_id: 'daea6acb0dcd9c68574419b6c0b0d1b7e284363a')
  if place.present?
    Place.find(12006).merge(place)
  else
    place = Place.create!({"id":327,"name":"Effin's Pub \u0026 Grill","reference":"CoQBcQAAAMnU72wQ-i1nO-Wo0x81fcWCQV3Pyitp1j-LV_XfoAyaBqVa6zUMrCMZlA0eMFjcuhFl5CHMvLqDZpu4s1I4WD0DVZ30njTeO8kczeTL1wMFMCsvYGexQFwhJvnV4jyhR3HzfxWbcJkRk2EYRafb4d9iKPVWi06DjuWNwi4txY2oEhA0bwogCFe37gwTxelW71EoGhTlLqyISKBa7YyVhvgx7knIigsU1g","place_id":"daea6acb0dcd9c68574419b6c0b0d1b7e284363a","types":["bar","restaurant","food","establishment"],"formatted_address":"6164 El Cajon Boulevard, San Diego, CA, United States","street_number":"6164","route":"El Cajon Boulevard","zipcode":"92115","city":"San Diego","state":"California","country":"US","created_at":"2013-10-11T13:35:34.144-07:00","updated_at":"2014-02-17T20:05:04.704-08:00","administrative_level_1":"CA","administrative_level_2":"San Diego","td_linx_code":"5506172","location_id":104,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.064775 32.763007)","do_not_connect_to_api":true,"merged_with_place_id":12006})
  end
end
puts "\n\n\n--------------------\n- Recreating W Hollywood: [11802]"
if Place.where(id: 31).any?
  place = Place.find_by(id: 11802)
  place ||= Place.find_by(place_id: 'ChIJSzQ7Ajm_woAR2yTwTn6QTFw')
  if place.present?
    Place.find(31).merge(place)
  else
    place = Place.create!({"id":11802,"name":"W Hollywood","reference":"CnRtAAAAT9_jBT9gNBXV4aqX-5KbPkT2e1E_Yhqy3vT1lxcmEmYGJ8oVfy_DbjIIW0lg3Bw1WzuqElO6LD4SLj1RDoA113sw7STClAUm8X4GNInNlonPvgmHVp4cWK0n1ClwlQNB2aw3w5nDmJLtb81RIKMSoBIQoPtGPmI2rzltMHCELo4G9xoU1PZrZ4DbATqKvmoxywMDJZ__gSE","place_id":"ChIJSzQ7Ajm_woAR2yTwTn6QTFw","types":["lodging","establishment"],"formatted_address":"6250 Hollywood Boulevard, Los Angeles, CA 90028, United States","street_number":"6250","route":"Hollywood Boulevard","zipcode":"90028","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-28T18:43:02.240-08:00","updated_at":"2015-01-28T18:43:02.240-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"3973552","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.325433 34.100752)","do_not_connect_to_api":true,"merged_with_place_id":31})
  end
elsif Place.where(id: 11802).any?
  place = Place.find_by(id: 31)
  place ||= Place.find_by(place_id: '93aa4959ebca57136feff8fe04a5fe270059d888')
  if place.present?
    Place.find(11802).merge(place)
  else
    place = Place.create!({"id":31,"name":"W Hollywood","reference":"CnRoAAAAunHJgdRJxUW2tK7z59zcy3-LMGnyzj5twK_HZ_E-GZCxGL3c_7L8pqHvWdebj7Y--E9BOKLvirPy4Pd25xd7UIfbMQZEpEcwwMW6o9bIwjdj29VYT1NH4uSxBseuoLrdx3NuBSKN3hteojg8MGJ2zRIQZ6GeYNrn6PKJ5XxboFhpaRoUHyGSUbiLGJRTTay1tzQRQomTXrc","place_id":"93aa4959ebca57136feff8fe04a5fe270059d888","types":["lodging","establishment"],"formatted_address":"6250 Hollywood Boulevard, Los Angeles, CA, United States","street_number":"6250 Hollywood Boulevard","route":"","zipcode":"90028","city":"Los Angeles","state":"California","country":"US","created_at":"2013-10-11T13:32:46.809-07:00","updated_at":"2014-02-27T12:23:20.507-08:00","administrative_level_1":"Los Angeles","administrative_level_2":"Los Angeles County","td_linx_code":"3973552","location_id":20,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.325433 34.100752)","do_not_connect_to_api":true,"merged_with_place_id":11802})
  end
end
puts "\n\n\n--------------------\n- Recreating Writer's Room: [11862]"
if Place.where(id: 3058).any?
  place = Place.find_by(id: 11862)
  place ||= Place.find_by(place_id: 'ChIJSZKfXSO_woARIDHHN55tFQ4')
  if place.present?
    Place.find(3058).merge(place)
  else
    place = Place.create!({"id":11862,"name":"Writer's Room","reference":"CnRuAAAAn4ra6Z1dBYNwPAo1jKyaRBEUjIfvX8-P3L7_QEmTlCR2zpulzrpl881QqbFeDF8iBFT-vWky8JL5JqH_NwXHLpJEXIVhDoBcZY6DAIsueX-LiL2qEtC0vqYp8d0pIjQgHTb-VCim8es0PMrAG6SxaxIQ_T7zLoeooobn57Hk8xESahoU1RibPGbhEKqCx9X5VTyE1GZHb80","place_id":"ChIJSZKfXSO_woARIDHHN55tFQ4","types":["bar","establishment"],"formatted_address":"6685 Hollywood Boulevard, Los Angeles, CA 90028, United States","street_number":"6685","route":"Hollywood Boulevard","zipcode":"90028","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-30T18:06:18.130-08:00","updated_at":"2015-01-30T18:06:18.130-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.335938 34.101736)","do_not_connect_to_api":true,"merged_with_place_id":3058})
  end
elsif Place.where(id: 11862).any?
  place = Place.find_by(id: 3058)
  place ||= Place.find_by(place_id: 'b7d70da11d4a142cacfa65ad70d66ef74f7dfbb9')
  if place.present?
    Place.find(11862).merge(place)
  else
    place = Place.create!({"id":3058,"name":"Writer's Room","reference":"CnRuAAAAkIhiW-qRd_f7t13-_4_cYbKVOv49_kEqVuQpwZLwkQdKD4xu8gOH6iE8QGoT21Hf2f8VGYGeSJY70Gchk1d3BKIiTDxXgRyn3xRO7OnujbS6fzS2gj0JE8xNTH1PJ3gKRK6qcxo5SAv4J116RtpJdRIQF8jlJyfajQMW_pJUFunhZhoUCDkbkTWs5rQMiukE3vp-3L8CVwQ","place_id":"b7d70da11d4a142cacfa65ad70d66ef74f7dfbb9","types":["bar","establishment"],"formatted_address":"6685 Hollywood Boulevard, Los Angeles, CA, United States","street_number":"6685","route":"Hollywood Boulevard","zipcode":"90028","city":"Los Angeles","state":"California","country":"US","created_at":"2013-11-21T08:58:07.291-08:00","updated_at":"2014-02-17T20:19:14.413-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"3796153","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.335878 34.1017)","do_not_connect_to_api":true,"merged_with_place_id":11862})
  end
end
puts "\n\n\n--------------------\n- Recreating Rocky's 7440 Club: [11914]"
if Place.where(id: 4150).any?
  place = Place.find_by(id: 11914)
  place ||= Place.find_by(place_id: 'ChIJXaWZQr7fmoARmT6NxTa-Jrk')
  if place.present?
    Place.find(4150).merge(place)
  else
    place = Place.create!({"id":11914,"name":"Rocky's 7440 Club","reference":"CoQBdAAAAE7usMOTHZrn-QHZQVgZaCKG_7VrwCXVjYryXaBJQmMa5GOzcPU2UwIOG2tqXBRD9vWn9s2GxyiBWXf1OM3xgaXTpChYRKNhokJmXjE4immXZbDNQz9nfcKxTHoyjU22LD5Wj6f10sh2LgVCfsMKgl4gBY9-_HSm1czbHmDwwgBIEhCjhIMVkRStW12UAsjh8IeOGhQJuro6I8GGxH4-Ojky_DXWxjVv8A","place_id":"ChIJXaWZQr7fmoARmT6NxTa-Jrk","types":["night_club","bar","establishment"],"formatted_address":"7440 Auburn Boulevard, Citrus Heights, CA 95610, United States","street_number":"7440","route":"Auburn Boulevard","zipcode":"95610","city":"Citrus Heights","state":"California","country":"US","created_at":"2015-02-01T19:57:59.167-08:00","updated_at":"2015-02-01T19:57:59.167-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5243725","location_id":305,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.289921 38.700995)","do_not_connect_to_api":true,"merged_with_place_id":4150})
  end
elsif Place.where(id: 11914).any?
  place = Place.find_by(id: 4150)
  place ||= Place.find_by(place_id: '678baca0b6fe9f96d67d8e7adccd50ec9c2d9263')
  if place.present?
    Place.find(11914).merge(place)
  else
    place = Place.create!({"id":4150,"name":"Rocky's 7440 Club","reference":"CoQBcwAAAH5ufroP-AZLRZ36HADs2RswjXyohsmL7zUtA-LUZTI4vVGOM7oLs731sjeO8h4o9DcMN7-v8bzKj39k8_VIEcfYcawrL6VRT-iGMWikn6UUMmYXV4Y7sv2p66mPpsWc0UUryRxBqVvCi-7IWhTKHnqYnOkJsNW7Bb6U1bmwhuttEhAWDjQz5P8DW2ZyT1li_8gXGhS_6ZPasMtOR0r-gue6LGfj1mHnbA","place_id":"678baca0b6fe9f96d67d8e7adccd50ec9c2d9263","types":["night_club","bar","establishment"],"formatted_address":"7440 Auburn Boulevard, Citrus Heights, CA, United States","street_number":"7440","route":"Auburn Boulevard","zipcode":"95610","city":"Citrus Heights","state":"California","country":"US","created_at":"2014-01-21T16:08:31.444-08:00","updated_at":"2014-02-17T20:25:35.748-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5243725","location_id":305,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-121.290149 38.700871)","do_not_connect_to_api":true,"merged_with_place_id":11914})
  end
end
puts "\n\n\n--------------------\n- Recreating Mel and Rose: [11855]"
if Place.where(id: 8670).any?
  place = Place.find_by(id: 11855)
  place ||= Place.find_by(place_id: 'ChIJIcWjRLa-woARGcgOWJOmY6Y')
  if place.present?
    Place.find(8670).merge(place)
  else
    place = Place.create!({"id":11855,"name":"Mel and Rose","reference":"CnRuAAAA4y3XlNvoxJ0JR7cAO2W3vOf8UoaUlC0OFq_7wDfddJkWposH-G3PnarPj2inhA8VJQoEG2Elo-SdeKtNoohjFkC9EWEe1ze_lJotOglb3CZf3iAJhEuPyRQ5zRlOda2bnzEsMILpC8Vin56D9dGSChIQliu_DgIjTtmKwtxXUlvPghoUMtgC3G2RPoj_1FpWKQENgIA7N7Q","place_id":"ChIJIcWjRLa-woARGcgOWJOmY6Y","types":["liquor_store","grocery_or_supermarket","food","store","establishment"],"formatted_address":"8344 Melrose Avenue, Los Angeles, CA 90069, United States","street_number":"8344","route":"Melrose Avenue","zipcode":"90069","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-30T17:33:42.534-08:00","updated_at":"2015-01-30T17:33:42.534-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.371825 34.083499)","do_not_connect_to_api":true,"merged_with_place_id":8670})
  end
elsif Place.where(id: 11855).any?
  place = Place.find_by(id: 8670)
  place ||= Place.find_by(place_id: '388b5f06032f42e8faea9f215a0be7e5fb38e9b3')
  if place.present?
    Place.find(11855).merge(place)
  else
    place = Place.create!({"id":8670,"name":"Mel and Rose","reference":"CnRvAAAAVxmxYY1DfEeO7F7ToRMHpldrtqe9W0_XoWYbTkBQGMcVP2kX13EgbfAxUG_Qfi05HyDaOYYC_SPjzR7hkMR6VH3lNTDXC8czTUkPtVRe8Xx122UDjXf0GEcb8rSWx7-o_MHo_X519bIl_BifzoRdYhIQlDc-a5_jEhkTllY36of9ehoUA9b6JxV7DF35beh96LWStOU4qN0","place_id":"388b5f06032f42e8faea9f215a0be7e5fb38e9b3","types":["liquor_store","grocery_or_supermarket","food","store","establishment"],"formatted_address":"8344 Melrose Ave, Los Angeles, CA 90069, United States","street_number":"8344","route":"Melrose Ave","zipcode":"90069","city":"Los Angeles","state":"California","country":"US","created_at":"2014-10-05T13:44:58.159-07:00","updated_at":"2014-10-05T13:44:58.159-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.371825 34.083499)","do_not_connect_to_api":true,"merged_with_place_id":11855})
  end
end
puts "\n\n\n--------------------\n- Recreating A.O.C.: [11968]"
if Place.where(id: 7776).any?
  place = Place.find_by(id: 11968)
  place ||= Place.find_by(place_id: 'ChIJX6WyxTa5woARZPdVFVEVAKU')
  if place.present?
    Place.find(7776).merge(place)
  else
    place = Place.create!({"id":11968,"name":"A.O.C.","reference":"CnRpAAAAH3SZ8yYNqz9VZ1o60hy0Fc4hq0uHMSq27KOzSIas_Q_RV-Lkk41ZyBODlH4S1iS824Ip91f9j3E_XDlB7d1HE4_E2fGCHMuyzPwCSEuO0gAxmwo0Btt2cBwDnvlcUX9qrBckvXZZbCenjXujrW_6UhIQSBHNSrS7eeRpUR20-zfPDhoUnHkNodcQbySS16t_xCzBwDJ1Jkw","place_id":"ChIJX6WyxTa5woARZPdVFVEVAKU","types":["bar","restaurant","food","establishment"],"formatted_address":"8700 West 3rd Street, Los Angeles, CA 90048, United States","street_number":"8700","route":"West 3rd Street","zipcode":"90048","city":"Los Angeles","state":"California","country":"US","created_at":"2015-02-02T18:44:18.623-08:00","updated_at":"2015-02-02T18:44:18.623-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"7196451","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.381973 34.07341)","do_not_connect_to_api":true,"merged_with_place_id":7776})
  end
elsif Place.where(id: 11968).any?
  place = Place.find_by(id: 7776)
  place ||= Place.find_by(place_id: 'f7930ee5eeae6fab21600516ced80e4eb157f99b')
  if place.present?
    Place.find(11968).merge(place)
  else
    place = Place.create!({"id":7776,"name":"A.O.C.","reference":"CnRpAAAAG46GGJV1eqm4wEDTK34EkCVEfKJmoKHf8kM84cvzYiQuPR3njKr5Igo92V_O5-7wwu4svNjFyesj1ycsTW3zEfG-iexmW017__6Cm8KvarSLD0nHCNILOSpW7gCiVBE2aA3TmwOO41q0VivCjkK94RIQBjUmCVNx1WMfBhSzkAPRYhoUSyzYfYfCmI4IuA-kZgrcB3-LTFQ","place_id":"f7930ee5eeae6fab21600516ced80e4eb157f99b","types":["bar","restaurant","food","establishment"],"formatted_address":"8700 W 3rd St, Los Angeles, CA, United States","street_number":"8700","route":"W 3rd St","zipcode":"90048","city":"Los Angeles","state":"California","country":"US","created_at":"2014-08-17T11:31:17.378-07:00","updated_at":"2014-08-17T11:31:17.378-07:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"7196451","location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.381948 34.073415)","do_not_connect_to_api":true,"merged_with_place_id":11968})
  end
end
puts "\n\n\n--------------------\n- Recreating Dominick's: [11788]"
if Place.where(id: 5772).any?
  place = Place.find_by(id: 11788)
  place ||= Place.find_by(place_id: 'ChIJuYvwgLK-woAR1uJnmdYGL34')
  if place.present?
    Place.find(5772).merge(place)
  else
    place = Place.create!({"id":11788,"name":"Dominick's","reference":"CnRsAAAArdeNVxyagPZVcr1jsJMBmju4-2wWPb69k-pZwrEtFP7kJd-OUPJa4aEBgVYu3pLed6We32OGe9vFx2VriCnr2eLzIB0x8s32p1DvUEfOKPrViyRWhfZjnPzYQWyMEOr1UHKlUg4m0KbnptT16Zp6UxIQTkaolZf647wrR7fXI_u-4BoUrCH1ZkU9XUuoBVv4SsBxXLIZg1s","place_id":"ChIJuYvwgLK-woAR1uJnmdYGL34","types":["bar","restaurant","food","establishment"],"formatted_address":"8715 Beverly Boulevard, West Hollywood, CA 90048, United States","street_number":"8715","route":"Beverly Boulevard","zipcode":"90048","city":"West Hollywood","state":"California","country":"US","created_at":"2015-01-28T15:59:50.951-08:00","updated_at":"2015-01-28T15:59:50.951-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.381079 34.077069)","do_not_connect_to_api":true,"merged_with_place_id":5772})
  end
elsif Place.where(id: 11788).any?
  place = Place.find_by(id: 5772)
  place ||= Place.find_by(place_id: 'e5012cf4cb53acda0db8c9a5a2fa02c4032de55b')
  if place.present?
    Place.find(11788).merge(place)
  else
    place = Place.create!({"id":5772,"name":"Dominick's","reference":"CnRsAAAAT15tuETn1LX1IDdkgVgeCOLfXkmgFsedgeYfKE2e_PJwfYhltG-_1pK18ViH62ppDL1sX8hrpc6xBWurSSgG5BMlppSVtDEn7Lu9ZmbGvLBnW4msYjQVkYun5HdQiZwsqc2pwuTHzLVsEHRgMX1vfBIQxRdCC-YFVP_t1iEi6lvccxoUzi3Yz8tee1OqGGZtTHDJM23NyPk","place_id":"e5012cf4cb53acda0db8c9a5a2fa02c4032de55b","types":["bar","restaurant","food","establishment"],"formatted_address":"8715 Beverly Blvd, West Hollywood, CA, United States","street_number":"8715","route":"Beverly Blvd","zipcode":"90048","city":"West Hollywood","state":"California","country":"US","created_at":"2014-04-01T13:57:59.409-07:00","updated_at":"2014-04-01T13:57:59.409-07:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"5229099","location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.381079 34.077069)","do_not_connect_to_api":true,"merged_with_place_id":11788})
  end
end
puts "\n\n\n--------------------\n- Recreating Petit Ermitage: [11949]"
if Place.where(id: 4133).any?
  place = Place.find_by(id: 11949)
  place ||= Place.find_by(place_id: 'ChIJe72g-aS-woARFWxi79pOMe0')
  if place.present?
    Place.find(4133).merge(place)
  else
    place = Place.create!({"id":11949,"name":"Petit Ermitage","reference":"CnRwAAAAzLiTUZ06POEMLUofFlAy3VLy0CpHWjCALPvV8xd-FjjPuvCK4jeMsGCaTdZO_DB474ry7umUy0fJdO1B-t-8gsO_lbwT4cPngxNZ7pgyBtFGVv7fD_jnIDzcvcxEV1VIyrO1C-HpdlDZswnQHuHCTRIQBuMRaZagJ9OflCqZBsTd0hoUFzFxbnYrkD_qWWEYEwXNdtvBZco","place_id":"ChIJe72g-aS-woARFWxi79pOMe0","types":["lodging","establishment"],"formatted_address":"8822 Cynthia Street, West Hollywood, CA 90069, United States","street_number":"8822","route":"Cynthia Street","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2015-02-02T14:11:23.258-08:00","updated_at":"2015-02-02T14:11:23.258-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.384123 34.087102)","do_not_connect_to_api":true,"merged_with_place_id":4133})
  end
elsif Place.where(id: 11949).any?
  place = Place.find_by(id: 4133)
  place ||= Place.find_by(place_id: '1383fe5b8bca9f5e4ccc327012471016f1b98259')
  if place.present?
    Place.find(11949).merge(place)
  else
    place = Place.create!({"id":4133,"name":"Petit Ermitage","reference":"CnRwAAAABIW3HB8gp3KH1yqJX7gfDAEwAalCAgScMG5iLsHkAf8p1OsaYSSnX0n7M53IYyD9gAzEuprgtJZXpZLQG8Tl3wOSuVrGUcT-CY3C7yFi_05pl2UcsUEE542xP3S3iaIRul14t4kDYbbJwIVlCGcmiRIQFdg3cJ309_WHcgYH8WJ_mxoUKIm1WLb6XMCPkt3UzjY4WzrbIe8","place_id":"1383fe5b8bca9f5e4ccc327012471016f1b98259","types":["lodging","establishment"],"formatted_address":"8822 Cynthia Street, West Hollywood, CA, United States","street_number":"8822","route":"Cynthia Street","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2014-01-21T09:57:25.353-08:00","updated_at":"2014-02-17T20:25:30.353-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles","td_linx_code":"5500097","location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.383998 34.087198)","do_not_connect_to_api":true,"merged_with_place_id":11949})
  end
end
puts "\n\n\n--------------------\n- Recreating Rock and Reilly's Irish Pub: [12248]"
if Place.where(id: 28).any?
  place = Place.find_by(id: 12248)
  place ||= Place.find_by(place_id: 'ChIJQ0PKyKO-woARNr4ExF4gPVI')
  if place.present?
    Place.find(28).merge(place)
  else
    place = Place.create!({"id":12248,"name":"Rock and Reilly's Irish Pub","reference":"CoQBfQAAAHu5echdHYbBmrD0tVwJCbYIoBIWAomG4920Tk0_p_EYJIYs5j2pA-KYaWluieRUnd9hyugOmIL4oxiS2bty81GipiBrqnMlFMt3p9eoq0wZ-DH2k7ktgEWjZRPTeH68ieMfxvTXr8ckhMyyResM9Xu9TOXCceEwHRFNv-IpOwNpEhBf-jWhbg0ieyv81tnzK1zFGhThxo1N1Q6AZPs9kQaOvlkI87eASg","place_id":"ChIJQ0PKyKO-woARNr4ExF4gPVI","types":["bar","restaurant","food","establishment"],"formatted_address":"8911 Sunset Boulevard, West Hollywood, CA 90069, United States","street_number":"8911","route":"Sunset Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2015-02-10T09:40:09.395-08:00","updated_at":"2015-02-18T10:57:58.664-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5249862","location_id":21,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.385975 34.090838)","do_not_connect_to_api":true,"merged_with_place_id":28})
  end
elsif Place.where(id: 12248).any?
  place = Place.find_by(id: 28)
  place ||= Place.find_by(place_id: 'e9069067861a7bc5f88c2daec981e951e6ac851c')
  if place.present?
    Place.find(12248).merge(place)
  else
    place = Place.create!({"id":28,"name":"Rock and Reilly's Irish Pub","reference":"CoQBeQAAAFUo5-H0zFwymswvvlPbl7QKZ4wSlwRFzBCegytwM57kpzhaK6SSf29BHRX5KlQ8-ysXvgf74o0uZYWWP7Zb-RG58hqN52---wG8g5VJJzYsrpMlzfpL8nkJsnDohvZrRXX96FXF9Qyd4h6maau8Fy_kOewQgSycsbHOJbT9O82tEhDy2E32zlMkOkc8HaxTOk6PGhT6luigRmrcFA5kU9DAaA2KXJJtlw","place_id":"e9069067861a7bc5f88c2daec981e951e6ac851c","types":["bar","restaurant","food","establishment"],"formatted_address":"8911 Sunset Blvd, West Hollywood, CA, United States","street_number":"8911","route":"Sunset Blvd","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2013-10-11T13:32:45.124-07:00","updated_at":"2014-02-17T20:03:23.782-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5249862","location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.385923 34.090773)","do_not_connect_to_api":true,"merged_with_place_id":12248})
  end
end
puts "\n\n\n--------------------\n- Recreating Dan Tana's: [12417]"
if Place.where(id: 3039).any?
  place = Place.find_by(id: 12417)
  place ||= Place.find_by(place_id: 'ChIJreK-k6i-woARSyd335Nkcr0')
  if place.present?
    Place.find(3039).merge(place)
  else
    place = Place.create!({"id":12417,"name":"Dan Tana's","reference":"CmReAAAAp07pgQpJuqNGXEJmJxU-OwRnXykeLTa9aFakCpaZNXKRJKSOd5LFXmErCkdIp18s_UX16LSzzLWZ2omktaSYcVo07_KgCLbwaJGgjvaVWy3ExRtYZHQcMv1KND3Kds_4EhCaHSuQMJRDP1ZD02152b5HGhSQhn_nwdLfV1zAN6DlJkBFBZ_mFA","place_id":"ChIJreK-k6i-woARSyd335Nkcr0","types":["bar","restaurant","food","establishment"],"formatted_address":"9071 Santa Monica Boulevard, West Hollywood, CA 90069, United States","street_number":"9071","route":"Santa Monica Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2015-02-17T12:28:57.283-08:00","updated_at":"2015-02-18T10:54:38.486-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":21,"is_location":false,"price_level":3,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.389037 34.081773)","do_not_connect_to_api":true,"merged_with_place_id":3039})
  end
elsif Place.where(id: 12417).any?
  place = Place.find_by(id: 3039)
  place ||= Place.find_by(place_id: '951518acfb33b64aa33cfca276135db4341bada8')
  if place.present?
    Place.find(12417).merge(place)
  else
    place = Place.create!({"id":3039,"name":"Dan Tana's","reference":"CnRtAAAADDLYBDstYlwmCmvDU-BCPN898PTKkdnkNovxn8wnwab-bbqPl5pMupKq3Z4y5Etc_GBY7SJwDn0kjgAPxirwqNF_QpvVYaGk2pnoYF_l1GMN46vVL0EwPIhyYKn25EOwYw2pGJbBObtm8r4oU9cq5BIQJYTT-zM8YVVtIZiFzUykgRoUWfmlFudc0-lWHegT5hP-jQRJr20","place_id":"951518acfb33b64aa33cfca276135db4341bada8","types":["restaurant","food","establishment"],"formatted_address":"9071 Santa Monica Boulevard, West Hollywood, CA, United States","street_number":"9071","route":"Santa Monica Boulevard","zipcode":"90069","city":"West Hollywood","state":"California","country":"US","created_at":"2013-11-19T19:27:19.088-08:00","updated_at":"2014-02-17T20:19:07.726-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles","td_linx_code":"5226285","location_id":21,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.389001 34.081729)","do_not_connect_to_api":true,"merged_with_place_id":12417})
  end
end
puts "\n\n\n--------------------\n- Recreating University of California San Diego: [11803]"
if Place.where(id: 7454).any?
  place = Place.find_by(id: 11803)
  place ||= Place.find_by(place_id: 'ChIJT69MQcQG3IARpz6Rifyqtu8')
  if place.present?
    Place.find(7454).merge(place)
  else
    place = Place.create!({"id":11803,"name":"University of California San Diego","reference":"CpQBhAAAAIfO77KtoSaMIkYjcjy-TXNi0d6v60Q-qMSP9hY-VaPJWesFo7REH82Ret_R7zSod93hyHzGtK4mA8vUqzKvBq5p6yxhapmFCA33CK_J7LFkJKN0IYLduGpjTB1j8fwz0_wADROU3GhpaBmBCxstwp9qomdfZL0WEPci_ZmqUIuuu1nVL7b2G1f0bJgrOVdsfxIQKCH9BskZbyn_2eO7kCFXMhoU6TrPYCS9cCM-owVEFjO9lUeBjSg","place_id":"ChIJT69MQcQG3IARpz6Rifyqtu8","types":["university","establishment"],"formatted_address":"9500 Gilman Drive, La Jolla, CA 92093, United States","street_number":"9500","route":"Gilman Drive","zipcode":"92093","city":"La Jolla","state":"California","country":"US","created_at":"2015-01-28T18:49:30.711-08:00","updated_at":"2015-01-28T18:49:30.711-08:00","administrative_level_1":"CA","administrative_level_2":"San Diego County","td_linx_code":nil,"location_id":1881,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.234013 32.88006)","do_not_connect_to_api":true,"merged_with_place_id":7454})
  end
elsif Place.where(id: 11803).any?
  place = Place.find_by(id: 7454)
  place ||= Place.find_by(place_id: 'bfd55838e72171d9e6637f406bd551f4c4700960')
  if place.present?
    Place.find(11803).merge(place)
  else
    place = Place.create!({"id":7454,"name":"University of California San Diego","reference":"CpQBhQAAAP7Pm2XYRhWBO-0FtF3R3_tYLvp8k8PSucFnY-y_jEejtT7GYPaf9B7681kMNoVnAxWce8F5MS6AzyIycOaNLGAz4oXR-145UcJFxI0HZuW2jX7QJ_nQp7D3q4gNiuV9tnS3OqUsDeDEPIPt94M5myLgY32gnN4csUP8b4uf3oCNIyoMOHAU4XOMggNYfkWIIRIQb4n7iYyKE3YzYOMbS0Ms_hoUOKKLvPFZEIYRw4AKfTrsr2LAgWU","place_id":"bfd55838e72171d9e6637f406bd551f4c4700960","types":["university","establishment"],"formatted_address":"9500 Gilman Dr, La Jolla, CA, United States","street_number":"9500","route":"Gilman Dr","zipcode":"92093","city":"La Jolla","state":"California","country":"US","created_at":"2014-07-24T11:01:15.151-07:00","updated_at":"2014-07-24T11:01:15.151-07:00","administrative_level_1":"CA","administrative_level_2":"San Diego County","td_linx_code":"5517784","location_id":1881,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.234013 32.88006)","do_not_connect_to_api":true,"merged_with_place_id":11803})
  end
end
puts "\n\n\n--------------------\n- Recreating Third Base South Park Meadows: [11770]"
if Place.where(id: 386).any?
  place = Place.find_by(id: 11770)
  place ||= Place.find_by(place_id: 'ChIJwR0TUtZMW4YRQHab4-yfXmU')
  if place.present?
    Place.find(386).merge(place)
  else
    place = Place.create!({"id":11770,"name":"Third Base South Park Meadows","reference":"CoQBfwAAABiBV2DIMc-zPOptMgkwEbMvP0G9Xj9_Yd-weL6Uf34mrVajHpwKYhOpWQP5-gGG_ciEab9y06l-tzl43E8yM_7xvY52xDvZRL66OafUE-6cdHwnQaBFNTfMznxEYyPCpuWykQhKGg6OYwmWTHDmhv-nZzlgqPm-cH389ysjJjMDEhDmb2mK8pGgS2wjp9VQmuUsGhSr2mRCOIBUTVdJv92iSA1-0-QL0g","place_id":"ChIJwR0TUtZMW4YRQHab4-yfXmU","types":["bar","restaurant","food","establishment"],"formatted_address":"9600 S I H 35 # B, Austin, TX 78748, United States","street_number":"9600","route":"S I H 35 # B","zipcode":"78748","city":"Austin","state":"Texas","country":"US","created_at":"2015-01-28T08:38:16.648-08:00","updated_at":"2015-02-04T10:37:44.091-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.791469 30.160554)","do_not_connect_to_api":true,"merged_with_place_id":386})
  end
elsif Place.where(id: 11770).any?
  place = Place.find_by(id: 386)
  place ||= Place.find_by(place_id: 'd3711da12217bb0efade40d2591809ad641975ab')
  if place.present?
    Place.find(11770).merge(place)
  else
    place = Place.create!({"id":386,"name":"Third Base South Park Meadows","reference":"CoQBewAAACvjw_VToXUU-Umz26FSg8eSHFRInw61PEfAh7ApBiXhbDiRTLI0TC0xYD-OyrFToSBgpj1EQ47FxpsMfXbL8mzoVSvJO4mVkEchG0d5kmeZLGwacEs_5LWPIg6vsWx_qcn1HN-k0YSDCRzAx2li8C4fM18-_XZAV5fX9SIphhCmEhBDri1K4orlQu5Liohq-PzrGhQsDS_mJEF3A5HnxDXWkiJpCurjRQ","place_id":"d3711da12217bb0efade40d2591809ad641975ab","types":["bar","restaurant","food","establishment"],"formatted_address":"9600 S I H 35 # B, Austin, TX, United States","street_number":"9600","route":"S I H 35 # B","zipcode":"78748","city":"Austin","state":"Texas","country":"US","created_at":"2013-10-11T13:36:10.035-07:00","updated_at":"2015-02-04T11:00:16.582-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"2575998","location_id":27,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.791474 30.160515)","do_not_connect_to_api":true,"merged_with_place_id":11770})
  end
end
puts "\n\n\n--------------------\n- Recreating Khoury's Fine Wine & Spirits: [11779]"
if Place.where(id: 7931).any?
  place = Place.find_by(id: 11779)
  place ||= Place.find_by(place_id: 'ChIJ1VN5NmvOyIARr2dMmi6qBio')
  if place.present?
    Place.find(7931).merge(place)
  else
    place = Place.create!({"id":11779,"name":"Khoury's Fine Wine \u0026 Spirits","reference":"CoQBfQAAAAIG3kSMEaVJfeMh1S8xJpCP8VdGu-95zlZ8PNOYNB2uZh8-kylwXRrSAVZwrJOQ_VRqKYirzvDvZCD6aZi8l39blKo8VkDSstBbRnzKIenerVUR7cko9FtK8PH6JF0jPfxul6BvUgBQAceBKdjPSQ3iUaIXVx5EidCVharmfXyREhB-2cZK-Ij24g49nvrJ70k2GhT5HnEgpD_LOmGOp8p2gsHBmTYmyg","place_id":"ChIJ1VN5NmvOyIARr2dMmi6qBio","types":["liquor_store","food","store","bar","establishment"],"formatted_address":"9915 South Eastern Avenue #110, Las Vegas, NV 89183, United States","street_number":"9915","route":"South Eastern Avenue","zipcode":"89183","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2015-01-28T10:01:58.205-08:00","updated_at":"2015-01-28T10:01:58.205-08:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"1857033","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.118383 36.00921)","do_not_connect_to_api":true,"merged_with_place_id":7931})
  end
elsif Place.where(id: 11779).any?
  place = Place.find_by(id: 7931)
  place ||= Place.find_by(place_id: '955c5ec890a1631c82f5b70ad61ed6d99388226f')
  if place.present?
    Place.find(11779).merge(place)
  else
    place = Place.create!({"id":7931,"name":"Khoury's Fine Wine \u0026 Spirits","reference":"CoQBfQAAAHCut-vv4slAvZVin937KEGY7rWMAonESl-Y5-2eAV5zGlW8w9kJ3xOtwNbEGldOyWTOK6RpQQDE5axMlfcMvrb6T-_KV7V_lOcRP7qkBKa-tMHo89rccXspQyPviR0NZuN_4LijvMZIfSvFqONIqnkhb5gJ-_PCrGYkgLeqdJJQEhCUGVPF8Ek8NAA4-P--h-cDGhSQwmMr0nBE2JZB7HstQBtFIDabrg","place_id":"955c5ec890a1631c82f5b70ad61ed6d99388226f","types":["liquor_store","food","store","bar","establishment"],"formatted_address":"9915 S Eastern Ave #110, Las Vegas, NV, United States","street_number":"9915","route":"S Eastern Ave","zipcode":"89183","city":"Las Vegas","state":"Nevada","country":"US","created_at":"2014-09-02T15:17:12.336-07:00","updated_at":"2014-09-02T15:17:12.336-07:00","administrative_level_1":"NV","administrative_level_2":nil,"td_linx_code":"1857033","location_id":672,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-115.11627 36.008797)","do_not_connect_to_api":true,"merged_with_place_id":11779})
  end
end
puts "\n\n\n--------------------\n- Recreating Timmy Nolan's Tavern and Grill OTHER INCORRECT: [7808]"
if Place.where(id: 267).any?
  place = Place.find_by(id: 7808)
  place ||= Place.find_by(place_id: '571c290c38d708a94541fce789254d9880ad681c')
  if place.present?
    Place.find(267).merge(place)
  else
    place = Place.create!({"id":7808,"name":"Timmy Nolan's Tavern and Grill OTHER INCORRECT","reference":"CpQBigAAAPhF9wa977W8aO4O19u5TExm_Ew35VT5glk0M5e9h3V1tO4B9vFXk4N2fWTuctMa54_wVuAYIgKo3GPzT23yjS67t5mfOVs_k8Tyvh_LMaNWj3dzqp3kNilGw_fPkti5aHGpdErG2MLbiQe-PF1SITNyb8M0A-Y18ZuekWF59I6d5ikETQcls1suZDt6OPD_2xIQi02TTzNxGO1YooTru1dYihoUmsE2wVrGU3-SdJWhxa9BOq4g3HQ","place_id":"571c290c38d708a94541fce789254d9880ad681c","types":["bar","point_of_interest","establishment"],"formatted_address":"Timmy Nolan's Tavern and Grill, 10111 Riverside Dr, Toluca Lake, CA 91602, USA","street_number":"10111","route":"Riverside Dr","zipcode":"91602","city":"Los Angeles","state":"California","country":"US","created_at":"2014-08-18T22:41:53.091-07:00","updated_at":"2015-02-27T10:54:41.822-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"","location_id":19,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.3510263 34.1523443)","do_not_connect_to_api":true,"merged_with_place_id":267})
  end
elsif Place.where(id: 7808).any?
  place = Place.find_by(id: 267)
  place ||= Place.find_by(place_id: 'e691a52fd9629ce403d13f51f6e638feafc1ab32')
  if place.present?
    Place.find(7808).merge(place)
  else
    place = Place.create!({"id":267,"name":"Timmy Nolan's Tavern and Grill ","reference":"CoQBewAAAF4pJU67A-kEFj4EZiE4xxiG-cZpK_-oAxvh9hjiyyBFHcfqn0PP_OQky_tqHeabcOoXSTxKtiZs8mTZwZpL_pMBq9oGWidY-Lvj00DMEhOXiC1mjeSFdO_aGjKy60N1lcPWmDc8i2bbP2HVYLPfa0aLeBAB42zPwiFNeD17Rz_xEhBBPTiVE2hM0EdQNz2GTzxGGhSNlvGa_H42qDw0RIl6yKYklVjGIA","place_id":"e691a52fd9629ce403d13f51f6e638feafc1ab32","types":["night_club","bar","restaurant","food","establishment"],"formatted_address":"10111 Riverside Drive, Toluca Lake, CA 91602","street_number":"10111","route":"Riverside Drive","zipcode":"91602","city":"Los Angeles","state":"California","country":"US","created_at":"2013-10-11T13:35:03.567-07:00","updated_at":"2015-02-27T10:54:50.569-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"5246827","location_id":19,"is_location":false,"price_level":1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.351026 34.152344)","do_not_connect_to_api":true,"merged_with_place_id":7808})
  end
end
puts "\n\n\n--------------------\n- Recreating Brion's Grille - Incorrect: [12336]"
if Place.where(id: 8044).any?
  place = Place.find_by(id: 12336)
  place ||= Place.find_by(place_id: 'ChIJvZ_6vVxOtokRXT8PD15vPnQ')
  if place.present?
    Place.find(8044).merge(place)
  else
    place = Place.create!({"id":12336,"name":"Brion's Grille - Incorrect","reference":"CnRhAAAAKXjjWwZ1Ehm5FlHFT7f2vUemVKQLps1O8JXZhHBvB5GEmA-YUFRSRNnPGramKQuE0_mhvh4Ko6AkHY1sWkM4SMGwaGkLO6HFBpqEyYhrt1fLN4cmQgUEE_qkWsY2F9ilpd99gpTDA7_wFQXMFT13PhIQC48KQ0uoX_VOSvxOJWDMFhoU6IL8isFuBq6y9B7-XuyQJSd2hJY","place_id":"ChIJvZ_6vVxOtokRXT8PD15vPnQ","types":["bar","restaurant","food","establishment"],"formatted_address":"10621 Braddock Road, Fairfax, VA 22032, United States","street_number":"10621","route":"Braddock Road","zipcode":"22032","city":"Fairfax","state":"Virginia","country":"US","created_at":"2015-02-15T12:21:04.562-08:00","updated_at":"2015-02-27T15:37:03.846-08:00","administrative_level_1":"VA","administrative_level_2":nil,"td_linx_code":"5604454","location_id":1770,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.314272 38.825458)","do_not_connect_to_api":true,"merged_with_place_id":8044})
  end
elsif Place.where(id: 12336).any?
  place = Place.find_by(id: 8044)
  place ||= Place.find_by(place_id: '2f89c869f8c84fc3aafa833ce5566a40809f826e')
  if place.present?
    Place.find(12336).merge(place)
  else
    place = Place.create!({"id":8044,"name":"Brion's Grille ","reference":"CnRvAAAAbwcqBJDt2H-PKhZ7mnaCQXb0EWnw7ajrBHoeqXPCpZPv_pt-b6psNOYtMuT-h6-1rl294wlaT7oDPjDBmXjz5VN5XuIklntPV5aMoTxlWpEUkB5xw1SE5TZu-Mu93s3aEVjp8VipeLK2nIbRP67cMhIQ2rG5Rax48BUCgOqbhflzvBoUoQC8hRf8Bw8uDxWDy3yJDs8mrlQ","place_id":"2f89c869f8c84fc3aafa833ce5566a40809f826e","types":["bar","restaurant","food","establishment"],"formatted_address":"10621 Braddock Rd, Fairfax, VA, United States","street_number":"10621","route":"Braddock Rd","zipcode":"22032","city":"Fairfax","state":"Virginia","country":"US","created_at":"2014-09-09T07:40:57.199-07:00","updated_at":"2015-02-27T15:37:15.746-08:00","administrative_level_1":"VA","administrative_level_2":"Fairfax County","td_linx_code":"5604454","location_id":1770,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-77.314272 38.825458)","do_not_connect_to_api":true,"merged_with_place_id":12336})
  end
end
puts "\n\n\n--------------------\n- Recreating Costco: [9511]"
if Place.where(id: 9468).any?
  place = Place.find_by(id: 9511)
  place ||= Place.find_by(place_id: '65c3b681802f894d23eaa2f3dd9e5c9ee68ce321')
  if place.present?
    Place.find(9468).merge(place)
  else
    place = Place.create!({"id":9511,"name":"Costco","reference":"CnRoAAAAWmqXUh85S-7yrZvdK6Mj_R1BbdUPPd0yf25MvqXWFdXHX-PC6jFFF335i24l8wbHDci_tSFEB3Bjocqhf57Vd9MslV61ZYF7tqt2u1e8wjpeljnT1TNN0lSIg9OSQfZkiRFwEXTKYQod4PRNGMST3RIQkO_0FeikKqL7GvN6rRDbwRoU7OJ4QswkwVOjDP_q2NkimkwLOuc","place_id":"65c3b681802f894d23eaa2f3dd9e5c9ee68ce321","types":["store","establishment"],"formatted_address":"11000 W Garden Grove Blvd, Garden Grove, CA 92843, United States","street_number":"11000","route":"W Garden Grove Blvd","zipcode":"92843","city":"Garden Grove","state":"California","country":"US","created_at":"2014-11-03T10:31:16.557-08:00","updated_at":"2014-11-03T10:31:16.557-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":8287,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.940741 33.772582)","do_not_connect_to_api":true,"merged_with_place_id":9468})
  end
elsif Place.where(id: 9511).any?
  place = Place.find_by(id: 9468)
  place ||= Place.find_by(place_id: 'd22242e6fc7a36dfb68b815b5d9e2a5348b351a7')
  if place.present?
    Place.find(9511).merge(place)
  else
    place = Place.create!({"id":9468,"name":"Costco Vision Center","reference":"CoQBdgAAAGuwEzSJMXtb-_jUGZqqe22xqGoOqAVkmkYdt6KywyUEs5bCHsYwbAnL3Uh0Ukob7GIVpc4YEGIovNG2P-PTqqbvnTh3UD0TKQOZ5OG4uwuNZ5ZlUH1TLnSWgIn0B3a9a-aTMWqWFcDp2gmTS6uSXjZmDC9p6MehJ1Y7f9PBrpy9EhBKLG_O2f16xS6wSBezDteMGhTckpiBKyTJ6yoIyKXfk77vQvoQ2g","place_id":"d22242e6fc7a36dfb68b815b5d9e2a5348b351a7","types":["store","health","establishment"],"formatted_address":"11000 Garden Grove Blvd, Garden Grove, CA 92843, United States","street_number":"11000","route":"Garden Grove Blvd","zipcode":"92843","city":"Garden Grove","state":"California","country":"US","created_at":"2014-11-02T17:16:29.446-08:00","updated_at":"2014-11-02T17:16:29.446-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":8287,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-117.94095 33.77208)","do_not_connect_to_api":true,"merged_with_place_id":9511})
  end
end
puts "\n\n\n--------------------\n- Recreating Lock & Key Social Drinkery: [11465]"
if Place.where(id: 5844).any?
  place = Place.find_by(id: 11465)
  place ||= Place.find_by(place_id: '0a5ae5ed7f170589d24902cf2ebbbb59cce6df7d')
  if place.present?
    Place.find(5844).merge(place)
  else
    place = Place.create!({"id":11465,"name":"Lock \u0026 Key Social Drinkery","reference":"CoQBfQAAAMLRLGaEEmJNKi8NpDvga_GrxB2EdZjUT2TPmbO_MUu6O8cRbOoIuhQ_80Svrp6WueowUkPVB-FIA-O9SOAg36LaHDgyYrDxiJJiGSdm4wqKc9HVYbhuTAJvCcZiLJO84Jk5ECPcmXNaVhxvhekniZ5j7YVcj2nEvbFJAg59B1RpEhAYxXSXsJyer4PYo37yObfNGhTCowEg16BjahF06as95jQja-iXTg","place_id":"0a5ae5ed7f170589d24902cf2ebbbb59cce6df7d","types":["restaurant","food","establishment"],"formatted_address":"11033 Downey Avenue, Downey, CA 90241, United States","street_number":"11033","route":"Downey Avenue","zipcode":"90241","city":"Downey","state":"California","country":"US","created_at":"2015-01-19T21:11:02.046-08:00","updated_at":"2015-01-19T21:11:02.046-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":363,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.132468 33.941349)","do_not_connect_to_api":true,"merged_with_place_id":5844})
  end
elsif Place.where(id: 11465).any?
  place = Place.find_by(id: 5844)
  place ||= Place.find_by(place_id: '0c0275f34537093f316ab0979b1d5d7a49f1a99c')
  if place.present?
    Place.find(11465).merge(place)
  else
    place = Place.create!({"id":5844,"name":"Lock \u0026 Key","reference":"CqQBkwAAANYWnSAyF3gvwvbq_GqOeRiUHxFSHlyB4NrFqMCzCwuP9xWrPxqbRWCKNM-4jsmJ5HLwwgSIcPv4hTzcdG3PtzbEocZ0HyClFjRjz5zUBKCGupfbXzxO_CTmwWW8jCClS-MEtdV7EHj7x1EU252PmTc3c7-rb5EBwZ__vPk0nG9P3KT5HOron-c4u0lXWBZ_bk8iVqKcwKKUgdbR3tMC_54SEMxR9q3Sva55IUHraTB3HMIaFEYU9tJRyxHhMzPMGmmlV-QBCVX1","place_id":"0c0275f34537093f316ab0979b1d5d7a49f1a99c","types":["street_address"],"formatted_address":"11033 Downey Ave, Downey, CA 90241, USA","street_number":"11033","route":"Downey Ave","zipcode":"90241","city":"Downey","state":"California","country":"US","created_at":"2014-04-07T10:45:02.287-07:00","updated_at":"2014-04-07T11:01:18.853-07:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":"7298784","location_id":363,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.1324685 33.9413491)","do_not_connect_to_api":true,"merged_with_place_id":11465})
  end
end
puts "\n\n\n--------------------\n- Recreating Barú Urbano: [12203]"
if Place.where(id: 1751).any?
  place = Place.find_by(id: 12203)
  place ||= Place.find_by(place_id: 'ChIJC3cAVaG-2YgRnDe3GmQcsrY')
  if place.present?
    Place.find(1751).merge(place)
  else
    place = Place.create!({"id":12203,"name":"Barú Urbano","reference":"CnRuAAAAYpgYGsfBMXqQyUV7fWel2vafdvOoeI62tW1N5vKhE65-FTuwXEurGhiEdI9iLnMvJ_1BscICpXJc0XWOEwdZ_GYdUYrHNVLFVhcxwJJytUsbg5eXo9x71Gx08wCWzdtFp5KS-9HbY_8F8h7z0TkqHxIQiwo8R6vjsveYBpksm0uJ7BoU7MYOl6BLTcxDzVcxeVYwh0DdDXA","place_id":"ChIJC3cAVaG-2YgRnDe3GmQcsrY","types":["bar","restaurant","food","establishment"],"formatted_address":"11402 Northwest 41st Street, Doral, FL 33178, United States","street_number":"11402","route":"Northwest 41st Street","zipcode":"33178","city":"Doral","state":"Florida","country":"US","created_at":"2015-02-09T10:43:45.784-08:00","updated_at":"2015-02-18T10:58:09.194-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":nil,"location_id":694,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.38272 25.810977)","do_not_connect_to_api":true,"merged_with_place_id":1751})
  end
elsif Place.where(id: 12203).any?
  place = Place.find_by(id: 1751)
  place ||= Place.find_by(place_id: '6ad81ba0f59f9d0ca8c508523363a78b0347c58f')
  if place.present?
    Place.find(12203).merge(place)
  else
    place = Place.create!({"id":1751,"name":"Barú Urbano","reference":"CnRvAAAARW9vBzYHmDJJODUMQp0KOGuWgcnEQOBLgHuSx8_EyISoqXLrAgucav86aOm4Eb8UeOm7VMTmKloNtVq6DgfPJS7-x9aue5_obGoLr9B81Xga8D-vRst61lSrLxwmoYzb5Vk2TT2yjVxoVRSwSxZrjRIQm5LjaQxGPpoYgCosdtZjNBoUhwycPUaQAiSAAcRWyRDjnSQqYLk","place_id":"6ad81ba0f59f9d0ca8c508523363a78b0347c58f","types":["restaurant","food","establishment"],"formatted_address":"11402 Northwest 41st Street, Doral, FL, United States","street_number":"11402","route":"Northwest 41st Street","zipcode":"33178","city":"Doral","state":"Florida","country":"US","created_at":"2013-11-11T00:48:50.790-08:00","updated_at":"2014-02-17T20:12:07.180-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"3903906","location_id":694,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.38272 25.810977)","do_not_connect_to_api":true,"merged_with_place_id":12203})
  end
end
puts "\n\n\n--------------------\n- Recreating Rocco's Tavern INCORRECT: [11822]"
if Place.where(id: 9678).any?
  place = Place.find_by(id: 11822)
  place ||= Place.find_by(place_id: 'ChIJz7DIi_C9woARgtCR9Dh1sRU')
  if place.present?
    Place.find(9678).merge(place)
  else
    place = Place.create!({"id":11822,"name":"Rocco's Tavern INCORRECT","reference":"CnRvAAAADd18fvmyIRgn9M3YJIfPKMYKq3jk9zwGjMJjJ-Gf0ex_00-_89YGmqrEjNK97o3x1K0n8ykjsky8eBfUPNBZ6z5UlN2fcssXrHvTcgsTNcvaTLxEuHJ1UCnDunzaZOcYm4lbG58BnTN8JTd9xR6wPBIQAEizVg6Cif47TEhuIGkaJxoUKH2cLuPsYxiQ1_kf1EnnOgp8ddI","place_id":"ChIJz7DIi_C9woARgtCR9Dh1sRU","types":["bar","restaurant","food","establishment"],"formatted_address":"12514 Ventura Boulevard, Studio City, CA 91604, United States","street_number":"12514","route":"Ventura Boulevard","zipcode":"91604","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-29T22:24:50.853-08:00","updated_at":"2015-02-27T11:09:42.574-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"","location_id":19,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.405778 34.142581)","do_not_connect_to_api":true,"merged_with_place_id":9678})
  end
elsif Place.where(id: 11822).any?
  place = Place.find_by(id: 9678)
  place ||= Place.find_by(place_id: '3769cb740f3193a183c378357b4265f5f808d636')
  if place.present?
    Place.find(11822).merge(place)
  else
    place = Place.create!({"id":9678,"name":"Rocco's Tavern","reference":"CnRvAAAArSzLk-giePXnHoQRdEvJ_U-pmJvS6b-JWUlUFOj0XivgX56cvhFlLnAmOD-CR6GlawyJK3jtUB10c3BLgFvXYgFoKlbERELH9qYDW7vtDhQoms9Em3FxaxCI-TropTkioL0ckx7FnPK0vSDpOrSk9xIQLiP2pVm7bkFhRFXiRJsuMxoUyJ0rAVuhfDSn3ihsnI05xDAws5M","place_id":"3769cb740f3193a183c378357b4265f5f808d636","types":["bar","restaurant","food","establishment"],"formatted_address":"12514 Ventura Blvd, Studio City, CA 91604","street_number":"12514","route":"Ventura Blvd","zipcode":"91604","city":"Los Angeles","state":"California","country":"US","created_at":"2014-11-09T11:19:03.195-08:00","updated_at":"2015-02-27T11:10:05.976-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":"","location_id":19,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.405778 34.142581)","do_not_connect_to_api":true,"merged_with_place_id":11822})
  end
end
puts "\n\n\n--------------------\n- Recreating Mahall's: [11824]"
if Place.where(id: 9774).any?
  place = Place.find_by(id: 11824)
  place ||= Place.find_by(place_id: 'ChIJoYGEKx3yMIgRJTh0SbsFt08')
  if place.present?
    Place.find(9774).merge(place)
  else
    place = Place.create!({"id":11824,"name":"Mahall's","reference":"CnRqAAAAirehQe67_tFgOUzlKEQi0YtjyDwoFZE2t8EsvOc-17DDnIWelE7XiXeUoCxlTBrh16LGLUJD3a8d7WkwsOjd6RnbEDp4ZLcnQQEPO2E4ED5C8JU1s2KJbqAej1QJZLbkEYvfDpzIRbr5jSID7UcyHBIQrRwTygSv6yqeZz2SWbFH2xoU2dzHvFpE9B30i5KBytxzC7nu_SE","place_id":"ChIJoYGEKx3yMIgRJTh0SbsFt08","types":["bowling_alley","bar","restaurant","food","establishment"],"formatted_address":"13200 Madison Avenue, Lakewood, OH 44107, United States","street_number":"13200","route":"Madison Avenue","zipcode":"44107","city":"Lakewood","state":"Ohio","country":"US","created_at":"2015-01-30T05:26:36.957-08:00","updated_at":"2015-01-30T05:26:36.957-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":nil,"location_id":964,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.781148 41.477303)","do_not_connect_to_api":true,"merged_with_place_id":9774})
  end
elsif Place.where(id: 11824).any?
  place = Place.find_by(id: 9774)
  place ||= Place.find_by(place_id: 'ec67a17f1bed5fd6bfc67b42b4f899293cd86a43')
  if place.present?
    Place.find(11824).merge(place)
  else
    place = Place.create!({"id":9774,"name":"Mahall's","reference":"CnRqAAAA0xmt7d8LyE_dW8iFNf-nBCySyPc_1y27q4HWGzABhY_g-xgeCYYQs7zQtWCHiIZjeixL9NaPUGuys9UeZ-nLYSyFSs1wgSnEl0xm2qh-WNHqOOFB1B6D9RUF6K6FGpw_C6fuikThrk1sDHhDnwd4HRIQ4wL0389qe5YuskbNjtXhFhoUtQNpr_8vWF702MShv7JOQDIfZDw","place_id":"ec67a17f1bed5fd6bfc67b42b4f899293cd86a43","types":["bowling_alley","bar","restaurant","food","establishment"],"formatted_address":"13200 Madison Ave, Lakewood, OH 44107, United States","street_number":"13200","route":"Madison Ave","zipcode":"44107","city":"Lakewood","state":"Ohio","country":"US","created_at":"2014-11-12T12:55:53.281-08:00","updated_at":"2014-11-12T12:55:53.281-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":nil,"location_id":964,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.781148 41.477303)","do_not_connect_to_api":true,"merged_with_place_id":11824})
  end
end
puts "\n\n\n--------------------\n- Recreating Third Base: [11771]"
if Place.where(id: 388).any?
  place = Place.find_by(id: 11771)
  place ||= Place.find_by(place_id: 'ChIJC1A-udIyW4YRIG53VhmZg6E')
  if place.present?
    Place.find(388).merge(place)
  else
    place = Place.create!({"id":11771,"name":"Third Base","reference":"CnRsAAAA7okKrrka5i8hGezkUopm48MPZjN5PUCIcMX94uoJXavunylFuvn3H87fAYsRdiyCo8PB35upUXcuKR6YgPsAQfhh7aLI_FFwEUqQNXuSk440VwYp9vWtaOI8v68Pw5ee46f8V-1mB6D7WWfrShL1fhIQPbm4Zhm4B_D4Is6USMw7ZRoU6oasb26NM5XfL7_rnD71cpwnKOE","place_id":"ChIJC1A-udIyW4YRIG53VhmZg6E","types":["bar","establishment"],"formatted_address":"13301 U.S. 183, Austin, TX 78750, United States","street_number":"13301","route":"U.S. 183","zipcode":"78750","city":"Austin","state":"Texas","country":"US","created_at":"2015-01-28T08:39:33.159-08:00","updated_at":"2015-02-04T10:59:32.684-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":nil,"location_id":27,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.786605 30.445201)","do_not_connect_to_api":true,"merged_with_place_id":388})
  end
elsif Place.where(id: 11771).any?
  place = Place.find_by(id: 388)
  place ||= Place.find_by(place_id: 'c7e2c1ce7de14be2831ca7d84b3d0b459a3915a9')
  if place.present?
    Place.find(11771).merge(place)
  else
    place = Place.create!({"id":388,"name":"Third Base","reference":"CnRpAAAAhxmghtTwI-EBNot_F76wE0-iz5evoS9Oj7X5hbVNzs4CAgTSJpWz0ZrAnZR8DiU1RXeW3CEBfjmLY_3jErJmpN2JgvTr9OMmNzKqRSH84x_Zw-tM8wRH__aJNTW4Stwewa5mEUYcSYiXZcCVQBIBgBIQZgZ_jI73CNkhkZwxK0smeBoUudJt7SEENso1EcxMu6lGQdUcKq4","place_id":"c7e2c1ce7de14be2831ca7d84b3d0b459a3915a9","types":["bar","establishment"],"formatted_address":"13301 U.S. 183, Austin, TX, United States","street_number":"13301","route":"U.S. 183","zipcode":"78750","city":"Austin","state":"Texas","country":"US","created_at":"2013-10-11T13:36:10.796-07:00","updated_at":"2015-02-04T10:59:31.362-08:00","administrative_level_1":"TX","administrative_level_2":"Williamson County","td_linx_code":"2133017","location_id":27,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-97.786598 30.445141)","do_not_connect_to_api":true,"merged_with_place_id":11771})
  end
end
puts "\n\n\n--------------------\n- Recreating Murph's: [11823]"
if Place.where(id: 10118).any?
  place = Place.find_by(id: 11823)
  place ||= Place.find_by(place_id: 'ChIJDSI6qiCWwoARaUxw8JxUJQw')
  if place.present?
    Place.find(10118).merge(place)
  else
    place = Place.create!({"id":11823,"name":"Murph's","reference":"CnRoAAAA0VnOWkHdDHXuZFeYpEa_EEAf6UOIch-Z7BQVssF9jqRrFOhunR0Rf-2EMJ9hXkkNkR6nxFqfHhYdYwqSyBrZCw8PtOWYGKD3rUAO1kIkUV_WFbxj55kCMJGk8LZo_dw4SURVWMWULVafnBToKUL8phIQuBeyan3VkvrfKrF2LHNYJRoUqC67T1rBpUGkZCigA5Frc4xPxnQ","place_id":"ChIJDSI6qiCWwoARaUxw8JxUJQw","types":["bar","restaurant","food","establishment"],"formatted_address":"14649 Ventura Boulevard, Los Angeles, CA 91604, United States","street_number":nil,"route":nil,"zipcode":"91604","city":"Los Angeles","state":"California","country":"US","created_at":"2015-01-29T22:34:28.212-08:00","updated_at":"2015-01-29T22:34:28.212-08:00","administrative_level_1":"CA","administrative_level_2":nil,"td_linx_code":nil,"location_id":19,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.452515 34.15181)","do_not_connect_to_api":true,"merged_with_place_id":10118})
  end
elsif Place.where(id: 11823).any?
  place = Place.find_by(id: 10118)
  place ||= Place.find_by(place_id: '90419dbfb81e6881966abd7f2bf68dd72b7c3ade')
  if place.present?
    Place.find(11823).merge(place)
  else
    place = Place.create!({"id":10118,"name":"Murph's","reference":"CnRpAAAAb7mKpFP1QadfbIupC3FMzfg91H6XKgQyoYnIi7c_4BxrLhArUbX3FdKo9Z28Ery7U-FESLKkV6l1OFtLBpZuAE-Q88UStImFLKly1AFkDN5STj4iN5H5BR0ryyD-BB9jZvhNASV9O8PpVcwZoVxWkhIQIFxFL3arYe6H7SWLgs1GFxoUSib2deEZUc-uSPeBCrPkBaXMt1k","place_id":"90419dbfb81e6881966abd7f2bf68dd72b7c3ade","types":["bar","restaurant","food","establishment"],"formatted_address":"14649 Ventura Blvd, Los Angeles, CA 91604, United States","street_number":"14649","route":"Ventura Blvd","zipcode":"91604","city":"Los Angeles","state":"California","country":"US","created_at":"2014-11-26T01:27:53.741-08:00","updated_at":"2014-11-26T01:27:53.741-08:00","administrative_level_1":"CA","administrative_level_2":"Los Angeles County","td_linx_code":nil,"location_id":442,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-118.421854 34.146284)","do_not_connect_to_api":true,"merged_with_place_id":11823})
  end
end
puts "\n\n\n--------------------\n- Recreating Billiard Club: [12195]"
if Place.where(id: 5024).any?
  place = Place.find_by(id: 12195)
  place ||= Place.find_by(place_id: 'ChIJkRQE3Nak2YgRBLHLc-4VBX4')
  if place.present?
    Place.find(5024).merge(place)
  else
    place = Place.create!({"id":12195,"name":"Billiard Club","reference":"CnRvAAAAmwVBh7SndoEAlbCWxOMKwyzu8sSmOpq7dzxXCICLagpFb0gfe890Qi63JtQET4934KDGu8M0yesVOjeoryukqYSq7dzKehfVE69YjKsOWMoOrkdUP2Mn2xWVgWYxei12j_C4jauHS-G04E4G5WhNWxIQ6e73N3peNluAJmeLyYSfdBoUQqe05ysk_H4xq8uK_yBeMcfOz_Q","place_id":"ChIJkRQE3Nak2YgRBLHLc-4VBX4","types":["bar","establishment"],"formatted_address":"15532 Northwest 77th Court, Hialeah, FL 33016, United States","street_number":"15532","route":"Northwest 77th Court","zipcode":"33016","city":"Hialeah","state":"Florida","country":"US","created_at":"2015-02-09T09:28:37.575-08:00","updated_at":"2015-02-18T10:58:10.477-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"5175223","location_id":695,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.326118 25.915002)","do_not_connect_to_api":true,"merged_with_place_id":5024})
  end
elsif Place.where(id: 12195).any?
  place = Place.find_by(id: 5024)
  place ||= Place.find_by(place_id: '23ab832a73e3213a62d9dfe96404d20e2af499fd')
  if place.present?
    Place.find(12195).merge(place)
  else
    place = Place.create!({"id":5024,"name":"Billiard Club","reference":"CnRvAAAAG9injooZ_qpFWM43WI-QPXkeCj0QKIFV1d5P4dEWCK36b0mU9EenU9fMtTgUux-NqnqgRSp6Xbcv28o9pc7WGBfgJql4j7h5K1lKYBReEKXUeTQfARb0V6F1HAhFReo6pgghh6d994frlKLZmR0YdBIQrewP446kJP5wVsHUtMg6CBoUCHQC4PPHHvgfcRe3LNGBIxlUcSk","place_id":"23ab832a73e3213a62d9dfe96404d20e2af499fd","types":["bar","establishment"],"formatted_address":"15532 NW 77th Ct, Hialeah, FL, United States","street_number":"15532","route":"NW 77th Ct","zipcode":"33016","city":"Hialeah","state":"Florida","country":"US","created_at":"2014-03-06T21:29:04.636-08:00","updated_at":"2014-03-06T21:29:04.636-08:00","administrative_level_1":"FL","administrative_level_2":nil,"td_linx_code":"5175223","location_id":695,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-80.325781 25.914917)","do_not_connect_to_api":true,"merged_with_place_id":12195})
  end
end
puts "\n\n\n--------------------\n- Recreating Maguire's Restaurant: [11972]"
if Place.where(id: 8255).any?
  place = Place.find_by(id: 11972)
  place ||= Place.find_by(place_id: 'ChIJu5nbtvsjTIYRhG0Esu-L9mw')
  if place.present?
    Place.find(8255).merge(place)
  else
    place = Place.create!({"id":11972,"name":"Maguire's Restaurant","reference":"CoQBdgAAAOpZdroD_AP0DWT8nXGHT2a5cTPz9YtZ4kZVvs6vMGrQbvRq7gAGL6k1sgJTNvBfyF1-CkqRjQ1iakdT0EeFLIvrgEBROg1otVdpnPwNcuKELaEM65w_x0mzyOQq29YGO8PXxLkBA3ClryWN_WyuVu9nsgbPNFO5c7OQO0t8QUCFEhANwO9JLAt6WLEPwt-Vj6FxGhQOdtiHBYeH6LctiVHEkkECfxJSEg","place_id":"ChIJu5nbtvsjTIYRhG0Esu-L9mw","types":["bar","restaurant","food","establishment"],"formatted_address":"17552 Dallas Parkway, Dallas, TX 75287, United States","street_number":"17552","route":"Dallas Parkway","zipcode":"75287","city":"Dallas","state":"Texas","country":"US","created_at":"2015-02-02T20:53:07.229-08:00","updated_at":"2015-02-02T20:53:07.229-08:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1617500","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.828197 32.990208)","do_not_connect_to_api":true,"merged_with_place_id":8255})
  end
elsif Place.where(id: 11972).any?
  place = Place.find_by(id: 8255)
  place ||= Place.find_by(place_id: 'f18cd17fcf4d749e5669e84abfc7d732a79c673e')
  if place.present?
    Place.find(11972).merge(place)
  else
    place = Place.create!({"id":8255,"name":"Maguire's Restaurant","reference":"CoQBdgAAAPiV2ttOCEBd05KTmBLLbreYkWj7RgFh_7ATi6Q7TX4u2girr9kjGngBsmG4KfK0TfFGCLHoqT_th0nqFBtZDaC_rNeCxaLf3eDSsjWwA8uQuu3-rbUdGRqV8ohlaPym0GmyRfwoVgXSSA4xeLb3GujEHvAX3_cRa0VnDBv8uysiEhAyFnG5KfZ54NKKZjbKw7kFGhSyWXFdeXis1uI2Nzxy2vC8-Iof0g","place_id":"f18cd17fcf4d749e5669e84abfc7d732a79c673e","types":["restaurant","food","establishment"],"formatted_address":"17552 Dallas Pkwy, Dallas, TX, United States","street_number":"17552","route":"Dallas Pkwy","zipcode":"75287","city":"Dallas","state":"Texas","country":"US","created_at":"2014-09-22T09:53:30.290-07:00","updated_at":"2014-09-22T09:53:30.290-07:00","administrative_level_1":"TX","administrative_level_2":nil,"td_linx_code":"1617500","location_id":544,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-96.828197 32.990208)","do_not_connect_to_api":true,"merged_with_place_id":11972})
  end
end
puts "\n\n\n--------------------\n- Recreating Frank & Tony's Place: [12177]"
if Place.where(id: 2311).any?
  place = Place.find_by(id: 12177)
  place ||= Place.find_by(place_id: 'ChIJJQDu5XSpMYgRCQb9yeYqqyc')
  if place.present?
    Place.find(2311).merge(place)
  else
    place = Place.create!({"id":12177,"name":"Frank \u0026 Tony's Place","reference":"CoQBdgAAAAVrRA6QcyvbSz20Dqq7KXUi-iTraIqDh4bZvnXwz_B9cNNTpK760CBCVA_Eyc8SlacnF2lnl_oVy806rMZw10cCGsYZ41X_D_gR3zYSwXqIJx00g93hQgmEt-AqiN4vdrbff1ATJr7pr9TaXeMWz3VRIz74oycDySMC0nF1ZEgDEhDA8wOLioVUjwFoUb1rLBBYGhRImmmjFueVZIdeC9Cc5KoWgfatWg","place_id":"ChIJJQDu5XSpMYgRCQb9yeYqqyc","types":["restaurant","food","establishment"],"formatted_address":"38107 2nd Street, Willoughby, OH 44094, United States","street_number":"38107","route":"2nd Street","zipcode":"44094","city":"Willoughby","state":"Ohio","country":"US","created_at":"2015-02-09T05:13:00.852-08:00","updated_at":"2015-02-18T11:01:14.721-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":nil,"location_id":970,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.407723 41.640864)","do_not_connect_to_api":true,"merged_with_place_id":2311})
  end
elsif Place.where(id: 12177).any?
  place = Place.find_by(id: 2311)
  place ||= Place.find_by(place_id: '7127ca5dca49b9cb529f24bc3d8ecdfbc79010b4')
  if place.present?
    Place.find(12177).merge(place)
  else
    place = Place.create!({"id":2311,"name":"Frank \u0026 Tony's Place","reference":"CoQBdQAAAK8a3AAqrzUA2R24pYo7mJps2-RFng8lrJkCPV92QiKfxPs7UlwVnCE6jrN2wTGHpVYPo2Jtmj28J6qlgpN-bSUFQZl8Zpgw8s6BzD8N_cItefpw2SBrpAsoRUgA_Pp6bmatIjfqcTZuGwDIWsFRJ2hazWeddE12yy7vjkRw_q_ZEhDveyn8WeivARS6h_o6cTC7GhTHITI0h6zCinX8oBc-OJDVyhAUUg","place_id":"7127ca5dca49b9cb529f24bc3d8ecdfbc79010b4","types":["restaurant","food","establishment"],"formatted_address":"38107 2nd Street, Willoughby, OH, United States","street_number":"38107","route":"2nd Street","zipcode":"44094","city":"Willoughby","state":"Ohio","country":"US","created_at":"2013-11-11T00:53:21.181-08:00","updated_at":"2015-02-20T09:13:14.409-08:00","administrative_level_1":"OH","administrative_level_2":nil,"td_linx_code":"1876646","location_id":970,"is_location":false,"price_level":2,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.407739 41.640724)","do_not_connect_to_api":true,"merged_with_place_id":12177})
  end
end
puts "\n\n\n--------------------\n- Recreating Downing Student Union: [12310]"
if Place.where(id: 8250).any?
  place = Place.find_by(id: 12310)
  place ||= Place.find_by(place_id: 'ChIJ-5h5AdXoZYgRjnwsMN9sj1s')
  if place.present?
    Place.find(8250).merge(place)
  else
    place = Place.create!({"id":12310,"name":"Downing Student Union","reference":"CoQBgAAAAE0flGj6N6RfUA4xPlWtbRc5hHIadTkNqY_DNHavAdlZhcUwif2KsF7V7oCoj464La9fRhq9WFC1ZVRZy8BVa0RphSCVPdG6eda42vvz2BWQea_b_8MiXdrL-SUs-9NwGzRHjVyYP_FK6CsKXNoQviv7hw13J_UwawSp9uDn0KOFEhB6p_zXKTpw5n_2UnDnPeOtGhS5mxS_NvdMQYXG_8FrRoQf11SLBw","place_id":"ChIJ-5h5AdXoZYgRjnwsMN9sj1s","types":["premise"],"formatted_address":"Downing Student Union, Western Kentucky University, Avenue Of Champions, Bowling Green, KY 42101, USA","street_number":nil,"route":"Avenue Of Champions","zipcode":"42101","city":"Bowling Green","state":"Kentucky","country":"US","created_at":"2015-02-12T16:41:30.942-08:00","updated_at":"2015-02-18T10:57:47.290-08:00","administrative_level_1":"KY","administrative_level_2":"Warren County","td_linx_code":nil,"location_id":11073,"is_location":false,"price_level":-1,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-86.45691269999999 36.9848873)","do_not_connect_to_api":true,"merged_with_place_id":8250})
  end
elsif Place.where(id: 12310).any?
  place = Place.find_by(id: 8250)
  place ||= Place.find_by(place_id: 'cf3e16ab0a08b48fff69b75673bb11004239afee')
  if place.present?
    Place.find(12310).merge(place)
  else
    place = Place.create!({"id":8250,"name":"Downing Student Union","reference":"CpQBgQAAACncghmbI8jYVyC0Pfx1A_h0Q5aLdi_qvOMBZxAK6g8ik2AgKyUt2sdOYIkZTovxwiSHURVZXVzOGMS2VxXIASNxqzNFJ2-1teVmNAjllyMkj18SLdX0s0FxN1ynXJNqFumR-EwCUnN2KApfHS6oPdh160pcKNYW_yBl-wyEq0ThvTQ_5tqfWXOk1sMoINyPdxIQOGn1DDqLpCabpVRqd2D4cRoUa-qXhFyF6e08FQh0x3yHsz6AxuM","place_id":"cf3e16ab0a08b48fff69b75673bb11004239afee","types":["premise"],"formatted_address":"Downing Student Union, Avenue of Champions, Western Kentucky University, Bowling Green, KY 42101, USA","street_number":nil,"route":"Avenue of Champions","zipcode":"42101","city":"Bowling Green","state":"Kentucky","country":"US","created_at":"2014-09-22T08:25:08.949-07:00","updated_at":"2014-09-22T08:25:08.949-07:00","administrative_level_1":"KY","administrative_level_2":"Warren County","td_linx_code":nil,"location_id":11073,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-86.4568382 36.9848233)","do_not_connect_to_api":true,"merged_with_place_id":12310})
  end
end
puts "\n\n\n--------------------\n- Recreating West Park Station: [10527]"
if Place.where(id: 2210).any?
  place = Place.find_by(id: 10527)
  place ||= Place.find_by(place_id: 'fcb713e409b0328f0423d73e9aeccfc5dbe3df80')
  if place.present?
    Place.find(2210).merge(place)
  else
    place = Place.create!({"id":10527,"name":"West Park Station","reference":"CoQBfAAAABB3shQjrtlmDQjfyZ8tj5Yy3T0VQEwXl4HJ2Qwp__C7Ps16G9m6veqWAEeJS9vxMsA88xfJ7itllhU8ZobsLZDBD7W0NKSOVjjozuPsnqfNrzbZnjHn1fL2y8DDdsonbgeFhATGSAGmQoqIF-cHHKrtcG0FkNi8cbjfvRXUS_5VEhDqpWpxq7bKSawezZI3LywjGhQqhq1H-sSNFwXoAa3-IW0scnDHFA","place_id":"fcb713e409b0328f0423d73e9aeccfc5dbe3df80","types":["subway_station","transit_station","train_station","establishment"],"formatted_address":"West Park Station, Cleveland, OH 44111, USA","street_number":nil,"route":nil,"zipcode":"44111","city":"Cleveland","state":"Ohio","country":"US","created_at":"2014-12-02T06:43:52.856-08:00","updated_at":"2014-12-02T06:43:52.856-08:00","administrative_level_1":"OH","administrative_level_2":"Cuyahoga County","td_linx_code":nil,"location_id":167789,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.792856 41.456617)","do_not_connect_to_api":true,"merged_with_place_id":2210})
  end
elsif Place.where(id: 10527).any?
  place = Place.find_by(id: 2210)
  place ||= Place.find_by(place_id: '5a3257a03c1337b505eea8e1f592a17275cd4d28')
  if place.present?
    Place.find(10527).merge(place)
  else
    place = Place.create!({"id":2210,"name":"West Park Station","reference":"CoQBfAAAAL6uZjN7WSqCKwZyZxeQredVJkMvOVXnlSLKZTLOVCNhgYIYp0SrEWFfQhruiSxWjr9pAW4JAlOZmrML_gaSLxiVJAGlDL5UUxCwWy7bhh18yP6g-Dq22vwt5SS7zTArBLDKo4favOoV5WRDh3FvR4jMELPjLHefVKzX8sbU6CZtEhBk_hdbfFKoHnrJktmECfwKGhTQinTF8TI2YeTFljljrvE7angR7w","place_id":"5a3257a03c1337b505eea8e1f592a17275cd4d28","types":["point_of_interest","restaurant","food","establishment"],"formatted_address":"West Park Station, 17015 Lorain Ave, Cleveland, OH 44111, USA","street_number":"17015","route":"Lorain Ave","zipcode":"44111","city":"Cleveland","state":"Ohio","country":"US","created_at":"2013-11-11T00:52:35.254-08:00","updated_at":"2014-02-17T20:14:33.625-08:00","administrative_level_1":"OH","administrative_level_2":"Cuyahoga","td_linx_code":"2069305","location_id":958,"is_location":false,"price_level":nil,"phone_number":nil,"neighborhoods":nil,"lonlat":"POINT (-81.815863 41.4501339)","do_not_connect_to_api":true,"merged_with_place_id":10527})
  end
end


    Place.find(8893).merge(Place.find(13799))
  end
end
