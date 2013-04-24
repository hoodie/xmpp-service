
exports.xmpp_util = {

  STATUSES:
    AVAILABLE : 'available'
    CHAT      : 'chat'
    AWAY      : 'away'
    DND       : 'dnd'
    XA        : 'xa'
    ONLINE    : 'online'
    OFFLINE   : 'offline'

  listeners: 'foo'


  sendMessage: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @client.send(stanza)
    console.log clc.green stanza.toString()

  
  setStatusMessage: (message, to = null) -> @setStatus '', message, to

  setStatus: (show, message, to = null) ->
    status = @STATUSES[show.toUpperCase()]

    presence = if to? then new xmpp.Presence {to: to} else new xmpp.Presence()

    presence.c("status").t(message) if message?
    if show? and status?
      presence.c("show").t(status)
    presence.toString()

}
class XepAdHocCommand
  constructor: (@title, @function) ->

exports.XepAdHocCommand = XepAdHocCommand
