require_relative "spec_helper"



describe Cli do

  # ------------------------------------------------------------------
  # constants
  cmd = ""

  # ------------------------------------------------------------------
  # framework 
  describe "rspec framework" do
    it "#works" do
      expect( 1 ).to eql( 1 )
    end
  end

  # ------------------------------------------------------------------
  # interface
  describe "interface" do

    before :each do
      @sut = Cli.new
    end

    it "#defines resolve" do
      expect( @sut ).to respond_to( :resolve )
    end

  end

  # ------------------------------------------------------------------
  # help && options
  interfaces = [
               {
                 :command => "resolve",
                 :options => [
                              { :long=>"--log", :short => "-l"},
                              { :long=>"--ssh-config-file", :short => "-c"},
                             ]
               },
               {
                 :command => "reset",
                 :options => [
                              { :long=>"--log", :short => "-l"},
                              { :long=>"--ssh-config-file", :short => "-c"},
                             ]
               },
              ]
    

  interfaces.each do |i|

    describe "help #{i[:command]}" do

      before :all do
        @output = with_captured_stdout { Cli.start(["help", i[:command]]) }
      end

      i[:options].each do |o|

        it "#option short #{o[:short]}" do
          expect( @output ).to match( /#{o[:short]}/ )
        end

        it "#option short #{o[:long]}" do
          expect( @output ).to match( /#{o[:long]}/ )
        end


      end # options

    end

  end # interfaces each


  # ------------------------------------------------------------------
  # resolve
  command =  "resolve"

  describe "command '#{command}'" do

    context  "file" do

      json_file = "spec/cli/fixtures/fixture1.json"

      ssh_config_filename = Cli::DEFAULT_SSH_CONFIG_FILE

      before :each do
        @dbl_ssh_config_file = double( "ssh-config-file" )
        expect( File ).to receive( :open ).with( ssh_config_filename, "w").and_yield( @dbl_ssh_config_file )
        allow( @dbl_ssh_config_file ).to receive( :puts ).with( kind_of( String ))
      end
       

      context "when ':ssh-config-file' does not exist" do

        before :each do
          expect( File ).to receive( :exist? ).with( ssh_config_filename).and_return( false )
          expect( File ).no_to receive( :readlines? ).with( ssh_config_filename )
        end
        
      end # context "when ':ssh-config-file' does not exist" do

      context "when ':ssh-config-file' does exists" do

        before :each do
          @ssh_config_file_lines= [ "line 1", "line2" ]
          expect( File ).to receive( :exist? ).with( ssh_config_filename).and_return( true )
        end


        context "when NO previous resolves" do

          before :each do
            expect( File ).to receive( :readlines ).with( ssh_config_filename).and_return( @ssh_config_file_lines )
          end

          it "writes existing lines to ssh-config file" do
            expect( @dbl_ssh_config_file ).to receive( :puts ).once.with( Cli::MAGIC_START ).ordered
            expect( @dbl_ssh_config_file ).to receive( :puts ).once.with( /^host\s+\w+\s*\n\s*HostName\s+\w?/ ).ordered
            expect( @dbl_ssh_config_file ).to receive( :puts ).once.with( Cli::MAGIC_END ).ordered

            @ssh_config_file_lines.each do |line|
              expect( @dbl_ssh_config_file ).to receive( :puts ).with( line ).ordered
            end

            Cli.start( [command, json_file] )
          end

        end # context "when NO previous resolves" 

        context "when previous resolves" do

          before :each do
            content = [ Cli::MAGIC_START, "old magic", Cli::MAGIC_END ] + @ssh_config_file_lines 
            expect( File ).to receive( :readlines ).with( ssh_config_filename).and_return( content )
          end

          it "removes previous lines between MAGIC_START - MAGIC_END " do

            expect( @dbl_ssh_config_file ).to receive( :puts ).once.with( Cli::MAGIC_START ).ordered
            expect( @dbl_ssh_config_file ).to receive( :puts ).once.with( /^host\s+\w+\s*\n\s*HostName\s+\w?/ ).once.ordered
            expect( @dbl_ssh_config_file ).to receive( :puts ).once.with( Cli::MAGIC_END ).ordered

            @ssh_config_file_lines.each do |line|
              expect( @dbl_ssh_config_file ).to receive( :puts ).with( line ).ordered
            end

            Cli.start( [command, json_file] )
          end


        end  

      end # context "when ':ssh-config-file' does exists" do


      # it "#writes to file" do
      #   
      #   expect( File ).to receive( :read ).with( file ).and_call_original
      #   expect( 1 ).to eql( 1 )
      # end

    end #     context  "file" do

  end #   describe "resolve" do



end
