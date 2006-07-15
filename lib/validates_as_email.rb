# validates_as_email.rb - implement the validation of email
#  
#  Copyright (c) 2006 O.S. Systems
#  
#  Author: Luis Gustavo S. Barreto <gustavo@ossystems.com.br>
# 
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.

# Referencias:
#
# SMTP: Simple Mail Transfer Protocol - http://cr.yp.to/smtp.html
# MX Record - http://en.wikipedia.org/wiki/MX_record

require 'socket'
require 'resolv'
require 'timeout'
require 'rfc2822'

include Socket::Constants

module RFC2822
  def RFC2822.check_addr_spec(email = nil)
    # apenas valida o formato do email...
    email =~ RFC2822::EmailAddress
  end

  def RFC2822.check_addr_online(email = nil)
    return true if email.blank?

    host = email.split("@")[1]
    # Verifica se o host existe
    Socket.gethostbyname(host)

    socket = Socket.new(AF_INET, SOCK_STREAM, 0)

    dns =  Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::MX)
    mx_record = dns[0].exchange.to_s unless dns.empty?

    # Se o host nao tiver um MX Record usa o proprio host como SMTP
    smtp_server = mx_record == nil ? host : mx_record
    sockaddr = Socket.pack_sockaddr_in(25, smtp_server)

    socket.connect(sockaddr)

    # Conectou? estamos prontos pra conversar?
    if socket.recvfrom(255).to_s.chomp =~ /^220/
      # Conversando...
      socket.write("HELO #{host}\r\n")
      out = socket.recvfrom(255).to_s.chomp
      #RAILS_DEFAULT_LOGGER.debug "#{smtp_server} ---------------------------"
      #RAILS_DEFAULT_LOGGER.debug "HELO #{host}"
      #RAILS_DEFAULT_LOGGER.debug out

      socket.write("MAIL FROM: <#{email}>\r\n")
      out = socket.recvfrom(255).to_s.chomp
      #RAILS_DEFAULT_LOGGER.debug "MAIL FROM: <#{email}>"
      #RAILS_DEFAULT_LOGGER.debug out

      socket.write("RCPT TO: <#{email}>\r\n")
      out = socket.recvfrom(255).to_s.chomp
      #RAILS_DEFAULT_LOGGER.debug "RCPT TO: <#{email}>"
      #RAILS_DEFAULT_LOGGER.debug out

      # Foi um prazer
      socket.write("QUIT\r\n")
      #RAILS_DEFAULT_LOGGER.debug "QUIT"
      #RAILS_DEFAULT_LOGGER.debug socket.recvfrom(255).to_s.chomp
      socket.close

      # Se a ultima coisa que o SMTP server enviou comecar com 250 o email existe, se não...
      out =~ /^250/ ? true : nil
    else
      return nil
    end 
  end
end

module ActiveRecord
  module Validations
    module ClassMethods
      def validates_as_email(*attr_names)
        configuration = { :message => "is invalid",
          :timeout => "can't be checked because we can't contact your mail server, wait a minute and try again..."}
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          unless value.blank?
            begin
              # levanta excessão padrão se nao validar o endereço
              raise unless RFC2822::check_addr_spec(value)
              # levanta excessão padrão se for pra validar online e não passar no teste
              raise if configuration[:online] and not RFC2822::check_addr_online(value)
            rescue Errno::ETIMEDOUT
              # pode ocorrer no check_addr_online
              record.errors.add(attr_name, configuration[:timeout])
            rescue
              # excessão padrão (também nos casos de SocketError e Errno::ECONNREFUSED)
              record.errors.add(attr_name, configuration[:message])
            end
          end
        end
      end
    end
  end
end