node "default" {
  class {"test_module":
    ensure => "purged"
  }
}