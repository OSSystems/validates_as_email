require 'abstract_unit'

# Modelos
class EmailOnline < ActiveRecord::Base
  def self.columns; []; end
  attr_accessor :mail
  validates_as_email :mail, :online => true
end

class EmailOffline < ActiveRecord::Base
  def self.columns; []; end
  attr_accessor :mail
  validates_as_email :mail
end

class EmailOfflineObrigatorio < ActiveRecord::Base
  def self.columns; []; end
  attr_accessor :mail
  validates_as_email :mail
  validates_presence_of :mail
end

# Testes
class EmailsTest < Test::Unit::TestCase
  def test_email_vazio
    assert EmailOffline.new(:mail => '').valid?, "string vazia eh valida mas foi rejeitada"
    assert EmailOffline.new(:mail => nil).valid?, "nil eh valido mas foi rejeitado"
  end
  
  def test_email_obrigatorio
    assert !EmailOfflineObrigatorio.new(:mail => '').valid?, "e-mail obrigatorio de valor vazio passou na validacao"
    assert !EmailOfflineObrigatorio.new(:mail => nil).valid?, "e-mail obrigatorio de valor nulo passou na validacao"
  end
  
  def test_email_invalido_offline
    addresses = [
      '-- dave --@example.com', # (spaces are invalid unless enclosed in quotation marks)
      '[dave]@example.com', # (square brackets are invalid, unless contained within quotation marks)
      '.dave@example.com', # (the local part of a domain name cannot start with a period)
      'Max@Job 3:14', 
      'Job@Book of Job',
      'J. P. \'s-Gravezande, a.k.a. The Hacker!@example.com',
      ]
    addresses.each do |address|
      assert !EmailOffline.new(:mail => address).valid?, "#{address} aceito mas invalido"
    end
  end

  def test_email_valido_offline
    addresses = [
      '+1~1+@example.com',
      '{_dave_}@example.com',
      '"[[ dave ]]"@example.com',
      'dave."dave"@example.com',
      'test@localhost',
      'test@example.com', 
      'test@example.co.uk',
      'test@example.com.br',
      '"J. P. \'s-Gravezande, a.k.a. The Hacker!"@example.com',
      'me@[187.223.45.119]',
      'someone@123.com',
      'simon&garfunkel@songs.com'
      ]
    addresses.each do |address|
      assert EmailOffline.new(:mail => address).valid?, "#{address} valido mas rejeitado"
    end
  end

  def test_email_invalido_online
    ["ubirajararodrigues@debian.org", "inexistente@boaideia.inf.br"].each do |address|
      assert !EmailOnline.new(:mail => address).valid?, "aceitou #{address}, mas a conta *nao* existe"
    end
  end

  def test_email_valido_online
    address = "gustavosbarreto@gmail.com"
    assert EmailOnline.new(:mail => address).valid?, "rejeitou #{address}, mas a conta existe"
  end
  
  def test_email_valido_redirecionado_online
    ["gustavo@ossystems.com.br", "andre@boaideia.inf.br"].each do |address|
      assert EmailOnline.new(:mail => address).valid?, "rejeitou #{address}, mas o redirecionamento existe"
    end
  end
  
  def test_email_sintaxe_valida_mas_host_sem_mx
    address = "validates_as_email@localhost"
    assert !EmailOnline.new(:mail => address).valid?, "localhost deve ter mx ou smtp rodando, nao devia para passar neste teste"
  end
  
  def test_email_alias_online
    address = "redirecionamento@boaideia.inf.br"
    assert EmailOnline.new(:mail => address).valid?, "nao aceitou o alias #{address}"
  end
end