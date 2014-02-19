require 'rspec/core/rake_task'
require 'pathname'

ROOT = Pathname(__FILE__).parent

load ROOT + "lib/i2c.rb"

warn "I2CDevice::VERSION = #{I2CDevice::VERSION}" 

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :release do
	tags = `git tag`.split(/\n/)
	if tags.include? I2CDevice::VERSION
		raise "Already exist tag #{I2CDevice::VERSION}"
	end
	sh %{gem build i2c-devices.gemspec}
	sh %{gem push i2c-devices-#{I2CDevice::VERSION}.gem}
	sh %{git add -u}
	sh %{git commit -m '#{I2CDevice::VERSION}'}
	sh %{git tag #{I2CDevice::VERSION}}
	sh %{git push}
	sh %{git push --tags}
end
