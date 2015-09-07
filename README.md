# aws-ssh-resolver - Resolve AWS EC2 HostNames for OpenSSH configuration - $Release:0.0.2-SNAPSHOT$

`aws-ssh-resolver` keeps AWS EC2 HostNames in OpenSSH configuration
file in sync with Amazon cloud making it easier for a user to use
OpenSSH, and related tools, on Amazon Platform.

## The Problem

[Amazon EC2 Instance IP Addressing](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-instance-addressing.html)
  documents, how every EC2 instance is associated a private IP, which
  cannot be reached directly from the Internet. Together with the
  Private IP comes also a DNS hostname, which can be resolved only on
  the network that the instance is in.  An instance may be assigned a
  Public IP Address, accessible from the Internet, and a corresponding
  Public DNS name, resolvable outside the network of the instance.
  Public IPs come Amazon's pool of public IP address, and an instance
  may not reuse the IP address, once it is released. For example,
  stopping, or terminating, an instance releases the Public IP
  Address.

Amazon EC2 Instance IP Addressing brings about several challenges for
SSH users, or any related tool [ansible](http://www.ansible.com/home),
[fabric](http://www.fabfile.org/),
[serverspec](http://serverspec.org/) etc.

1. Public DNS Name encodes the Public IP Address, and does not
   actually ease that much humans in identifying instances.

2. Accessing an instance becomes complicated, because Public IP
   Address, once released, cannot be reused. Using fixed IP addresses
   brings about the need to manage IP address in an address pool, and
   comes with extra costs.

3. EC2 instances, with only a Private IP Address, cannot be reached
   directly from the Internet.

4. Private DNS names also encode the IP address they map to. On top of
   that, they cannot be resolved outside the cloud network.

## The Solution

The solutions, offered by
[aws-ssh-resolver](https://github.com/jarjuk/aws-ssh-resolver)

1. extract a name, which can be easily memorized by humans from an EC2
   instance Tag information, and map that name to the Public DNS Name
   of the instance

2. allow the Tag-name - DNS name mapping to the updated

3. Support
    [ProxyCommand with Netcat](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts#ProxyCommand_with_Netcat)
    configuration in OpenSSH allowing users to create a transparent
    multihop SSH connection to EC2 instances with Private IP Address
    only

4. "Do You Remember"/"It All Starts With One": the Tag-name/DNS name
   mapping is used also for EC2 instances with Private IP Address only

## Usage

### Installation

Add following lines to `Gemfile`

    source 'https://rubygems.org'
	gem 'aws-ssh-resolver'

and run

	bundle install

### Configuration

Create an initial
[OpenSSH Configuration](http://www.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man5/ssh_config.5?query=ssh_config&sec=5)
file `ssh/config.aws` with any fixed configuration.  Running
**aws-ssh-resolver** updates this file, but does not interfere with
the content user has entered.

**Notice**: If `ssh/config.aws` -file does not exist, the first
 **aws-ssh-resolver** run creates the initial version of
 `ssh/config.aws` automatically using `ssh/config.init`.  This avoids
 the need to check in the mutable `ssh/config.aws` into a version
 control system system.

### Update OpenSSH Configuration file

To updates `ssh/config.aws` with `host` entries for EC2 instances pipe
the result of `aws ec2 describe-instances` to
**aws-ssh-resolver**. For example

	aws ec2 describe-instances |  bundle exec aws-ssh-resolver.rb resolve

The command above creates host entries in `ssh/config.aws` -file. In
this file, `host` values are taken from `Name` tags on EC2 instances,
and `HostName` values are taken from `PublicDnsName` on EC2
instances. If `PublicDnsName` is not defined, use `PrivateDnsName`
instead.

When the network topology changes, i.e. an instance gets a new IP
address, an instance is terminated, or a new instance is launched,
rerun the command to update content in `ssh/config.aws` to reflect the
new situation.

## An Example

### Example Setup

The example uses two Ubuntu EC2 instances with `Name` -tags `myFront`
and `myBack1`. Instance `myFront` has an internal IP
`10.0.0.246`. Instances on subnet `10.0.0.0/24` can be reached over
Internet, and `myFront` has been assigned a public IP 52.19.117.227
and an externally resolvable DNS name
`c2-52-19-117-227.eu-west-1.compute.amazonaws.com`. Instance `myBack1`
belongs to private subnet `10.0.1.0/24`, and cannot reached directly
from Internet. It has a private IP address 10.0.1.242 with a DNS name
`ip-10-0-1-242.eu-west-1.compute.internal`. Both of these instances
have been created using
[Amazon EC2 Key Pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
`demo_key`.


    +----------------------------------------------------------------+
    | Tags: [ "Name": "myFront" ], Ubuntu 14.04 LTS Trusty           |
    | 52.19.117.227/c2-52-19-117-227.eu-west-1.compute.amazonaws.com |
    | 10.0.0.246/ip-10-0-0-246.eu-west-1.compute.internal            |
	! 10.0.0.0/24                                                    |
    | .ssh/demo_key.pub                                              |
    +----------------------------------------------------------------+

    +----------------------------------------------------------------+
    | Tags: [ "Name": "myBack1" ], Ubuntu 14.04 LTS Trusty           |
    |                                                                |
    |10.0.1.242//ip-10-0-1-242.eu-west-1.compute.internal            |
    |10.0.1.0/24                                                     |
    |.ssh/demo_key.pub                                               |
    +----------------------------------------------------------------+


### Initial Configuration

We start by creating `ssh/config.aws` configuration file with the
following initial content

    Host *.compute.internal ProxyCommand ssh myFront1 -F
         ssh/config.aws nc -q0 %h 22

    Host *.compute.amazonaws.com

    Host *
         user ubuntu
         StrictHostKeyChecking no
         UserKnownHostsFile=/dev/null
         IdentityFile ~/.ssh/demo-key/demo-key

### Read Network Topology, and Update OpenSSH Configuration

Running command

	aws ec2 describe-instances |  bundle exec aws-ssh-resolver.rb resolve

reads EC2 information from Amazon platform, extracts `Name` tags and
DNS names, and updates `ssh/config.aws` with `host` and `HostName`
information as shown below:

    # +++ aws-ssh-resolver-cli update start here +++

    # Content generated 2015-09-06-21:57:37

    host myFront1
        HostName ec2-52-19-117-227.eu-west-1.compute.amazonaws.com


    host myBack1
        HostName ip-10-0-1-242.eu-west-1.compute.internal


    # +++ aws-ssh-resolver-cli update end here +++
    Host *.compute.internal
         ProxyCommand ssh myFront1 -F ssh/config.aws nc -q0 %h 22

    Host *.compute.amazonaws.com

    Host *
         user ubuntu
         StrictHostKeyChecking no
         UserKnownHostsFile=/dev/null
         IdentityFile ~/.ssh/demo-key/demo-key

### Using OpenSSH Configuration to Access ASW Instances

The configuration in `ssh/configaws` allows us to use tag name
`myFront1` to make a SSH connection to machine with the DNS name
`c2-52-19-117-227.eu-west-1.compute.amazonaws.com` simply with command

	ssh myFront1 -F ssh/config.aws
	Warning: Permanently added 'ec2-52-19-117-227.eu-west-1.compute.amazonaws.com,52.19.117.227' (ECDSA) to the list of known hosts.


The instance on subnet `10.0.1.0/24` cannot reached directly, and the
configuration instructs OpenSSH to use `myFront` as a intermediary to
create a
[transparent ssh connection](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts#ProxyCommand_with_Netcat)
to `myBack1`. This all takes place transparently, and the simple
command

	ssh myBack1 -F ssh/config.aws
	Warning: Permanently added 'ec2-52-19-117-227.eu-west-1.compute.amazonaws.com,52.19.117.227' (ECDSA) to the list of known hosts.
	Warning: Permanently added 'ip-10-0-1-242.eu-west-1.compute.internal' (ECDSA) to the list of known hosts.

creates a SSH connection to `myBack1`.

Warnings shown above, are due to parameters `UserKnownHostsFile` and
`StrictHostKeyChecking`, which prevent ssh from updating the default
`.ssh/known_hosts` file with the fingerprints of the (temporary)
instances used in testing.


### Updating OpenSSH Configuration

If the network configuration changes, rerunning

	aws ec2 describe-instances |  bundle exec aws-ssh-resolver.rb resolve

refreshes configuration in `ssh/config.aws`.

## Changes

See [RELEASES](RELEASES.md)

## License

MIT
