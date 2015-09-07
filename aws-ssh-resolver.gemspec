# -*- encoding: utf-8; mode: ruby -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 

# http://guides.rubygems.org/make-your-own-gem/

Gem::Specification.new do |s|

  # version           = "0.0.1.pre"
  version           = File.open( "VERSION", "r" ) { |f| f.read }.strip.gsub( "-SNAPSHOT", ".pre" )

  s.name            = 'aws-ssh-resolver'
  s.version         = version
  s.date            = Time.now.strftime( "%Y-%m-%d" )  #'2014-09-10'
  s.summary         = "Update OpenSSH config with CloudFormation EC2 instance DNS names'"
  s.description     = <<EOF
  Update OpenSSH config file to map EC2 instance name in CloudFormation
  to DNS-name on Amazon platform.
EOF

  s.authors         = ["jarjuk"]
  s.require_paths   = [ "lib" ]
  s.license         = 'MIT'


  s.homepage        = "https://github.com/jarjuk/aws-ssh-resolver"
  s.files           = ["README.md"] | Dir.glob("lib/**/*")  |  Dir.glob("spec/**/*")  | Dir.glob("bin/**/*") 

  s.bindir          = 'bin'
  s.executables     = [ "aws-ssh-resolver.rb" ]

  s.required_ruby_version = '~> 2'

  s.add_runtime_dependency 'thor',              '~>0.18'
  s.add_runtime_dependency 'json'

end
