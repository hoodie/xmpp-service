xmpp      = require "node-xmpp"
CliAble = require('./CliAble').CliAble



class exports.XmppPresence extends CliAble

  constructor: (@profile, @connection) ->

  send: (to = @profile.maintainer_jid, set_interval = true)->
    # tell everybody
    if to?
      p = new xmpp.Element('presence', {to: to})
    else
      p = new xmpp.Element('presence')
    p.c('priority').t(@profile.priority) if @profile.priority?
    @connection.send p
    @outgoing p.toString()
    # keep alive
    if set_interval
      setInterval (=>
        @send(to, false)
        console.log Date(), 'online'
      )
      ,1000 * 120

  probe: (buddy) ->
    presence = new xmpp.Element('presence', {type: 'probe', to: buddy})
    @connection.send presence

  setStatusMessage: (message, to = null) ->
    help = -> console.log "setStatusMessage()"
    @setStatus '', message, to

  setStatus: (show, message, to = null) ->
    status = @STATUSES[show.toUpperCase()]

    presence = if to? then new xmpp.Presence {to: to} else new xmpp.Presence()

    presence.c("status").t(message) if message?
    if show? and status?
      presence.c("show").t(status)
    @connection.send presence

  handlePresence: -> @info 'presence'
