require 'thor'
require 'json'
require_relative "../aws-ssh-resolver"

class Cli < Thor

  include Utils::MyLogger     # mix logger
  PROGNAME = "main"           # logger progname

  # ------------------------------------------------------------------
  # constanst
  DEFAULT_SSH_CONFIG_FILE     = "ssh/config.aws"
  DEFAULT_SSH_CONFIG_INIT     = "ssh/config.init"
  MAGIC_START                 = "# +++ aws-ssh-resolver-cli update start here +++"
  MAGIC_END                   = "# +++ aws-ssh-resolver-cli update end here +++"
  DEFAULT_DESCRIBE_INSTANCES  = "aws ec2 describe-instances --filters 'Name=tag-key,Values=Name'"

  # ------------------------------------------------------------------
  # constructore

  def initialize(*args)
    super
    @logger = getLogger( PROGNAME, options )
  end

  # ------------------------------------------------------------------
  # make two thor tasks share options?
  # http://stackoverflow.com/questions/14346285/how-to-make-two-thor-tasks-share-options

  class << self
    def add_shared_option(name, options = {})
      @shared_options = {} if @shared_options.nil?
      @shared_options[name] =  options
    end

    def shared_options(*option_names)
      option_names.each do |option_name|
        opt =  @shared_options[option_name]
        raise "Tried to access shared option '#{option_name}' but it was not previously defined" if opt.nil?
        option option_name, opt
      end
    end
  end

  # # ------------------------------------------------------------------

  class_option :log, :aliases => "-l", :type =>:string, :default => nil, 
  :enum => [ "DEBUG", "INFO", "WARN", "ERROR" ],
  :desc => "Set debug level "

  # ------------------------------------------------------------------

  add_shared_option :ssh_config_file, :type => :string, :default => DEFAULT_SSH_CONFIG_FILE, :aliases => "-c",
  :desc => "OpenSSH config file to update/create"

  add_shared_option :ssh_config_init, :type => :string, :default => DEFAULT_SSH_CONFIG_INIT, :aliases => "-i",
  :desc => "Initialize :ssh-config-file files with this file"


  add_shared_option :describe_instances, :type => :string, :default => DEFAULT_DESCRIBE_INSTANCES, :aliases => "-d",
  :desc => "aws command to query ec2 instances"


  # ------------------------------------------------------------------
  # common instruction
  long_desc_notice_on_ssh_config_init = <<-EOS

     NOTICE: By default ':ssh-config-file' seeded from ':ssh-config-init',
     if it does not exist. Create an empty ':ssh-config-init' file, or 
     pass an empty string to ':ssh-config-init' to avoid an error. 

  EOS


  # ------------------------------------------------------------------
  # resolver

  desc "resolve <json-file>", "Create/update OpenSSH config file with AWS HostNames from a JSON document"


  long_desc <<-LONGDESC

     Updates ':ssh_config_file'  (creates the file if it does not exist) with host/hostname 
     configuration parsed from 'json_file' (defaults to $stdin).

     Entries in ':ssh_config_file' start and end with special tag-lines, which allow the tool
     to replace host/hostanme entries with new values for each run.

     #{long_desc_notice_on_ssh_config_init}

  LONGDESC

  shared_options :ssh_config_file
  shared_options :ssh_config_init

  def resolve( json_file="-" )

    @logger.info( "#{__method__} starting, options '#{options}'" )

    ssh_config_init = options[:ssh_config_init]
    ssh_config_file = options[:ssh_config_file]
    # puts( "options=#{options}" )

    # raw data from aws
    ec2_instances = get_ec2_instances( json_file )
    
    # hash with host => hostname
    host_hostname_mappings = create_host_hostname_mappings( ec2_instances )

    # seed  'ssh_config_file' with 'ssh_config_init'
    init_ssh_config_file( ssh_config_file, ssh_config_init )

    # output to file
    output_to_file(  ssh_config_file, host_hostname_mappings )

    
  end

  # ------------------------------------------------------------------
  # aws-cli
  desc "aws", "Create/update OpenSSH config file with AWS HostNames using aws Commad Line query"

  long_desc <<-LONGDESC
 
     Uses `aws` Command Line Interface to query ec2 information and parse host/hostname 
     information update/create ':ssh_config_file'.

     #{long_desc_notice_on_ssh_config_init}

  LONGDESC

  shared_options :ssh_config_file
  shared_options :ssh_config_init
  shared_options :describe_instances

  def aws()

    ssh_config_file = options[:ssh_config_file]
    ssh_config_init = options[:ssh_config_init]
    describe_instances = options[:describe_instances]

    # run aws-cli query
    ec2_instances = aws_cli_ec2_instances( describe_instances )

    # hash with host => hostname
    host_hostname_mappings = create_host_hostname_mappings( ec2_instances )

    # seed  'ssh_config_file' with 'ssh_config_init'
    init_ssh_config_file( ssh_config_file, ssh_config_init )

    # output to file
    output_to_file(  ssh_config_file, host_hostname_mappings )

  end

  # ------------------------------------------------------------------
  # reset

  desc "reset", "Removes automatic entries in OpenSSH config file"


  long_desc <<-LONGDESC

     Removes automatic entries starting with with special tag-lines from ':ssh_config_file'.

     Delete the file if it becomes empty

  LONGDESC


  shared_options :ssh_config_file

  def reset(  )

    ssh_config_file = options[:ssh_config_file]
    # Read content of (without magic content) ssh_config_file into memory
    ssh_config_file_content = read_ssh_config_file_content_minus_magic( ssh_config_file )
    if ssh_config_file_content.empty? 
      File.delete( ssh_config_file )
    else
      File.open( ssh_config_file, 'w') do |f2|
        ssh_config_file_content.each do |line|
          f2.puts line
        end
      end

    end


  end

  # ------------------------------------------------------------------
  # subrus

  no_commands do

    # return raw ec2 describe-status JSON
    def aws_cli_ec2_instances( describe_instances ) 

      @logger.info( "#{__method__} describe_instances '#{describe_instances}'" )

      json_string = %x{ #{describe_instances} }
      ec2_instances = parse_json( json_string )

      @logger.debug( "#{__method__} describe_instances '#{describe_instances}' --> #{ec2_instances}" )

      return ec2_instances

    end


    # return raw ec2 describe-status JSON
    def get_ec2_instances( file ) 

      @logger.info( "#{__method__} read file '#{file}'" )

      json_string =  ( file == "-" ? $stdin.readlines.join :  File.read(file) )
      ec2_instances = parse_json( json_string )

      @logger.debug( "#{__method__} file '#{file}' --> #{ec2_instances}" )
      return ec2_instances

    end

    def parse_json( json_string ) 

      @logger.debug( "#{__method__} json_string '#{json_string}'" )

      ec2_instances = JSON.parse( json_string  )

      return ec2_instances

    end


    # map raw aws ec2-describe-status json to hash with Host/PublicDnsName props
    def create_host_hostname_mappings( ec2_instances ) 
      host_hostname_mappings = ec2_instances['Reservations']
        .map{ |i| i['Instances'].first }        
        .map{ |i|   { 
          :Host => i['Tags'].select{ |t| t['Key'] == 'Name'}.first['Value'],
          :HostName => i['PublicDnsName'] && !i['PublicDnsName'].empty? ? i['PublicDnsName'] : i['PrivateDnsName']
        } }

      @logger.info( "#{__method__} host_hostname_mappings '#{host_hostname_mappings}'" )
      return host_hostname_mappings
    end

    # add 'host_hostname_mappings' to 'ssh_config_file'
    def output_to_file( ssh_config_file, host_hostname_mappings ) 

      # Read content of (without magic content) ssh_config_file into memory
      ssh_config_file_content = read_ssh_config_file_content_minus_magic( ssh_config_file )

      # write new magic with host entries
      File.open( ssh_config_file, 'w') do |f2|

        f2.puts MAGIC_START
        f2.puts <<-EOS

# Content generated #{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}

        EOS

        host_hostname_mappings.each do |h|
          host_entry = <<EOS
host #{h[:Host]}
    HostName #{h[:HostName]}


EOS
          f2.puts  host_entry
        end

        f2.puts MAGIC_END
        
        ssh_config_file_content.each do |line|
          f2.puts line
        end

      end

    end

    # copy 'ssh_config_init' to 'ssh_config_file' - if it does not
    # exist && 'ssh_config_init' define
    def init_ssh_config_file( ssh_config_file, ssh_config_init ) 
      File.open( ssh_config_file, 'w') { |f| f.write(File.read(ssh_config_init )) } if !File.exist?( ssh_config_file ) && 
        ssh_config_init && !ssh_config_init.empty?
    end

    # read ssh_config from file/$stdin, remove old magic
    def read_ssh_config_file_content_minus_magic( ssh_config_file )

      ssh_config_file_content = File.exist?( ssh_config_file ) ? File.readlines( ssh_config_file ) : []

      # remove old magic
      within_magic = false
      ssh_config_file_content = ssh_config_file_content.select do |line| 
        ret = case within_magic 
              when true
                if line.chomp == MAGIC_END then
                  within_magic = false
                end
                false
              when false
                if line.chomp == MAGIC_START  then
                  within_magic = true
                end
                (line.chomp == MAGIC_START ? false : true)
              end
        ret
      end

      return ssh_config_file_content

    end




  end # no_task




end # class 
