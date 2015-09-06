require 'logger'

# see http://hawkins.io/2013/08/using-the-ruby-logger/

module Utils

  module MyLogger

    # no logging done

    class NullLoger < Logger
      def initialize(*args)
      end

      def add(*args, &block)
      end
    end

    LOGFILE="aws-ssh-resolver.log"

    def getLogger( progname, options={} ) 

      level = get_level( options )

      if level.nil? 

        return NullLoger.new 

      else
        
        logger = Logger.new( LOGFILE )
        logger.level=level
        logger.progname = progname
        return logger

      end 

    end # getLogger

    # ------------------------------------------------------------------
    private

    def get_level( options ) 

      # puts  "#{__method__}: options=#{options}" 

      level_name = options && options[:log] ? options[:log] : ENV['LOG_LEVEL']

      level = case  level_name
              when 'warn', 'WARN'
                Logger::WARN
              when 'info', 'INFO'
                Logger::INFO
              when 'debug', 'DEBUG'
                Logger::DEBUG
              when 'error', 'ERROR'
                Logger::ERROR
              else
                nil
              end

      return level
    end



  end
  

end 
