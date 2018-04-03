Facter.add('myfirstfacts') do
  setcode do
    {"foo1" => "bar1"}
  end
end
