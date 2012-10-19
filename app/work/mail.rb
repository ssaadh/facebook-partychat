require 'Mail'

Mail.defaults do
  retriever_method :imap, :address    => 'imap.gmail.com',
                          :port       => 993,
                          :user_name  => 'EMAIL@gmail.com',
                          :password   => 'PASSWORD',
                          :enable_ssl => true
end

@test = Mail.find( :what => :last, :count => 1, :keys => 'FROM notification@facebookmail.com' )

@testing = @test.header[ 'X-Facebook-Notify' ]

p @testing