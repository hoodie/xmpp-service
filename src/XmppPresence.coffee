xmpp      = require "node-xmpp"
CliAble = require('./CliAble').CliAble

# TODO: Entity Capabilities       (XEP-0115)

class exports.XmppPresence extends CliAble

  STATUSES:
    AVAILABLE : 'available'
    CHAT      : 'chat'
    AWAY      : 'away'
    DND       : 'dnd'
    XA        : 'xa'
    ONLINE    : 'online'
    OFFLINE   : 'offline'

  constructor: (@node) ->
    {@config} = @node
    @presenceRefresh = 10


  send: (to = @config.maintainer_jid, set_interval = true)->
    # tell everybody
    if to?
      p = new xmpp.Element('presence', {to: to})
    else
      p = new xmpp.Element('presence')
    p.c('priority').t(@config.priority) if @config.priority?
    @node.send p
    # keep alive
    if set_interval
      setInterval (=>
        @send(to, false)
        console.log Date(), 'online'
      )
      ,1000 * @presenceRefresh

  setStatus: (show, message, to = null) ->
    status = @STATUSES[show.toUpperCase()]

    presence = if to? then new xmpp.Presence {to: to} else new xmpp.Presence()

    presence.c("status").t(message) if message?
    if show? and status?
      presence.c("show").t(status)
    @node.send presence

  probe: (buddy) ->
    presence = new xmpp.Presence {type: 'probe', to: buddy}
    @node.send presence

  subscribe: (jid) ->
    @node.send new xmpp.Presence {to: jid, type: 'subscribe'}

  unsubscribe: (jid) ->
    @node.send new xmpp.Presence {to: jid, type: 'unsubscribe'}

  acceptUnsubscribe: (jid) ->
    @node.send new xmpp.Presence {to: jid, type: 'unsubscribed'}

  handlePresence: -> @info 'presence'
