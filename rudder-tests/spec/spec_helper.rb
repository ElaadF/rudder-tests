require 'serverspec'
require 'net/ssh'
require 'json'
require 'resources/api_call'
require 'resources/agent_run'
require 'formatters/junit_formatter'

host = ENV['TARGET_HOST']
datastate_path = ENV['DATASTATE']
$rudderToken = ENV['TOKEN']

# Some common rudder test elements
$params = {}
ENV.each { |key, value|
  if key.start_with?("RUDDER_")
    key2 = key[7..-1]
    $params[key2] = value
  end
}

file = File.open datastate_path
data = JSON.load file

$servers = data.select {|key, value| value.fetch("role", "none") == "server"}
$rudderUrl = $servers.first[1]["webapp_url"] || "undefined_url"

if host == "localhost"
  set :backend, :exec
  set :host, host
  set :disable_sudo, true
else
  set :backend, :ssh

  options = Net::SSH::Config.for(host)

  options[:user] = data[host]["ssh_user"]
  options[:port] = data[host]["ssh_port"]
  options[:keys_only] = true
  options[:auth_methods] = ["publickey"]

  # keys are an array of path
  options[:keys] = [data[host]["ssh_cred"]]
  # hostname can be different than the actual ip where to ssh
  set :host,        options[:host_name] || data[host]["ip"]
  set :ssh_options, options
end

# Set environment variables
set :env, :LANG => 'C', :LC_MESSAGES => 'C'

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'


RSpec.configure do |c|
  c.output_stream = File.open('serverspec-result.xml', 'w')
  c.formatter = 'JUnit'
end
