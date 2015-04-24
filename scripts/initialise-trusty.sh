#!/bin/bash

apt-get install -y git-core
git config --global user.name "Root on $hostname"
git config --global user.email "root@$hostname.$domainname"
apt-get install -y etckeeper facter emacs24-nox screen
sed -i -e 's/^VCS="bzr"/#VCS="bzr"/' /etc/etckeeper/etckeeper.conf
sed -i -e 's/^#VCS="git"/VCS="git"/' /etc/etckeeper/etckeeper.conf
etckeeper init
etckeeper commit "Initial revision"

apt-get install -y facter emacs24-nox screen

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

hostname $hostname
ipaddress=`facter ipaddress`
ipaddress6=`facter ipaddress6`
sed -ie "s/$ipaddress.*/$ipaddress $hostname.$domainname $hostname/" /etc/hosts
sed -ie "s/$ipaddress6.*/$ipaddress6 $hostname.$domainname $hostname/" /etc/hosts
apt-get install -y puppetmaster puppet puppet-el

# clone the puppet modules
git clone $puppetmodules_repo /etc/puppet/modules/

sed -ie "s/\[main\]/[main]\nserver=$puppetserver/g" /etc/puppet/puppet.conf
