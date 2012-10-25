configure :development, :test do
  set :database, 'sqlite3:///db/development.sqlite3'
end

configure :production do
  require 'uri'

  db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/d1tpn6k5ofglon')

  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :port     => db.port,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
  
  require 'newrelic_rpm'
end
