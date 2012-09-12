require 'rubygems'
require 'rake'
require 'rake/testtask'

def gemspec
  @gemspec ||= begin
    file = File.expand_path("../liangzan-contacts.gemspec", __FILE__)
    eval(File.read(file), binding, file)
  end
end

# Run the unit tests
desc "Run all unit tests"
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

require 'rdoc/task'
Rake::RDocTask.new

begin
  require 'rubygems/package_task'
  Gem::PackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec
  end
  task :gem => :gemspec
rescue LoadError
  task(:gem){abort "`gem install rake` to package gems"}
end

desc "Install the gem locally"
task :install => :gem do
  sh "gem install pkg/#{gemspec.full_name}.gem"
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end
