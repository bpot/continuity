$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'continuity'

require 'pry'

RSpec.configure do |config|
  config.before(:each) do
  end
end
