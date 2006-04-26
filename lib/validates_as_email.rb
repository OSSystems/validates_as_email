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

include Socket::Constants

module Email
  class Validacao
    # Funcao principal de validacao
    def self.valida_email(email = nil, online = nil)
      # Valida o formato do email...
      if email =~ /[^0-9][a-zA-Z0-9]@[^0-9][a-zA-Z0-9]+\.[a-zA-Z]{2,}$/
        return true if online != true

        #puts "online? #{online}"
        host = email.split("@")[1]
        # Verifica se o host existe
        begin
          Socket.gethostbyname(host)
        rescue SocketError
          return nil
        end

        socket = Socket.new(AF_INET, SOCK_STREAM, 0)

        dns =  Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::MX)
        mx_record = dns[0].exchange.to_s

        # Se o host nao tiver um MX Record usa o proprio host como SMTP
        smtp_server = mx_record == nil ? host : mx_record
        sockaddr = Socket.pack_sockaddr_in(25, smtp_server)

       # begin
        #  timeout(2) do
            socket.connect(sockaddr)
         # end
        #rescue
         # return nil
        #end

        # Conectou? estamos prontos pra conversar?
        if socket.recvfrom(255).to_s.chomp =~ /^220/
          # Conversando...
          socket.write("HELO #{smtp_server}\r\n")
          out = socket.recvfrom(255).to_s.chomp

          socket.write("MAIL FROM: <#{email}>\r\n")
          out = socket.recvfrom(255).to_s.chomp

          socket.write("RCPT TO: <#{email}>\r\n")
          out = socket.recvfrom(255).to_s.chomp

          # Foi um prazer
          socket.write("QUIT\r\n")
          socket.close

          # Se a ultima coisa que o SMTP server enviou comecar com 250 o email existe, se não...
          out =~ /^250/ ? true : nil
        else
          return nil
        end 
      end
    end
  end
end

module ActiveRecord
  module Validations
    module ClassMethods
      def validates_as_email(*attr_names)
        configuration = { :message => "email invalido" }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          unless Email::Validacao::valida_email(value, configuration[:online])          
            record.errors.add(attr_name, configuration[:message])
          end
        end
      end
    end
  end
end

