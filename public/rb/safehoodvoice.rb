# A Tropo 'scripting API' app - this runs on Tropo's servers
# handles inbound/outbound sessions: https://www.tropo.com/docs/rest/starting_session.htm

#require 'rubygems'
#require 'json'
#require 'net/http'

callerID = $currentCall.callerID
 
say "Hello!"
record "Please say your message!", {
    :beep => true,
    :maxTime => 900,
    :transcriptionOutFormat => "json",
    #:transcriptionOutURI => "http://post-hookie.heroku.com/hook/blah",
    :transcriptionOutURI => "http://safehood.heroku.com/messages/voice",   
    :transcriptionID => callerID
    }

#def send(message, number, from)
#    log("sending '#{message}' to number: #{number} from #{from}")
#    message(message, {
#      :to => number,
#      :network => "SMS",
#      :callerID => from
#    })
#end