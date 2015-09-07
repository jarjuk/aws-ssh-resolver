# -*- mode: ruby -*-


guard :rspec, cmd: 'bundle exec rspec'  do

  # TestSuites
  watch(%r{^spec/lib/.+_spec\.rb$})
  watch(%r{^lib/.+/(.+)\.rb$})                                  { |m| "spec/lib/#{m[1]}_spec.rb" }
  
  watch(%r{^spec/cli/.+_spec\.rb$})
  watch(%r{^lib/cli/(.+)\.rb$})                                 { |m| "spec/cli/#{m[1]}_spec.rb" }
  

end
