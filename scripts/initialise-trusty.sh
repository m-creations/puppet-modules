#!/bin/bash

## Usage

function usage () {
    printf "\n\n$0 hostname domainname puppetserver [ puppetmodules-gitrepo ]\n\n"
    printf "Note that you have to use the fqdn for the puppetserver and\n"
    printf "if \$hostname.\$domainname = \$puppetserver then a puppetmaster\n"
    printf "will be set up.\n\n"
    printf "Argument puppetmodules-gitrepo is only necessary if you are setting up\n"
    printf "a puppetmaster\n\n"
}

if [ $# != 4 ] ; then
    usage
    exit 1
fi

## Process command line params

hostname=$1
domainname=$2
puppetserver=$3
puppetmodules_repo=$4

# shall we set up a puppet master?
if [ "$hostname.$domainname" == "$puppetserver" ] ; then
    is_puppetmaster=1
else
    is_puppetmaster=0
fi

## Install git and etckeeper

apt-get install -y git-core
git config --global user.name "Root on $hostname"
git config --global user.email "root@$hostname.$domainname"
apt-get install -y etckeeper
sed -i -e 's/^VCS="bzr"/#VCS="bzr"/' /etc/etckeeper/etckeeper.conf
sed -i -e 's/^#VCS="git"/VCS="git"/' /etc/etckeeper/etckeeper.conf
etckeeper init
etckeeper commit "Initial revision"

apt-get install -y facter emacs24-nox screen

## Check for correct OS and version

os=`facter operatingsystem`
osrelease=`facter operatingsystemrelease`

if [ "$os" != "Ubuntu" ] ; then
  printf "\n\n ##### ERROR: this script only supports Ubuntu\n\n"
  exit 1
fi

if [ "$osrelease" != "14.04" ] ; then
  printf "\n\n ##### ERROR: this script only supports Ubuntu 14.04\n\n"
  exit 2
fi

## Set up the host and domain name

hostname $hostname
ipaddress=`facter ipaddress`
ipaddress6=`facter ipaddress6`
sed -ie "s/$ipaddress.*/$ipaddress $hostname.$domainname $hostname/" /etc/hosts
sed -ie "s/$ipaddress6.*/$ipaddress6 $hostname.$domainname $hostname/" /etc/hosts

## Install puppet and/or puppetmaster

if [ "$is_puppetmaster" = "1" ] ; then
    printf "\nYou want this server to be the puppetmaster. Will do ...\n"
    apt-get install -y puppetmaster puppet puppet-el

    # clone the puppet modules
    git clone $puppetmodules_repo /etc/puppet/modules/

    printf "\ndone.\n\nPlease create an /etc/puppet/manifests/site.pp file.\n\n"
else
    printf "\nSetting up this server as a puppet client node ...\n"
    apt-get install -y puppet

    printf "\ndone.\n\n"
    printf "Please go to the puppet master ($puppetserver) and sign the certificate of this host:\n\n"
    printf "root@${puppetserver}> puppet ca list\n\n"
    printf "  ${hostname} (SHA256) ....\n\n"
    printf "root@${puppetserver}> puppet ca sign $hostname.$domainname\n\n"
    printf "  Notice: Signed certificate request for $hostname.$domainname\n\n"
    printf "Then you can add this host to the nodes which are managed on the\n"
    printf "puppet master and configure it.\n\n"
fi

## Configure the correct puppet server name for puppet agent

sed -ie "s/\[main\]/[main]\nserver=$puppetserver/g" /etc/puppet/puppet.conf

# Local Variables:
# mode: shell-script
# indent-tabs-mode: nil
# outline-regexp: "^##+ "
# outline-heading-end-regexp: "\n"
# End:
