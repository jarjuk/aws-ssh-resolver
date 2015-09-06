# -*- mode: ruby -*-

# ------------------------------------------------------------------
# default

task :default => [:usage]

# ------------------------------------------------------------------
# configs


gem = "aws-ssh-resolver"

# ------------------------------------------------------------------
# usage 

desc "list tasks"
task :usage do
  puts "Tasks: #{(Rake::Task.tasks - [Rake::Task[:usage]]).join(', ')}"
  puts "(type rake -T for more detail)\n\n"
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
      args.with_defaults(:rspec_opts => "")
      sh "bundle exec rspec --format documentation spec/cli"
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
