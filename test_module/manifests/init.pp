class test_module(
  $ensure = lookup("test_module::globals::ensure"),
  $sample_content = lookup("test_module::globals::sample_content")
) {

  case $ensure {
    /^(installed|present)$/: {
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
        content => $sample_content,
        require => File["/puppet-test"]
      }
    }
    /^(purged|absent)$/: {
      file {"/puppet-test":
        ensure => "absent",
        force => true,
        backup => false
      }
    }
    default: { fail("Unsupported ${ensure}") }
  }
}