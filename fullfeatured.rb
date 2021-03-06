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

get '/monkey-respond' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('I am another monkey.')
  end.to_s
end

## call person

get '/talking-to-person' do
  from = params['From']
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('Hello person')
    r.dial do |dial|
      dial.number('+351937753869', 
                  url: '/talking-to-person/client-notification', 
                  method: 'GET',
                  statusCallback: 'https://secret-shelf-83431.herokuapp.com/talking-to-person/handle-hangup',
                  statusCallbackMethod: 'POST',
                  statusCallbackEvent: 'completed')
      dial.action('/talking-to-person/hangup-notification')
    end
    # r.redirect('/talking-to-person/hangup-notification')
    # r.say('Goodbye person')
  end.to_s
end

get '/talking-to-person/client-notification' do 
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('You are going to talk to a person.')
  end.to_s
end

post '/talking-to-person/hangup-notification' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('The other party hung up.')
  end.to_s
end

post '/talking-to-person/handle-hangup' do
    Twilio::TwiML::VoiceResponse.new do |r|
        r.redirect('/talking-to-person/hangup-notification')
    end.to_s
end



##################
## NEW APPROACH ##
##################


get '/new-talking-to-person' do
  from = params['From']
  room = 'MyRoom'
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('Hello person')
    r.dial do |dial|
      dial.number('+351937753869', 
                  url: "/new-talking-to-person/client-join-conference/#{room}", 
                  method: 'POST')
      dial.conference(room,
                      start_conference_on_enter: true,
                      end_conference_on_exit: true,
                      # hack :(
                      statusCallback: "https://secret-shelf-83431.herokuapp.com/new-talking-to-person/handle-hangup",
                      statusCallbackMethod: 'GET',
                      status_callback_event: 'end')
    end
  end.to_s
end

post '/new-talking-to-person/client-join-conference/:room' do 
  room = params['room']
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('You are going to talk to a person.')
    r.dial do |dial|
      dial.conference(room,
                      start_conference_on_enter: true,
                      end_conference_on_exit: true,
                      statusCallback: "https://secret-shelf-83431.herokuapp.com/new-talking-to-person/handle-hangup",
                      statusCallbackMethod: 'GET',
                      status_callback_event: 'end')
    end
  end.to_s
end

get '/new-talking-to-person/handle-hangup' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('You are going to talk to a person.')
    r.hangup
  end.to_s
end


#####################
## NEWEST APPROACH ##
#####################

## manage the conference and call procedurally :|



get '/newest-talking-to-person' do
  call_sid = params['CallSid']
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('Hello person')
    r.dial do |dial|
      dial.number('+351937753869',
                  url: "/newest-talking-to-person/client-picked-up/#{call_sid}")
    end
  end.to_s
end

post '/newest-talking-to-person/client-picked-up/:otherCallSid' do
  other_call_sid = params['otherCallSid']
  call_sid = params['CallSid']
  client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
  other_call = client.api.calls(other_call_sid)
  other_call.update(url: "https://secret-shelf-83431.herokuapp.com/newest-talking-to-person/join-conference/#{call_sid}",
                    method: 'POST')
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('You are going to talk to a person')
    r.dial do |dial|
      dial.conference('myRoom',
                      start_conference_on_enter: true,
                      end_conference_on_exit: false,
                      # hack :(
                      statusCallback: "https://secret-shelf-83431.herokuapp.com/newest-talking-to-person/handle-hangup/#{other_call_sid}",
                      statusCallbackMethod: 'POST',
                      statusEallbackEvent: 'leave')
    end
  end.to_s
end

post '/newest-talking-to-person/join-conference/:otherCallSid' do
  other_call_sid = params['otherCallSid']
  Twilio::TwiML::VoiceResponse.new do |r|
    r.dial do |dial|
      dial.conference('myRoom',
                      start_conference_on_enter: true,
                      end_conference_on_exit: false,
                      # hack :(
                      statusCallback: "https://secret-shelf-83431.herokuapp.com/newest-talking-to-person/handle-hangup/#{other_call_sid}",
                      statusCallbackMethod: 'POST',
                      statusCallbackEvent: 'leave')
    end
  end.to_s
end

post 'newest-talking-to-person/handle-hangup/:otherCallSid' do
  other_call_sid = params['otherCallSid']
  client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
  other_call = client.api.calls(other_call_sid)
  other_call.update(url: "https://secret-shelf-83431.herokuapp.com/newest-talking-to-person/message-and-hangup",
                    method: 'POST')
  # I believe this is unnecessary
  Twilio::TwiML::VoiceResponse.new do |r|
    r.hangup
  end.to_s
end

post '/newest-talking-to-person/message-and-hangup' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('The other person hung up.')
    r.hangup
  end.to_s
end
