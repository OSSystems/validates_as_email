require File.dirname(__FILE__) + '/abstract_unit'
require '../lib/validates_as_email'

# Modelo
class EmailData < ActiveRecord::Base
  set_table_name "emails"
end

# Testes
class EmailsTest < Test::Unit::TestCase
  def test_email_invalido_offline
    EmailData.validates_as_email :mail, :online => nil
    
    email_invalido = EmailData.create(:id => 1, :mail => "123aa@a.k")
    email_invalido.save


    assert ( email_invalido.errors.on(:mail) != nil ),
             "Salvou email invalido."
  end

  def test_email_valido_offline
    EmailData.validates_as_email :mail, :online => nil
    
    email_valido = EmailData.create(:id => 2, :mail => "gustavosbarreto@gmail.com")
    email_valido.save


    assert ( email_valido.errors.on(:mail) == nil ),
             "Nao salvou um email valido que deveria ser salvo."
  end

  def test_email_invalido_online
    EmailData.validates_as_email :mail, :online => true
    
    email_invalido = EmailData.create(:id => 3, :mail => "ubirajararodrigues@debian.org")
    email_invalido.save

    assert ( email_invalido.errors.on(:mail) != nil ),
             "Salvou email invalido."
  end

  def test_email_valido_online
    EmailData.validates_as_email :mail, :online => true
   
    email_valido = EmailData.create(:id => 4, :mail => "gustavosbarreto@gmail.com")
    email_valido.save

    assert ( email_valido.errors.on(:mail) == nil ),
             "Nao salvou um email valido que deveria ser salvo."
  end
end
