require_relative "../../lib/cli/aws-ssh-resolver-cli"

RSpec.configure do |config|


  # http://stackoverflow.com/questions/14987362/how-can-i-capture-stdout-to-a-string
  def with_captured_stdout
    begin
      old_stdout = $stdout
      $stdout = StringIO.new('','w')
      $stdout.sync = true
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
      $stdout.sync = true
    end
  end


end # RSpec.configure do |config|
