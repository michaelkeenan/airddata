require 'date'

def save_comment
  json = JSON.parse(request.body.read)
  uuid = json['comment_uuid']
  comment = {
    uuid: escape_html(json['uuid']),
    url: escape_html(json['url']),
    text: escape_html(json['comment']),
    created_at: Time.now.utc.to_s
  }
  @comments_store.transaction do
    @comments_store[uuid] = comment
  end
  send_comment_email(comment)
end

def send_comment_email(comment, send = true)
  subject = "New comment on #{comment[:url]}"

  body = <<~EOF
    <b>Created at</b>: #{comment[:created_at]}<br />
    <b>URL</b>: #{comment[:url]}<br />
    <br />
    #{comment[:text].gsub("\n", "<br />")}
    <br /><br />
    <a href="https://aird.michaelkeenan.net/comments##{comment[:comment_uuid]}">View all the comments here</a>.
  EOF

  recipients = @settings_store.transaction do
    @settings_store[:email_comments]
  end

  send_email(recipients, subject, body) if send

  body
end

def get_comments
  comments = []
  @comments_store.transaction do
    @comments_store.roots.each do |root|
      comments.push @comments_store[root]
      comments.last[:comment_uuid] = root
    end
  end
  comments.sort_by! { |comment| comment[:created_at] ? DateTime.parse(comment[:created_at]) : DateTime.new }
  comments
end

options '/comments/json' do
  allow_cors_options
end

post "/comments" do
  save_comment
  "OK"
end

get '/comments/json' do
  content_type :json
  headers['Access-Control-Allow-Origin'] = '*'
  @comments = get_comments
  erb :comments_json, layout: nil
end

get "/comments" do
  @comments = get_comments
  erb :comments
end

get "/comments/preview_email" do
  comments = get_comments
  send_comment_email(comments.last, false)
end

post "/comments/delete" do
  password_protected
  @comments_store.transaction do
    @comments_store[params[:comment_uuid]][:deleted_at] = Time.now.utc
  end
  @comments = get_comments
  erb :comments
end

post "/comments/restore" do
  password_protected
  @comments_store.transaction do
    @comments_store[params[:comment_uuid]][:deleted_at] = nil
  end
  @comments = get_comments
  erb :comments
end
