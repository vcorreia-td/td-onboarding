require 'rubygems'
require 'sinatra'
require 'twilio-ruby'

get '/hello-monkey' do
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
    r.gather(:numDigits => '1', :action => '/hello-monkey/handle-gather', :method => 'get') do |g|
      g.say('To speak to a real monkey, press 1.')
      g.say('Press any other key to start over.')
    end
  end.to_s
end

get '/hello-monkey/handle-gather' do
  redirect '/hello-monkey' unless params['Digits'] == '1'
  Twilio::TwiML::VoiceResponse.new do |r|
    r.dial(number: '+13105551212') ### Connect the caller to Koko, or your cell
    r.say('The call failed or the remote party hung up. Goodbye.')
  end.to_s
end
