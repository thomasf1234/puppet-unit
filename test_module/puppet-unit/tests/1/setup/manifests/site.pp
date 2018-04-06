node "default" {
  class {"test_module":
    sample_content => "Overridden Hello World!"
  }
}