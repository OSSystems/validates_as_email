# -*- coding: utf-8 -*-
# http://www.faqs.org/rfcs/rfc2822.html
module RFC2822
  EmailAddress = begin
    alpha = "a-zA-Z"
    digit = "0-9"
    atext = "[#{alpha}#{digit}\!\#\$\%\&\'\*+\/\=\?\^\_\`\{\|\}\~\-]"
    dot_atom_text = "#{atext}+([.]#{atext}*)*"
    dot_atom = "#{dot_atom_text}"
    qtext = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
    text = "[\\x01-\\x09\\x11\\x12\\x14-\\x7f]"
    quoted_pair = "(\\x5c#{text})"
    qcontent = "(?:#{qtext}|#{quoted_pair})"
    quoted_string = "[\"]#{qcontent}+[\"]"
    atom = "#{atext}+"
    word = "(?:#{atom}|#{quoted_string})"
    obs_local_part = "#{word}([.]#{word})*"
    local_part = "(?:#{dot_atom}|#{quoted_string}|#{obs_local_part})"
    no_ws_ctl = "\\x01-\\x08\\x11\\x12\\x14-\\x1f\\x7f"
    dtext = "[#{no_ws_ctl}\\x21-\\x5a\\x5e-\\x7e]"
    dcontent = "(?:#{dtext}|#{quoted_pair})"
    domain_literal = "\\[#{dcontent}+\\]"
    obs_domain = "#{atom}([.]#{atom})*"
    domain = "(?:#{dot_atom}|#{domain_literal}|#{obs_domain})"
    addr_spec = "#{local_part}\@#{domain}"
    pattern = Regexp.new addr_spec, nil, 'n'
  end

  class << self
    def check_addr_spec(email = nil)
      # apenas valida o formato do email...
      email =~ RFC2822::EmailAddress
    end

    def check_addr_online(email = nil)
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

      debug "#{Time.now} connecting to #{smtp_server} ------"
      socket.connect(sockaddr)

      # Conectou? estamos prontos pra conversar?
      if socket.recvfrom(255).to_s.chomp =~ /^220/
        # Conversando...
        debug "#{Time.now} HELO #{host}"
        socket.write("HELO #{host}\r\n")
        out = socket.recvfrom(255).to_s.chomp
        debug "#{Time.now} #{out}"

        debug "#{Time.now} MAIL FROM: <#{email}>"
        socket.write("MAIL FROM: <#{email}>\r\n")
        out = socket.recvfrom(255).to_s.chomp
        debug "#{Time.now} #{out}"

        debug "#{Time.now} RCPT TO: <#{email}>"
        socket.write("RCPT TO: <#{email}>\r\n")
        out = socket.recvfrom(255).to_s.chomp
        debug "#{Time.now} #{out}"

        # Foi um prazer
        debug "#{Time.now} QUIT"
        socket.write("QUIT\r\n")
        debug "#{Time.now} #{socket.recvfrom(255).to_s.chomp}"
        socket.close

        # Se a ultima coisa que o SMTP server enviou comecar com 250 o email existe, se não...
        out =~ /^250/ ? true : nil
      else
        return nil
      end
    end

    private
    def debug(message)
      if defined? RAILS_DEFAULT_LOGGER
        RAILS_DEFAULT_LOGGER.debug message
      end
    end
  end
end

=begin
addresses = [
  '-- dave --@example.com', # (spaces are invalid unless enclosed in quotation marks)
  '[dave]@example.com', # (square brackets are invalid, unless contained within quotation marks)
  '.dave@example.com', # (the local part of a domain name cannot start with a period)
  'Max@Job 3:14',
  'Job@Book of Job',
  'J. P. \'s-Gravezande, a.k.a. The Hacker!@example.com',
  ]
addresses.each do |address|
  if address =~ RFC2822::EmailAddress
    puts "#{address} deveria ter sido rejeitado, ERRO"
  else
    puts "#{address} rejeitado, OK"
  end
end


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
  if address =~ RFC2822::EmailAddress
    puts "#{address} aceito, OK"
  else
    puts "#{address} deveria ser aceito, ERRO"
  end
end
=end
