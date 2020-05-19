rudder-tests
============

Automatic tests repository

To run Rudder Test Framework, first prepare the needed tools:
- checkout https://github.com/Normation/rudder-tests
- install rudder-cli (checkout https://github.com/Normation/rudder-api-client and type ./build.sh in its lib.python)
- make a link to rudder api client : ln -s ~/repos/rudder-api-client
- install ruby 2
- install jq
- install serverspec http://serverspec.org/ (gem install serverspec)
- install docopt, requests, pexpect and urllib3 python modules (pip install docopt requests pexpect urllib3)
- install the vagrant-scp plugin (vagrant plugin install vagrant-scp)
- install the vagrant-disksize plugin (vagrant plugin install vagrant-disksize)

Additionally you can do this to get better performances:
- have vagrant >= 1.8 (to be able to clone VM)
- run vagrant plugin install vagrant-cachier (to have a cache for packages)

Run the desired test platform:
- ./rtf platform setup debian 

Run a test scenario:
- ./rtf scenario run debian base


rtf documentation
-----------------
        ./rtf --help
        
        Rudder test framework
        
        Usage:
            rtf platform list
            rtf platform status <platform>
            rtf platform setup <platform> [<version>]
            rtf platform destroy <platform>
            rtf platform update-rudder <platform> <version>
            rtf platform update-os <platform> <version>
            rtf host list <platform>
            rtf host update-rudder <host> <version>
            rtf host update-os <host> <version>
            rtf scenario list
            rtf scenario run <platform> <scenario> [--no-finally] [--filter=<test1>,<test2>,...] [--format=<format>]
        
          Options:
            --no-finally       Do not run tests tagged FINALLY in the scenario, to avoid coming back to initial state
            --filter=...       Only run provided test list from scenario
            --format=<format>  Output format to use (progress, documentation, html or json) [Default: documentation]


Writing tests
-------------
Tests are in spec/tests/

Just copy an existing test, and it can be used.

- Tests are serverspec files. They use a common code that can be found in spec/spec_helper.rb.
- Test parameters are provided vira environment_variables. Environment variables named RUDDER_* are already parsed into a global array named $params
- Tests consist of examples that are executed in order and their result is checked using rspec syntax
- Examples should be ressource types from serverspec: http://serverspec.org/resource_types.html
- Access to rudder api is provided by a prepared command line in the variable $rcli (equivalent to calling ./rudder-cli in rudder-api-client) 
- Tests should use parameters to not be specific to a scenario


Writing a scenario
------------------
Scenarii are in scenario/

A scenario is a list of commands to run tests in order with parameters.

A typical scenario:
        from scenario.lib import *
        start()
        run('hostname', 'test', Err.CONTINUE, PARAM=value)
        ...
        finish()

- Scenarii are python modules
- A global variable called scenario contains all necessary informations to run the scenario
- Some functions are available to help running tests, they are in scenario/lib.py
- Each tests has an error mode that tells what to do in case of error 
  - CONTINUE: continue testing even if this fail, should ne the default
  - BREAK: stop the scenario if this fail, for tests that change a state
  - FINALLY: always run this test, for leaning after a scenario, broken or not
- You can include a scenario from another one, just call import scenario.subscenario within your scenario
- Some methods are provided to iterate a test over current platform nodes 

Writing a technique test
------------------------

Technique tests use a special scenario to test a technique. The are localed in the technique folder,
in a `tests` directory, containing:

- `my_test.metadata`: The main file, in JSON, containing information about the test, for example the global compliance and the paths of other test files.
- `my_test.json`: The directive parameters for the test.
- `my_test.rb`: The serverspec file containing the actual test. It should check if the directive was correctly applied.
- `my_test.cf`(optionnal): A CFEngine policy to enforce before starting the test, to prepare the environement.

This content can be generated from an existing directive, using:

`rtf test from-directive <platform> <directiveid> <test_name> <destination_path>`

Adding a platform or an OS
--------------------------
OS are based on atlas vagrant boxes https://atlas.hashicorp.com/boxes/search?vagrantcloud=1
To add a new box, just add a varianble in the existing list in vagrant.rb

Platforms are in platforms/

- Platforms are a list of vm with a configuration that are related in a scenario.
- Platforms are described in json format
- A scenario may have some dependency on a platform content such as host types and names
- The "default" entry in inherited by all other entries
- The "plugins" entry is used to define the plugins that will be installed on the platform server, currently only available for the Rudder dev team.
- Each entry is a node name
- A node name should be "server" or "agentX", this is an assumption in some scenario and in the cleanbox initialization script
- "rudder-setup" describe the type of setup, currently only "agent" and "server" are supported
- "system" is one of the variable of known boxes from vagrant.rb
- "osname" is a substring of the OS name that is discovered by fusion (this is used by the fusion test)
- "provision" empty by default, define the script source to provision the vm, currently only "python" is supported
- "sync_file" folder path (without trailing "/") to deposit script files used in provisioning. If not set, vagrant will use the shared-files to upload the files

```json
{
  "default": { "run-with": "vagrant", "rudder-version": "5.0", "system": "debian9", "inventory-os": "debian" },
  "plugins": { "branding": "1.3", "notify": "1.0" },
  "server" : { "rudder-setup": "server", "sync_file": "/tmp/install" }
}
```

Using libvirt provider with rtf
--------------------------
You need to install several vagrant plugins to use libvirt (vagrant plugin install *plugin-name*): 
- vagrant-libvirt (Support of libvirt as provider)
- vagrant-mutate (To transform virtualbox boxes to libvirt format)

Unless the box is available on Atlas with libvirt provider, You will need to add boxes before lauching your tests:
```
vagrant box add <box-name>
vagrant mutate <box-name> libvirt
```
Some boxes (specially centos 7.2) do not work with vagrant 1.8.3, downgrading to vagrant 1.8.1 fixes the issue

You can then define you are using libivrt as provider by two ways:
- Defining key provider in your "default" section in your platform
- Running platform setup this way: ./rtf platform setup *platform-name*  provider=libvirt


Adding a new host format
------------------------
Everything on host is done through the Host class in rtf.

The only Host class is currently Vagrant. To implement the support of a new format you should create a new class implementing the same methods as Vagrant and deplare it in the host_types variable.


Using dev environment
------------------------

It's possible to create a development environment with rtf.
We provide a platform to launch your environment, just run: 
```
./rtf platform setup dev
```
You can also add a dev server to any platform by setting it's "rudder-setup" parameter to "dev-server" (like we do in dev.json)

To use the provided configuration file in your Eclipse/IntelliJ/IDE of your choice, just add this line the project run configuration arguments:
```
-Drudder.configFile=<path-to-rudder-tests>/dev/configuration.properties
```

You will also need:
- techniques in /var/rudder/configuration-repository/techniques, writable by the user running Java
- init a git repository in /var/rudder/configuration-repository
```
cd /var/rudder/configuration-repository
git init
git add .
git commit -m "Initial commit"
```
- /var/log/rudder/core/ and /var/log/rudder/webapps folder writable by the user running Java

Using aws to provide hosts
------------------------

It is possible to use rtf with aws. It requires the aws plugin.
```
# The aws plugin available via direct plugin install is wayyy to old (0.0.1) so you must build it (now 0.7.1)
git clone https://github.com/mitchellh/vagrant-aws.git
cd vagrant-aws
apt-get install rake bundler
vi Gemfile # comment last 3 lines referencing vagrant-aws gem
bundle install --path vendor/bundle
rake build
vagrant plugin install pkg/vagrant-aws-*.gem
vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
```

Install and configure aws cli: see https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
```
apt install awscli
aws configure
```

Configure VPC: 
- Create a VPC
- Give it one subnet (note the id)
- Give it one internet gateway
- Edit the subnet routing table to route default route through the gateway
Configure a security group (note the id):
- Allow https and ssh from outside: TCP:22, TCP:80, TCP:443
- Allow syslog, and cfengine from inside: previous ones + TCP/UDP:514 TCP:5309
Create a key pair (note the name):
- store the pem on your machine

Configure the parameters at the top of the Vagrantfile:
```
# name of your ssh keypair
$AWS_KEYNAME='rtf-XXX'
# Path of the private key file
$AWS_KEYPATH="rtf-XXX.pem"
# Subnet id in the VPC (id, not name)
$AWS_SUBNET='subnet-0760ec7afa0c7448e'
# Security group id in the VPC (id not name)
$AWS_SECURITY_GROUP='sg-062906d71ed329ae8'
```

You can now use rtf with aws as you usually do with virtualbox.


Useful Knowledge
------------------------

The IP addr used for the VMs can be set in the Vagrantfile by defining the variable NET_PREFIX. To make the first IP of your Vagrantfile start at 192.168.90.0 add:
```
$NET_PREFIX = 90
```
Each new platform will then start at 192.168.($NET_PREFIX+platform_id). This is not retro-compatible with older Vagrantfiles.
