%w(sinatra ./recall).each  { |lib| require lib}
run Sinatra::Application