require 'rubygems'
require 'sinatra'
require 'twilio-ruby'
require 'securerandom'
require 'mongo'

if File.file? '.env'
  open('.env', 'r').readlines.each {|l| kv = l.split('='); ENV[kv[0]] = kv[1].strip;}
end


# DB stuff

mongo_client = Mongo::Client.new(['127.0.0.1:27017'], :database => 'myCentral')
$db = mongo_client[:interactions]

def create_interaction(interaction_id, *call_sids)
  interaction = {interaction_id: interaction_id, call_sids: call_sids}
  $db.insert_one(interaction)
end

def destroy_interaction(interaction_id)
  $db.delete_one( {interaction_id: interaction_id} )
end

def add_call_to_interaction(interaction_id, call_sid)
  interaction = $db.find( {interaction_id: interaction_id} ).first
  call_sids = interaction['call_sids']
  call_sids.push(call_sid)
  $db.update_one( {'interaction_id' => interaction_id}, 
                 {'$set' => {call_sids: call_sids}})
end

def get_calls_in_interaction(interaction_id)
  interaction = $db.find( {interaction_id: interaction_id} )
  interaction = interaction.first
  interaction ? interaction['call_sids'] : []
end


# routes

client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
# domain = 'https://secret-shelf-83431.herokuapp.com'
domain = 'http://routing.tst.talkdeskdev.com:9221'

get '/interaction' do
  interaction_id = SecureRandom.uuid
  call_sid = params['CallSid']
  create_interaction(interaction_id, call_sid)
  other_call = client.calls.create(url: "#{domain}/interaction/conference/#{interaction_id}",
                                   to: '+351937753869',
                                   from: '+19783062153')
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
  add_call_to_interaction(interaction_id, call_sid)
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
  call_sids = get_calls_in_interaction(interaction_id)
  call_sids.delete(call_sid)
  call_sids.each do |cs|
    call = client.api.calls(cs)
    call.update(url: "#{domain}/interaction/goodbye",
                method: 'GET')
  end  
  destroy_interaction(interaction_id)
end

get '/interaction/goodbye' do
  Twilio::TwiML::VoiceResponse.new do |r|
    r.say('Another person hung up. Terminating call')
    r.hangup
  end.to_s
end
