require 'spec_helper'

acceptHost = $params['ACCEPT']

describe "Accept node"  do

  # find node uuid
  describe command($rudderCli + " nodes list_pending | jq '.nodes | map(select(.hostname ==\"" + acceptHost + "\" or .hostname ==\"" + acceptHost + ".rudder.local\")) | .[0].id'") do
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
    its(:exit_status) { should eq 0 }
  end

  # accept uuid
  describe command($rudderCli + " nodes accept ") do
    # append uuid to command here because $uuid is not available within describe context
    it { subject.name << $uuid }
    its(:stdout) { should match /"id": "#{$uuid}"/ }
    its(:stdout) { should match /"hostname": "#{acceptHost}/ }
    its(:stdout) { should match /"status": "accepted"/ }
    its(:exit_status) { should eq 0 }
  end

end
