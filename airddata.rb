require 'sinatra'
require 'pstore'
require 'securerandom'
require 'byebug'

include Rack::Utils

require_relative 'answers.rb'
require_relative 'comments.rb'
require_relative 'book_calls.rb'
require_relative 'settings.rb'

require_relative 'email'

enable :sessions

ANSWERS_FILE = 'answers.store'
COMMENTS_FILE = 'comments.store'
BOOK_CALLS_FILE = 'book_calls.store'
SETTINGS_FILE = 'settings.store'

SECRETS_FILE = 'secrets'

configure do
  enable :cross_origin
end

before do
  @answers_store = PStore.new(ANSWERS_FILE)
  @comments_store = PStore.new(COMMENTS_FILE)
  @book_calls_store = PStore.new(BOOK_CALLS_FILE)
  @settings_store = PStore.new(SETTINGS_FILE)
end

def allow_cors_options
  # Set the allowed HTTP methods for this route
  headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'

  # Set the allowed headers for this route
  headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

  # Set the allowed origins for this route
  headers['Access-Control-Allow-Origin'] = '*'

  status 200
  body ''
end

def password_protected
  redirect '/' unless session[:authenticated]
end

post "/login" do
  correct_password = File.read(SECRETS_FILE)
  session[:authenticated] = params[:password] == correct_password
  session[:authenticated] = true if request.host == 'localhost' && params[:password] == 'a'
  @error_message = 'Wrong password' if params[:password] && !session[:authenticated]

  redirect '/'
end

get "/" do
  erb :home
end

get "/logout" do
  session[:authenticated] = false
  erb :home
end