# aws-ssh-resolver - Resolve AWS EC2 HostNames for OpenSSH - $Release:0.0.1-SNAPSHOT$

`aws-ssh-resolver` updates AWS EC2 HostNames in OpenSSH config
file. It can call
[Amazon Command Line Interface](https://aws.amazon.com/cli/) to read
information on EC2 instances from Amazon platform, o


## The Problem

Each EC2 instance launched is allocated a private IP address, and
internal DSN hostname that resolves to this private IP address.
Internal IP address is not reachable over the Internet, nor can the
internal DSN hostname be resolved outside the network the instance is
in.

A instance may be assigned a public IP that allows accessing the
instance from Internet. Each instance that receives a public IP
address is also given an externally resolvable DNS hostname. Normally,
the public IP is taken from Amazon's pool of public IP addresses, and
the IP value used cannot be controlled by user.  Persistent public IP
address that can be associated to and from instances requires using
Amazon's Elastic IP Address (EIP) -service.  

* [Amazon EC2 Instance IP Addressing](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-instance-addressing.html)  a short summary

* private IPO released when the instance is terminated.

* release the public IP address for your instance when it's stopped or
  terminated. Your stopped instance receives a new public IP address
  when it's restarted
  
* release the public IP address for your instance when you associate
  an Elastic IP address with your instance

 * "We resolve an external DNS hostname to the public IP address of
    the instance outside the network of the instance" --> cannot
    change

* EC2 instances without Public IP address cannot be reached directly

* Public IP assigned by Amazon changes, public DNS uncontrollable

* private IP cannot be reached directrly: problemetatic running
  automated test, developer, automatic configuration, SSH tool.



## The Solution

CloudFormation defines name map this name to dns name. SSH connection
multihop.


