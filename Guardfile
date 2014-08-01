# A sample Guardfile
# More info at https://github.com/guard/guard#readme

interactor :off

guard 'livereload' do
  watch(%r{public/.+\.(css|js|html)})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|html|png|jpg))).*}) { |m| "/assets/#{m[3]}" }
end