# Facebook Messages & Partychat (Jabber/XMPP/Google Talk) Group Chat Syncing #

### About ###

Meant to sync and interlope Facebook Messaging and [Partychat](http://partych.at) which allows group chat rooms using Google Talk or Jabber/XMPP. Geared toward group chat.

Ruby code built using the Sinatra framework. Very beta right now and heavily focused on my workflow/needs. This code attempts to interlop the Partychat group chat functionality of Google Talk with Facebook Messages (especially Facebook messages between groups of people). It allows the retrieving of Facebook messages and sending of messages, though again the current methods and way the code works is very specific to how I needed it and not too flexible yet.

Can be used with hosts like Heroku, Amazon AWS, AppFog, etc. Free plans are more than enough.

##### Facebook Messages to Partychat #####

Need a Facebook API access token for retrieving messages. Call this site's '/api/fb/push/threads' url to get messages. API call is only for new messages within the past few minutes. Message threads have to be in the database in order to have their messages retrieved. No friendly way to add to database yet. This site itself doesn't actually directly post to Partychat. Need to specify a post http endpoint that will do the actual posting to Partychat. I myself am using the great, free, and open sourced [Partychat Hooks](http://partychat-hooks.appspot.com). It's by [Jehiah](http://jehiah.cz). So this would allow multiple Facebook threads to be posted to a single Partychat room. This app assumes you are creating a hook for each Facebook thread.

##### Partychat to Facebook Messages #####

Need to a Facebook account's username and password to send messages from Partychat to Facebook. This also uses [Partychat Hooks](http://partychat-hooks.appspot.com). A message will be sent to Facebook if it starts with what you specify as the hook command. For example if you choose "send", then sending a message beginning with /send in a Partychat room will then push from Partychat to an http endpoint you specify with the hooks. Currently that end point is '/api/fb/pull/:thread' with :thread being the thread short-name you specify in the database.

#### Notes ####

__Pulling in [new] Facebook Messages___:
The code for retrieving new FB messages is written with a few assumptions:
  (1) Script is being run frequently enough so as to almost always need to retrieve not even the last 25 messages
  (2) More than 25 new messages won't pile up at the pace the script is being run
  
So if the retrieving of Facebook messages is run every minute, the hope is no more than 25 new messages come within the 60 seconds since the script is last run.
Fixing this isn't difficult though. FB Api allows easy pagination.

__Not User friendly__:
Currently the instructions and way of using this is not user friendly. No one is using this except for me so haven't had problems yet. If you are having issues or would like changes to make things easier to use, let me know.

[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/e5b321591d1fbd4b9c511068bb18706e "githalytics.com")](http://githalytics.com/iknowicouldalwaysturn/facebook-partychat)
