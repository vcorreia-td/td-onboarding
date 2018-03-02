require 'rubygems'
require 'sinatra'
require 'twilio-ruby'
require 'securerandom'

if File.file? '.env'
  open('.env', 'r').readlines.each {|l| kv = l.split('='); ENV[kv[0]] = kv[1];}
end

db = {}
client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
puts client

# domain = 'https://secret-shelf-83431.herokuapp.com'
domain = 'http://routing.tst.talkdeskdev.com:9221'

get '/interaction' do
  interaction_id = SecureRandom.uuid
  room_id = SecureRandom.uuid
  call_sid = params['CallSid']
  db[interaction_id] = [call_sid]
  other_call = client.calls.create(url: "#{domain}/interaction/conference/#{interaction_id}",
                                   to: '+351937753869',
                                   #from: params['From'])
                                   from: '+19783062153')
  db[interaction_id] = [call_sid]
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('You are going to talk to a person')
    r.dial do |dial|
      dial.conference(interaction_id,
                      start_conference_on_enter: true,
                      end_conference_on_exit: false,
                      # hack :(
                      statusCallback: "#{domain}/interaction/hangup/#{interaction_id}",
                      statusCallbackMethod: 'POST',
                      status_callback_event: 'leave')
    end
  end.to_s
end

post '/interaction/conference/:interaction_id' do
  interaction_id = params['interaction_id']
  call_sid = params['CallSid']
  db[interaction_id].push(call_sid)
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('Prepare to talk to a person')
    r.dial do |dial|
      dial.conference(interaction_id,
                      start_conference_on_enter: true,
                      end_conference_on_exit: false,
                      # hack :(
                      statusCallback: "#{domain}/interaction/hangup/#{interaction_id}",
                      statusCallbackMethod: 'POST',
                      status_callback_event: 'leave')
    end
  end.to_s
end

post '/interaction/hangup/:interaction_id' do
  interaction_id = params['interaction_id']
  call_sid = params['CallSid']
  db[interaction_id].delete(call_sid)
  db[interaction_id].each do |cs|
    call = client.api.calls(cs)
    call.update(url: "#{domain}/interaction/goodbye",
                method: 'GET')
  end
  # clean DB
end

get '/interaction/goodbye' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('Another person hung up. Terminating call')
    r.hangup
  end.to_s
end
