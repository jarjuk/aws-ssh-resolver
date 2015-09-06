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

  describe "help and options" do

    command =  "help"

    describe "common options" do
      
      before :all do
        @output = with_captured_stdout { Cli.start([command]) }
      end

      it "#Options" do
        expect( @output ).to match( /Options/ )
      end

      it "#outputs -l --log" do
        expect( @output ).to match( /-l.*--log=/ )
      end

    end

    # --------------------
    # resolve
    describe "resolve" do

      task = "resolve"

      before :all do
        @output = with_captured_stdout { Cli.start([command, task]) }
      end

      it "#outputs usage for task" do
        expect( @output ).to match( /Usage:\n.*#{task}/ )
      end

      it "#option --log/-l" do
        expect( @output ).to match( /-l.*--log=/ )
      end

      it "#option ssh-config-file/c" do
        expect( @output ).to match( /-c.*--ssh-config-file=/ )
      end

    end

  end

  # ------------------------------------------------------------------
  # resolve

  describe "resolve" do

    command =  "resolve"


    context  "file" do

      file = "spec/cli/fixtures/fixture1.json"

      before :all do
        @dbl_file = double( "file" )
      end

      it "#works" do
        expect( File ).to receive( :open ).with( Cli::DEFAULT_SSH_CONFIG_FILE, "w").and_return( @dbl_file )
        expect( File ).to receive( :read ).with( file ).and_call_original
        Cli.start([command, file])
        expect( 1 ).to eql( 1 )
      end

    end #     context  "file" do

  end #   describe "resolve" do



end
