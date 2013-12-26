# Google PLACES api key
if Rails.env.development? or Rails.env.test?
  GOOGLE_API_KEY = 'AIzaSyAdudSZ-xD-ZwC-2eYxos3-7U69l_Seg44'
else
  GOOGLE_API_KEY='AIzaSyCdlLQPfIj9Ekiszj2HuTb6CNZz0zGirD0'
end