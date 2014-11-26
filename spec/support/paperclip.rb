# Taken from here:
# http://dev.mensfeld.pl/2013/11/paperclip-and-rspec-stubbing-paperclip-imagemagick-to-make-specs-run-faster-but-with-image-resolution-validation/comment-page-1/#comment-2202
# as an attempt to make the tests to run faster
module Paperclip
  def self.run(cmd, arguments = '', interpolation_values = {}, local_options = {})
    cmd == 'convert' ? nil : super
  end
end

class Paperclip::Attachment
  def post_process
  end
end
