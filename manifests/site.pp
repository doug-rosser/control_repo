node default {
}

node 'puppet.vm' {
  include epel

  class { '::haproxy':
    global_options   => {
      'log'     => "${::ipaddress} local0",
      'chroot'  => '/var/lib/haproxy',
      'pidfile' => '/var/run/haproxy.pid',
      'maxconn' => '4000',
      'daemon'  => '',
      'stats'   => 'socket /var/lib/haproxy/stats',
    },
  }

  # Monitoring TODO: Change this password?
  haproxy::listen { 'stats':
    ipaddress        => '*',
    ports            => '9090',
    collect_exported => false,
    options          => {
      'mode'  => 'http',
      'stats' => ['uri /', 'auth puppet:puppet']
      },
  }

 haproxy::balancermember { "puppet00:puppet-master01.vm":
   server_names      => "puppet-master01.vm",
   listening_service => 'puppet00',
   ipaddresses       => '172.31.20.62',
   ports             => '8140',
   options           => 'check',
 }
 haproxy::balancermember { "puppet00:puppet-master02.vm":
   server_names      => "puppet-master02.vm",
   listening_service => 'puppet00',
   ipaddresses       => '172.31.20.63',
   ports             => '8140',
   options           => 'check',
 }
 ## HA masters
 haproxy::listen { 'puppet00':
   ipaddress        => '*',
   ports            => '8140',
   collect_exported => false,
 }
}

node /^puppet-master.*/ {
  class {'puppet_enterprise::profile::master':
    certname                     => $::clientcert,
    console_host                 => 'console.vm',
    puppetdb_host                => 'puppetdb.vm',
    ca_host                      => 'certificate-authority.vm',
    classifier_host              => 'console.vm',
    console_server_certname      => 'console.vm',
  }

  # The classifier will also add the agent class which will manage the service
  # which is required for this class as its notifies pe-mcollective
  include puppet_enterprise::profile::master::mcollective

  # hack until PE-6012 gets fixed
  #Service <| title == 'pe-puppetserver' |> {
  #  start => 'service pe-puppetserver start && until test -d /etc/puppetlabs/puppet/ssl/ca ; do sleep 1 ; done'
  #}

  #file { 'hack for PE-6012':
  #  ensure  => file,
  #  path    => "${settings::ssldir}/ca/ca_crt.pem",
  #  source  => "${settings::ssldir}/certs/ca.pem",
  #  require => Class['puppet_enterprise::profile::master'],
  #}
}

