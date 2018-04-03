# puppet-unit

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/SUnit`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'puppet-unit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install puppet-unit

## Usage

```
$ bundle exec puppet-unit
1) MyTest2
   Description: Testing that 1+2=3
   Result: Test failed ✘
  RuntimeError :: ERRRRRORRR
  /home/vagrant/workspace/MyApp/puppet-unit/example1.rb:17:in `test'
  /home/vagrant/workspace/puppet-unit/lib/SUnit/test_runner.rb:40:in `block in run'
  /home/vagrant/workspace/puppet-unit/lib/SUnit/test_runner.rb:29:in `each'
  /home/vagrant/workspace/puppet-unit/lib/SUnit/test_runner.rb:29:in `each_with_index'
  /home/vagrant/workspace/puppet-unit/lib/SUnit/test_runner.rb:29:in `run'
  /home/vagrant/workspace/puppet-unit/exe/sunit:15:in `<top (required)>'
  /home/vagrant/workspace/MyApp/vendor/bundle/ruby/2.4.0/bin/sunit:23:in `load'
  /home/vagrant/workspace/MyApp/vendor/bundle/ruby/2.4.0/bin/sunit:23:in `<main>'
   Duration: 0.0s
2) MyTest
   Description: Testing that 1+1=2
   Result: Test passed ✔
   Duration: 0.0s
3) MyTest3
   Description: Testing that 1+2=3
   Result: Test skipped *
$ echo $?
1
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/puppet-unit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
