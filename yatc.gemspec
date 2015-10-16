Gem::Specification.new do |s|
  s.name          = 'yatc'
  s.version       = '0.0.3'
  s.date          = '2015-10-16'
  s.summary       = 'Yet Another Twitter Client'
  s.description   = 'Twitter client.'
  s.authors       = ['Rafael Rendón Pablo']
  s.email         = 'rafaelrendonpablo@gmail.com'
  s.files         = `git ls-files -- lib/*`.split("\n")
  
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map do |f|
    File.basename(f)
  end
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/rendon/yatc'
  s.license       = 'GNU GPL v3.0'
end
