require 'rubygems'
require 'progressbar'
require 'digest'
require 'sequel'

ADMIN = 'ohmayer'

# Create sqlite database
begin
  File.delete('users.db')
rescue Errno::ENOENT; end
DB = Sequel.sqlite('users.db')

DB.create_table :users do
  primary_key :id
  String :username, null: false
  String :hashed_password, null: false
  index :username
end

class User < Sequel::Model; end


usernames_file = ARGV[0]

File.open(usernames_file) do |file|
  admin_password = "NOT FOUND"
  bar = ProgressBar.new("Database", file.read.count("\n"))
  file.rewind
  while (username = file.gets)
    username.strip!
    
    # generate random password of 4 digits
    password  = (1000+Random.rand(999)).to_s.strip
    hash      = Digest::MD5.hexdigest(password).strip
    
    # Grab password for the admin user so we can show it
    admin_password = password if username == ADMIN
    User.create(username: username, hashed_password: hash)
    bar.inc
  end
  bar.finish
  puts "#{ADMIN} : #{admin_password}"
end