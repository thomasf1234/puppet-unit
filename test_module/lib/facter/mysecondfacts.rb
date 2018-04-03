Facter.add('mysecondfacts') do
  setcode do
    {"foo2" => "bar2"}
  end
end
