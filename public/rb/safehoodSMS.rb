# A Tropo 'scripting API' app - this runs on Tropo's servers
# handles inbound/outbound sessions: https://www.tropo.com/docs/rest/starting_session.htm

require 'rubygems'
require 'json'
require 'net/http'

def send(message, number, from)
    log("sending '#{message}' to number: #{number} from #{from}")
    message(message, {
      :to => number,
      :network => "SMS",
      :callerID => from
    })
end


outbound = $message ? true : false

if outbound
  # send sms out to the group
  msg = $message
  numbers = $numbers
  from = $callerId
  numbers = numbers.split(',')
  numbers.each {|n| send(msg,n,from)}
else
  if $currentCall.initialText =~ /^?nyan/i
    callID = $currentCall.callerID
    hangup
    call [callID], {
     :timeout => 120,
     :callerID => '15102213861',
     :onAnswer => lambda {
       say "http://nyan.cat/mp3s/nyan-looped.mp3"
       log "Obnoxious call complete"},
     :onTimeout => lambda {
       say "Call timed out" },
     :onCallFailure => lambda {
       log "Call could not be complete as dialed" }
    }
  else
    # send incoming texts to our server
    Net::HTTP.post_form( 
      URI.parse("http://safehood.heroku.com/messages/receive"), {
        :message => $currentCall.initialText,
        :incoming_number => $currentCall.calledID,
        :origin_number => $currentCall.callerID
      })
  end
end