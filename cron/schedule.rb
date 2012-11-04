loop {
  require 'net/http'
  require 'uri'

  uri = URI.parse 'http://afriendlysyncapp.herokuapp.com/api/fb/push/threads'
  puts Net::HTTP.get_response uri
  
  sleep 17
}