attributes :rating, :text

node(:time) { |comment| DateTime.strptime(comment.time.to_s, '%s') }

attributes :author_name