require 'rubygems'
require 'sinatra'
require 'twilio-ruby'

get '/hello-monkey' do
  from = params['From'] || 'nowhere'
  text = "Hello Monkey. You come from #{from}"
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say text
  end.to_s
end

get '/talk-to-monkey' do
  people = {
    '+14158675309' => 'Curious George',
    '+14158675310' => 'Boots',
    '+14158675311' => 'Virgil',
    '+14158675312' => 'Marcel',
  }
  name = people[params['From']] || 'Monkey'
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say("Hello #{name}")
    r.play(url: 'http://demo.twilio.com/hellomonkey/monkey.mp3')
    r.gather(:numDigits => '1', :action => '/talk-to-monkey/handle-gather', :method => 'get') do |g|
      g.say('To speak to a real monkey, press 1.')
      g.say('Press any other key to start over.')
    end
  end.to_s
end

get '/talk-to-monkey/handle-gather' do
  redirect '/talk-to-monkey' unless params['Digits'] == '1'
  Twilio::TwiML::VoiceResponse.new do |r|
    r.dial(number: '+19165710211') ### Connect the caller to Koko, or your cell
    r.say('The call failed or the remote party hung up. Goodbye.')
  end.to_s
end

get 'monkey-respond' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('I am another monkey.')
  end.to_s
end