reload!
r = Record.new
r.provider = 'foo'
r.identifier = 'baz'
r.metadata = {'foo' => 'bar'}
r.save
r = Record.find('21eb6533733a5e4763acacd1d45a60c2e0e404e1')
r.metadata = {'fooz' => 'barn'}
r.save
r.destroy