require File.expand_path(File.dirname(__FILE__) + '/test_helper')

# Modelos
class EmailOnline < Tableless
  attr_accessor :mail
  validates_as_email :mail, :online => true
end

class EmailOffline < Tableless
  attr_accessor :mail
  validates_as_email :mail
end

class EmailBlacklist < Tableless
  attr_accessor :mail
  validates_as_email :mail, :blacklist => [/gmail.com.br$/, /hotmail.com.br$/]
end

class MultipleEmailBlacklist < Tableless
  attr_accessor :mail
  validates_as_email :mail, :blacklist => [/gmail.com.br$/, /hotmail.com.br$/], :multiple => true
end

class MultipleEmailOffline < Tableless
  attr_accessor :mail
  validates_as_email :mail, :multiple => true
end

class EmailOfflineObrigatorio < Tableless
  attr_accessor :mail
  validates_as_email :mail
  validates_presence_of :mail
end

# Testes
class EmailsTest < Test::Unit::TestCase
  def test_email_com_blacklist_vazia
    assert EmailOffline.new(:mail => 'andre@teste.com').valid?, "endereco andre@teste.com devia passar na blacklist vazia"
  end

  def test_email_com_blacklist
    assert !EmailBlacklist.new(:mail => 'andre@gmail.com.br').valid?, "endereco andre@gmail.com.br devia parar na blacklist"
    assert EmailBlacklist.new(:mail => 'andre@gmail.com').valid?, "endereco andre@gmail.com devia passar na blacklist"

    assert !EmailBlacklist.new(:mail => 'andre@hotmail.com.br').valid?, "endereco andre@hotmail.com.br devia parar na blacklist"
    assert EmailBlacklist.new(:mail => 'andre@hotmail.com').valid?, "endereco andre@hotmail.com devia passar na blacklist"
  end

  def test_multiple_emails_com_blacklist
    assert !MultipleEmailBlacklist.new(:mail => 'andre@gmail.com.br, andre@hotmail.com.br').valid?, "enderecos andre@gmail.com.br e andre@hotmail.com.br deviam parar na blacklist"
    assert !MultipleEmailBlacklist.new(:mail => 'andre@gmail.com, andre@hotmail.com.br').valid?, "endereco andre@gmail.com, andre@hotmail.com.br devia parar na blacklist"
    assert MultipleEmailBlacklist.new(:mail => 'andre@gmail.com, andre@hotmail.com').valid?, "endereco andre@gmail.com, andre@hotmail.com deviam passar na blacklist"
  end

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

  def test_alias_valido_online
    address = "redirecionamento@boaideia.inf.br"
    assert EmailOnline.new(:mail => address).valid?, "rejeitou #{address}, mas o redirecionamento existe"
  end

  def test_email_sintaxe_valida_mas_host_sem_mx
    address = "validates_as_email@localhost"
    assert !EmailOnline.new(:mail => address).valid?, "localhost deve ter mx ou smtp rodando, nao devia para passar neste teste"
  end

  def test_multiplos_emails
    addresses = "um@exemplo.com.br, dois@exemplo.com.br,tres@exemplo.com.br , quatro@exemplo.com.br "
    assert MultipleEmailOffline.new(:mail => addresses).valid?, "#{addresses} valido mas rejeitado"
    assert !EmailOffline.new(:mail => addresses).valid?, "#{addresses} validado mas multiple eh falso"
  end

  def test_multiplos_emails_com_problema
    addresses = "um@exemplo.com.br, dois da silva <dois@exemplo.com.br>"
    assert !MultipleEmailOffline.new(:mail => addresses).valid?, "#{addresses} invalido mas validado"
  end
end
