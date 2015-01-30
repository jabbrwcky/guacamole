# -*- encoding : utf-8 -*-
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'rspec/its'
require 'json_expressions/rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end
