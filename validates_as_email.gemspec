# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "validates_as_email/version"

Gem::Specification.new do |s|
  s.name        = "validates_as_email"
  s.version     = ValidatesAsEmail::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["André Camargo",
                   "Everton J. Carpes",
                   "Luis Gustavo S. Barreto",
                   "Otávio Salvador"]
  s.email       = ["andre@boaideia.inf.br",
                   "everton.carpes@gmail.com",
                   "gustavo@ossystems.com.br",
                   "otavio@ossystems.com.br"]
  s.homepage    = "http://www.ossystems.com.br/"
  s.summary     = %q{Adiciona validação de e-Mail ao ActiveRecord}
  s.description = %q{Uma gem configurável que adiciona validação de e-Mail de acordo com a RFC 2822 a qualquer modelo do ActiveRecord, de forma semelhante como funciona as validações padrão.}

  s.rubyforge_project = "validates_as_email"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
