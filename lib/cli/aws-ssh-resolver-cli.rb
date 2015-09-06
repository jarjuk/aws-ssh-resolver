require 'thor'
require 'json'
require_relative "../aws-ssh-resolver"

class Cli < Thor

  include Utils::MyLogger     # mix logger
  PROGNAME = "main"           # logger progname

  # ------------------------------------------------------------------
  # constanst
  DEFAULT_SSH_CONFIG_FILE = "ssh/config.aws"
  MAGIC_START             = "# +++ aws-ssh-resolver-cli update start here +++"
  MAGIC_END               = "# +++ aws-ssh-resolver-cli update end here +++"

  # # ------------------------------------------------------------------

  class_option :log, :aliases => "-l", :type =>:string, :default => nil, 
  :enum => [ "DEBUG", "INFO", "WARN", "ERROR" ],
  :desc => "Set debug level "

  # ------------------------------------------------------------------
  # constructore

  def initialize(*args)
    super
    @logger = getLogger( PROGNAME, options )
  end

  # ------------------------------------------------------------------
  # resolver

  desc "resolve <json-file>", "Create/update OpenSSH config file with AWS HostNames"

  method_option :ssh_config_file, :type => :string, :default => DEFAULT_SSH_CONFIG_FILE, :aliases => "-c",
  :desc => "OpenSSH config file to update/create"


  long_desc <<-LONGDESC

     Updates ':shh_config_file'  (creates the file if it does not exist) with host/hostname 
     configuration.


  LONGDESC

  def resolve( file )

    @logger.info( "#{__method__} starting, options '#{options}'" )


    ssh_config_file = options[:ssh_config_file]
    # puts( "options=#{options}" )

    # raw data from aws
    ec2_instances = get_ec2_instances( file )
    
    # hash with host => hostname
    host_hostname_mappings = create_host_hostname_mappings( ec2_instances )

    # output to file
    output_to_file(  ssh_config_file, host_hostname_mappings )

    
  end

  # ------------------------------------------------------------------
  # subrus

  no_commands do

    # return raw ec2 describe-status JSON
    def get_ec2_instances( file ) 

      @logger.info( "#{__method__} read file '#{file}'" )
      ec2_instances = JSON.parse(File.read(file))

      @logger.debug( "#{__method__} file '#{file}' --> #{ec2_instances}" )
      return ec2_instances

    end

    # map raw aws ec2-describe-status json to hash with Host/PublicDnsName props
    def create_host_hostname_mappings( ec2_instances ) 
      host_hostname_mappings = ec2_instances['Reservations']
        .map{ |i| i['Instances'].first }        
        .select { |i| !i['PublicDnsName'].nil? && !i['PublicDnsName'].empty? }
        .map{ |i|   { 
          :Host => i['Tags'].select{ |t| t['Key'] == 'Name'}.first['Value'],
          :PublicDnsName => i['PublicDnsName']  } }

      @logger.info( "#{__method__} host_hostname_mappings '#{host_hostname_mappings}'" )
      return host_hostname_mappings
    end

    def output_to_file( ssh_config_file, host_hostname_mappings ) 


      # Read content of ssh_config_file into memory
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

      # write new magic with host entries
      File.open( ssh_config_file, 'w') do |f2|

        f2.puts MAGIC_START
        f2.puts <<-EOS

# Content generated #{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}

        EOS

        host_hostname_mappings.each do |h|
          host_entry = <<EOS
host #{h[:Host]}
    HostName #{h[:PublicDnsName]}


EOS
          f2.puts  host_entry
        end

        f2.puts MAGIC_END
        
        ssh_config_file_content.each do |line|
          f2.puts line
        end

      end

    end

  end # no_task



end # class 
