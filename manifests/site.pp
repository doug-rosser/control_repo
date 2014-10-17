node 'puppet.vm' {
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
