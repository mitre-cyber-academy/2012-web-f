require 'sinatra'
require 'json'
require 'sequel'
require 'sinatra/sequel'
require 'sqlite3'
require 'csv'

ADMIN_USERNAME    = 'ohmayer'
FLAG              = "MCA-D2242B07"

set :database, 'sqlite://users.db'
set :sessions, false

class User < Sequel::Model
  def to_s
    s = ''
    self.values.each_value { |v| s << v }
    s
  end
end


helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area: Only authorized personal and students may access their account. Accessing someone's elses account will be considered an Honor Code Violation")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    if @auth.provided? && @auth.basic? && @auth.credentials
      password_hash = Digest::MD5.hexdigest(@auth.credentials[1])
      @user ||= User.where(username: @auth.credentials[0], hashed_password: password_hash).first
      !@user.nil?
    else
      false
    end
  end
  
  def random_grade
    ['A', 'B', 'C', 'D', 'F'].sample
  end

end

get '/' do
  fields = params[:fields] || 'username'
  @count = User.fetch("SELECT * FROM users").count
  @users = User.fetch("SELECT #{fields} FROM users LIMIT 0,2")
  
  haml :index
end

get '/account' do
  protected!
  
  haml :account
end

get '/new' do
  haml :new
end

post '/new' do
  User.insert("username = ? AND hashed_password = ?", params[:username], params[:pasword])
  redirect '/account'
end