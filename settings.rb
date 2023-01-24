def settings_page
  @settings = {}
  @settings_store.transaction do
    @settings_store.roots.each do |root|
      @settings[root] = @settings_store[root]
    end
  end
  erb :settings
end

def save_settings
  @settings_store.transaction do
    @settings_store[:email_comments] = params[:email_comments]
    @settings_store[:email_book_call_messages] = params[:email_book_call_messages]
  end
end

post "/settings" do
  password_protected
  save_settings
  settings_page
end

get "/settings" do
  password_protected
  settings_page
end
