require 'sinatra'

get '/' do
  puts param['query']
  puts cookies[:cookie1]
  puts cookies["cookie2"]
end

post "/update" do
  puts "update"
end