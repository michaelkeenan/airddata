def book_call_messages_page
  @book_call_messages = []
  @book_calls_store.transaction do
    @book_calls_store.roots.each do |root|
      @book_call_messages.push @book_calls_store[root]
    end
  end
  @book_call_messages.sort_by! { |message| message[:created_at] ? DateTime.parse(message[:created_at]) : DateTime.new }
  erb :book_call_messages
end

def save_book_call_message(name, email, interest, message)
  @book_calls_store.transaction do
    @book_calls_store[SecureRandom.uuid] = {
      name:     escape_html(name),
      email:    escape_html(email),
      interest: escape_html(interest),
      message:  escape_html(message),
      created_at: Time.now.utc.to_s
    }
  end
end

def send_book_call_email(name, email, interest, message, send = true)
  subject = "Call request from #{name}: #{interest}"

  body = <<~EOF
    name: #{name}<br />
    email: #{email}<br />
    Interested in: #{interest}<br />
    message:<br />
    #{message.gsub("\n", "<br />")}
    <br /><br />
    <a href="https://aird.michaelkeenan.net/book_call_messages">View all the call requests here</a>.
  EOF

  recipients = @settings_store.transaction do
    @settings_store[:email_book_call_messages]
  end

  send_email(recipients, subject, body) if send
  body
end

post "/book_call_messages" do
  password_protected
  book_call_messages_page
end

get "/book_call_messages" do
  password_protected
  book_call_messages_page
end

get "/book_call_messages/preview_email" do
  @message = nil
  @book_calls_store.transaction do
    @message = @book_calls_store[@book_calls_store.roots.first]
  end
  send_book_call_email(
    @message[:name],
    @message[:email],
    @message[:interest],
    @message[:message],
    false)
end

options '/book_call' do
  allow_cors_options
end

post "/book_call" do
  headers['Access-Control-Allow-Origin'] = '*'
  json = JSON.parse(request.body.read)
  name =      json['name']
  email =     json['email']
  interest =  json['interest']
  message =   json['message']

  raise 'test error' if name == 'test error'

  begin
    save_book_call_message(name, email, interest, message)
  rescue
  end

  attempts = 0
  begin
    send_book_call_email(name, email, interest, message)
  rescue e
    attempts += 1
    if attempts < 2
      sleep 1
      retry
    end
  end

  "OK"
end
