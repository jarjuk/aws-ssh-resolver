# -*- mode: ruby -*-

# ------------------------------------------------------------------
# default

task :default => [:usage]

# ------------------------------------------------------------------
# configs


gem = "aws-ssh-resolver"
document_dir="generated-docs"

# ------------------------------------------------------------------
# usage 

desc "list tasks"
task :usage do
  puts "Tasks: #{(Rake::Task.tasks - [Rake::Task[:usage]]).join(', ')}"
  puts "(type rake -T for more detail)\n\n"
end

# ------------------------------------------------------------------
# Internal development

begin

  require "raketools_site.rb"
  require "raketools_release.rb"
rescue LoadError
  # puts ">>>>> Raketools not loaded, omitting tasks"
end

def version() 
  # gemspec wants to use 'pre' and not '-SNAPSHOT'
  return File.open( "VERSION", "r" ) { |f| f.read }.strip.gsub( "-SNAPSHOT", ".pre" )   # version number from file
end

# ------------------------------------------------------------------
# dev.workflow defined here

namespace "dev" do |ns|

  # ------------------------------------------------------------------
  # unit tests

  namespace :rspec do |ns|


    task :lib, :rspec_opts  do |t, args|
      args.with_defaults(:rspec_opts => "")
      sh "bundle exec rspec --format documentation spec/lib"
    end

    task :cli, :rspec_opts  do |t, args|
      document_file = "#{document_dir}/cli.txt"
      args.with_defaults(:rspec_opts => "")
      sh "bundle exec rspec --format documentation --out #{document_file} spec/cli"
    end

    task :guard do
      sh "bundle exec guard"
    end

  end # ns test

  desc "Run unit tests"  
  task :guard => [ "dev:rspec:guard" ]

  desc "Run unit tests"  
  task :rspec => [ "dev:rspec:lib", "dev:rspec:cli" ]

  # ------------------------------------------------------------------
  # Build && delivery

  desc "Build gempspec"
  task :build do
    sh "gem build #{gem}.gemspec"
  end

  desc "Install locally"
  task :install do
    version = version()
    sh "gem install ./#{gem}-#{version}.gem"
  end

  desc "Push to RubyGems"
  task :push do
    version = version()
    sh "gem push ./#{gem}-#{version}.gem"
  end


end # ns dev
