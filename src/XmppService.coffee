xmpp      = require "node-xmpp"
XmppNode      = require('./XmppNode').XmppNode

# TODO: service discovery         (XEP-0030, XEP-0128)
# TODO: ad-hoc commands           (XEP-0050)
# TODO: xml:lang for localization (read XEP-0030)
# http://xmpp.org/registrar/disco-features.html
# http://xmpp.org/registrar/disco-categories.html

#implements a discoverable service
class exports.XmppService extends XmppNode

  IDENTITY:
    name: 'coffeescript component' #@jid.domain.split('.')[0]
    category: 'test'
    type: 'test'
  ITEMS: []

  constructor: (@config) ->
    super @config

    @events.on 'iq.get', @dispatchIqGet
    @events.on 'iq.set', @dispatchIqSet

   
  ###
  # Dispatchers
  # TODO: do we need dispatchers outside XmppNode.coffee?
  ###
  dispatchIqSet: (stanza) ->

  dispatchIqGet: (stanza) ->
    if(stanza.getChild('query', @XMLNS.ITEMS))?
      @warn 'items request (UNIMPLEMENTED)'
    if(stanza.getChild('query', @XMLNS.INFO))?
      @success 'info request'
      @respondInfoResult stanza

  respondInfoResult: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@jid, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.INFO})
    query.c('identity', @identity)
    for feature in @FEATURES
      query.c('feature', {var: feature})
    @outgoing iq.toString()
    @send iq

