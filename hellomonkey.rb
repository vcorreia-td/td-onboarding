require 'rubygems'
require 'sinatra'
require 'twilio-ruby'

get '/' do
  'Index Page'
end

get '/hello-monkey' do
  from = params['From'] || 'nowhere'
  text = "Hello Monkey. You come from #{from}"
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say text
  end.to_s
end