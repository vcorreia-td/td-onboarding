require 'rubygems'
require 'sinatra'
require 'twilio-ruby'

get '/' do
  'Index Page'
end

get '/hello-monkey' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say 'Hello Monkey'
  end.to_s
end