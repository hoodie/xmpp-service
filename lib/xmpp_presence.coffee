xmpp      = require "node-xmpp"
CliAble = require('./cli_able').CliAble

# TODO: Entity Capabilities       (XEP-0115)
# TODO: Last Activity             (XEP-0012)
# TODO: Last Activity in Presence (XEP-0256)

class exports.XmppPresence extends CliAble

  SHOW:
    AVAILABLE : 'available'
    CHAT      : 'chat'
    AWAY      : 'away'
    DND       : 'dnd'
    XA        : 'xa'
    ONLINE    : 'online'
    OFFLINE   : 'offline'

  constructor: (@node) ->
    {@config} = @node
    @presenceInterval = 300
    show: @SHOW.XA
    status: ''


  send: (to = @config.maintainer_jid)->
    # tell everybody
    presence = if to? then new xmpp.Presence {to: to} else new xmpp.Presence()
    presence.c('priority').t(@config.priority) if @config.priority?
    presence.c('show').t(@show)                if @show?
    presence.c('status').t(@status)            if @status?
    @node.send presence
    # keep alive


  keep_alive: (interval = @presenceInterval) ->
    clearInterval @intervalId if @intervalId?
    @send()
    @intervalId = setInterval (=>
      @send()
      d = new Date()
      console.log "(#{d.getHours()}:#{d.getMinutes()}) #{@show}:: \"#{@status}\""
    )
    ,1000 * interval




  setShow: (show, message, to = null) ->
    show = @STATUSES[show.toUpperCase()]
    presence.c("status").t(message) if message?
    if show? and status?
      presence.c("show").t(status)

  subscribe: (jid) ->
    @node.send new xmpp.Presence {to: jid, type: 'subscribe'}

  unsubscribe: (jid) ->
    @node.send new xmpp.Presence {to: jid, type: 'unsubscribe'}

  acceptUnsubscribe: (jid) ->
    @node.send new xmpp.Presence {to: jid, type: 'unsubscribed'}

  handlePresence: -> @info 'presence'
