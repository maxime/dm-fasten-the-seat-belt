require 'rubygems'
require 'rake/gempackagetask'
require 'spec'
require 'spec/rake/spectask'
require 'pathname'

ROOT = Pathname(__FILE__).dirname.expand_path
require ROOT + 'lib/dm-fasten-the-seat-belt/fasten-the-seat-belt/version'

PLUGIN = "dm-fasten-the-seat-belt"
PROJECT_NAME = NAME = "dm-fasten-the-seat-belt"
AUTHOR = "Maxime Guilbot"
EMAIL = "maxime [a] ekohe [d] com"
HOMEPAGE = PROJECT_URL = "http://github.com/maxime/dm-fasten-the-seat-belt"
SUMMARY = PROJECT_DESCRIPTION = PROJECT_SUMMARY = "A new merb plugin for adding image and file upload storage capabilities"
GEM_VERSION = DataMapper::FastenTheSeatBelt::VERSION
GEM_DEPENDENCIES = [["dm-core", GEM_VERSION], ["mini_magick", ">=1.2.3"]]
GEM_CLEAN = ["log", "pkg"]
GEM_EXTRAS = { :has_rdoc => true, :extra_rdoc_files => %w[ README.txt LICENSE TODO ] }

GEM_NAME = "dm-fasten-the-seat-belt"

require 'tasks/hoe'

task :default => [ :spec ]

WIN32 = (RUBY_PLATFORM =~ /win32|mingw|cygwin/) rescue nil
SUDO  = WIN32 ? '' : ('sudo' unless ENV['SUDOLESS'])

desc "Install #{GEM_NAME} #{GEM_VERSION}"
task :install => [ :package ] do
  sh "#{SUDO} gem install --local pkg/#{GEM_NAME}-#{GEM_VERSION} --no-update-sources", :verbose => false
end

desc "Uninstall #{GEM_NAME} #{GEM_VERSION} (default ruby)"
task :uninstall => [ :clobber ] do
  sh "#{SUDO} gem uninstall #{GEM_NAME} -v#{GEM_VERSION} -I -x", :verbose => false
end

desc 'Run specifications'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
  t.spec_files = Pathname.glob((ROOT + 'spec/**/*_spec.rb').to_s)
  
  begin
    t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
    t.rcov_opts << "--exclude 'config,spec,#{Gem::path.join(',')}'"
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
  rescue Exception
    # rcov not installed
  end
end
