class java($version) {

  Package['software-properties-common']
  -> Exec['add-apt-repository-oracle']
  -> Exec['set-licence-selected']
  -> Exec['set-licence-seen']
  -> Package['oracle-java7-installer']
  
  package { "software-properties-common":
    ensure => latest
  }

  exec { "add-apt-repository-oracle":
    command => "/usr/bin/add-apt-repository -y ppa:webupd8team/java",
    unless => "grep -c . /etc/apt/sources.list.d/webupd8team-java-$lsbdistcodename.list",
  }

  exec {
    'set-licence-selected':
      command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections';

    'set-licence-seen':
      command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections';
  }

  package { 'oracle-java7-installer':
    ensure => "${version}",
    require => Exec['apt_update'],
  }
}
