# coding: utf-8
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'i2c'

Gem::Specification.new do |s|
	s.name          = 'i2c-devices'
	s.version       = I2CDevice::VERSION
	s.date          = '2014-02-15'
	s.summary       = "i2c device drivers"
	s.description   = "i2c-devices is a drivers for i2c devices"
	s.authors       = ["cho45"]
	s.email         = 'cho45@lowreal.net'
	s.files         = `git ls-files`.split($/)
	s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	s.test_files    = s.files.grep(%r{^(test|spec|features)/})
	s.homepage      = 'https://github.com/cho45/ruby-i2c-devices'
	s.license       = 'MIT'
	s.require_paths = ["lib"]
	s.extra_rdoc_files = ['README.md']
	s.rdoc_options << '--main' << 'README.md'

	s.add_development_dependency "bundler", "~> 1.5"
	s.add_development_dependency "rake"
end
