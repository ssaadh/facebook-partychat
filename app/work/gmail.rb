require 'gmail'

gmail = Gmail.new( 'EMAIL@gmail.com', 'PASSWORD' )

@test = gmail.inbox.emails( :from => 'notification@facebookmail.com' ).first.raw_message

@testing = @test.header[ 'X-Facebook-Notify' ]

p @testing

#puts YAML::dump( @test )

gmail.logout