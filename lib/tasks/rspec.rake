namespace :spec do

  desc 'Run all specs in spec directory (exluding feature specs)'
  RSpec::Core::RakeTask.new(:nofeatures) do |task|
    file_list = FileList['spec/**/*_spec.rb']
    file_list = file_list.exclude("spec/features/**/*_spec.rb")
    task.pattern = file_list
  end

  desc 'Run all specs in spec directory (exluding feature specs)'
  RSpec::Core::RakeTask.new(:features) do |task|
    file_list = FileList['spec/features/**/*_spec.rb']
    file_list = file_list.exclude("spec/features/**/*_spec.rb")
    task.pattern = file_list
  end
end
