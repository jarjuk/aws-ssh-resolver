# aws-ssh-resolver - Resolve AWS EC2 HostNames for OpenSSH configuration - $Release:0.0.4-SNAPSHOT$

`aws-ssh-resolver` keeps AWS EC2 HostNames in OpenSSH configuration
file in sync with Amazon cloud making it easier for to use OpenSSH,
and related tools, on Amazon Platform.

## The Problem

[Amazon EC2 Instance IP Addressing](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-instance-addressing.html)
sets several challenges for SSH usage, and for any tool using SSH
connections e.g.  [ansible](http://www.ansible.com/home),
[fabric](http://www.fabfile.org/),
[serverspec](http://serverspec.org/) etc.

* Amazon Public DNS Names encode Public IP Addresses. Each time an
  instance is assigned a new IP address, it also gets a new Public DNS
  name. In essence this means that the task of managing DNS names
  becomes comparable to the task of managing IP addresses.

* Using an IP address to contact an instance is complicated, because
  Public IP Address, once released, cannot be reused. Using fixed IP
  addresses requires keeping track of reserved address, and comes with
  extra costs.

* EC2 instances, with only a Private IP Address, cannot be reached
  directly from the Internet.

* Private DNS names also encode the IP address they map to. On top of
  that, Private DNS names cannot resolved outside the cloud network.

## The Solution

[aws-ssh-resolver](https://github.com/jarjuk/aws-ssh-resolver)
addresses the challenges above 

* It accepts output of
   [Amazon Command Line Interface](https://aws.amazon.com/cli/) to
   create
   [OpenSSH Configuration](http://www.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man5/ssh_config.5?query=ssh_config&sec=5)
   entries mapping persistent, and human-understandable, EC2 Tag names
   to mutable EC2 DNS names.
   
* Tag-name/DNS name mapping can be updated to reflect current cloud
   configuration.

* Tag-name/DNS mapping together with
    [ProxyCommand with Netcat](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts#ProxyCommand_with_Netcat)
    configuration in OpenSSH allows users to create a transparent
    multihop SSH connection to EC2 instances with Private IP Address
    only

For more background information, see
[blog post](https://jarjuk.wordpress.com/2015/09/08/using-openssh-on-aws-platform/#more-273https://jarjuk.wordpress.com/2015/09/08/using-openssh-on-aws-platform/#more-273).

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

**Notice**: The first **aws-ssh-resolver** run creates the initial
version of `ssh/config.aws` automatically using `ssh/config.init`, if
`ssh/config.aws` -file does not exist, . This avoids the need to check
in the mutable `ssh/config.aws` into a version control system.

### Update OpenSSH Configuration file

To update OpenSSH configuration with EC2 Tag/DNS mappings pipe the
result of `aws ec2 describe-instances` to **aws-ssh-resolver**
command:

	aws ec2 describe-instances |  bundle exec aws-ssh-resolver.rb resolve

The command extracts EC2 Tag/DNS information, and writes
`host`/`HostName` configuration entries in `ssh/config.aws` -file.  In
this file `host` value is taken from `Name` tag on an EC2 instance,
and `HostName` value is taken from `PublicDnsName` on an EC2
instance. If `PublicDnsName` is not defined, the command uses
`PrivateDnsName` instead.

When the network topology changes, i.e. an instance gets a new IP
address, an instance is terminated, or a new instance is launched,
rerun the command again to update content in `ssh/config.aws` to
reflect the new situation.

## An Example

### Example Setup

The example uses two Ubuntu EC2 instances with `Name` -tags `myFront`
and `myBack1`. Instance `myFront` has an internal IP
`10.0.0.246`. Instances on subnet `10.0.0.0/24` can be reached over
Internet, and `myFront` has been assigned a public IP `52.19.117.227`,
and an externally resolvable DNS name
`c2-52-19-117-227.eu-west-1.compute.amazonaws.com`. Instance `myBack1`
belongs to private subnet `10.0.1.0/24`, and cannot reached directly
from Internet. It has a private IP address `10.0.1.242` with a DNS
name `ip-10-0-1-242.eu-west-1.compute.internal`. Both of these
instances have been created using
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

    Host *.compute.internal 
	   ProxyCommand ssh myFront1 -F ssh/config.aws nc -q0 %h 22

    Host *
         user ubuntu
         StrictHostKeyChecking no
         UserKnownHostsFile=/dev/null
         IdentityFile ~/.ssh/demo-key/demo-key

This configuration instructs OpenSSH to use user name `ubuntu` and SSH
private key in `~/.ssh/demo-key/demo-key` for all SSH connections.

Amazon assigns DNS names ending with `compute.internal` to map to
Private IP address. The configuration tells OpenSSH to use `myFront1`
as a proxy to connect to instances with Private DNS name.


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

    Host *
         user ubuntu
         StrictHostKeyChecking no
         UserKnownHostsFile=/dev/null
         IdentityFile ~/.ssh/demo-key/demo-key
		 
This configuration adds the host definition for `myFront1`, and
instructs OpenSSH to use a Public DNS name to connect the instance.

The HostName for `myBack1` ends with `compute.internal`, and the
OpenSSH uses the proxy definition to access it.

### Using OpenSSH Configuration to Access ASW Instances

The configuration in `ssh/config.aws` allows us to use tag name
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
