class puppet_unit::example {
  file {"/puppet-test":
    ensure => "directory",
    mode => "0664",
    owner => "root",
    group => "root"
  }

  file { "/puppet-test/sample.txt":
    ensure  => "file",
    mode    => "0777",
    owner   => "root",
    group   => "root",
    content => "Overridden Hello World!",
  }
}

include puppet_unit::example
