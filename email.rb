require 'net/smtp'

def send_email(recipients, subject, body)
  message = email_body(recipients, subject, body)
  smtp = Net::SMTP.new 'smtp.dreamhost.com', 587
  smtp.enable_starttls
  smtp.start('michaelkeenan.net', 'bot@michaelkeenan.net', 'Jabber66^', :login) do |smtp|
    smtp.send_message message, 'bot@michaelkeenan.net', recipients.split(',')
  end
end

def email_body(recipients, subject, body)
  <<MESSAGE_DELIMITER
From: AWARE Robot <bot@michaelkeenan.net>
To: #{recipients}
MIME-Version: 1.0
Content-type: text/html
Subject: #{subject}


#{body}
MESSAGE_DELIMITER
end
