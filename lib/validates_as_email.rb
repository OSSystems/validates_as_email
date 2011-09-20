# -*- coding: utf-8 -*-
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

require 'active_support/concern'
require 'active_model'

require 'socket'
require 'resolv'
require 'timeout'
require 'rfc2822'

include Socket::Constants

module ValidatesAsEmail
  extend ActiveSupport::Concern

  class EmailValidator < ActiveModel::EachValidator

    class InvalidEmail < Exception; end

    def initialize(options)
      options[:message] ||= :invalid
      options[:timeout] ||= "can't be checked because we can't contact your mail server, wait a minute and try again..."
      options[:multiple] ||= false
      options[:blacklist] ||= []
      super(options)
    end

    def validate_each(record, attribute, value)
      unless value.blank?
        begin
          emails = options[:multiple] ? value.split(',').collect{|email| email.strip!} : [value]
          emails.each do |email|
            # levanta exceção se estiver na blacklist
            raise InvalidEmail unless options[:blacklist].select {|regex| email =~ regex}.empty?
            # levanta exceção padrao se nao validar o endereco
            raise InvalidEmail unless RFC2822::check_addr_spec(email)
            # levanta exceção padrao se for pra validar online e nao passar no teste
            raise InvalidEmail if options[:online] and not RFC2822::check_addr_online(email)
          end
        rescue Errno::ETIMEDOUT
          # pode ocorrer no check_addr_online
          record.errors.add(attr_name, options[:timeout])
        rescue InvalidEmail, SocketError, Errno::ECONNREFUSED
          record.errors.add(attribute, options[:message])
        end
      end
    end
  end

  module ClassMethods
    def validates_as_email(*attr_names)
      validates_with EmailValidator, _merge_attributes(attr_names)
    end
  end
end

ActiveRecord::Base.send(:include, ValidatesAsEmail)
