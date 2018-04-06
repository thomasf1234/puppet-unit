class puppet_unit::example {
  file {"/puppet-test":
    ensure => "absent"
  }
}

include puppet_unit::example
