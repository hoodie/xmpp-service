xmpp      = require "node-xmpp"
XmppNode      = require('./XmppNode').XmppNode

# TODO: service discovery         (XEP-0030, XEP-0128)
# TODO: ad-hoc commands           (XEP-0050)
# TODO: xml:lang for localization (read XEP-0030)
# http://xmpp.org/registrar/disco-features.html
# http://xmpp.org/registrar/disco-categories.html

#implements a discoverable service
class exports.XmppService extends XmppNode

  IDENTITIES: [
    #name = @JID.domain.split('.')[0]
    { category: 'client', type: 'pc', name: 'sort of a client bot'}
  ]

  ITEMS:
    alpha:
      name:'alpha', callback: -> console.log 'alpha'
    beta:
      name:'beta', callback: -> console.log 'beta'
  PRIVATE_ITEMS: # only visible to same JID
    exit:
      name:'End Process', callback: -> process.exit()
  
  #REMOTECONTROL: # TODO XEP 0146


  constructor: (@config) ->
    super @config
    @FEATURES.push @XMLNS.COMMANDS


  ###
  # Dispatchers
  # TODO: do we need dispatchers outside XmppNode.coffee?
  ###
  dispatchIqSet: (stanza) ->
    super(stanza)
    commands = stanza.getChildren('command', @XMLNS.COMMANDS)
    @handleCommands commands

  dispatchIqGet: (stanza) ->
    super(stanza)

    if(stanza.getChild('query', @XMLNS.ITEMS))?
      #@warn 'items request'

      for query in stanza.getChildrenByAttr('node', @XMLNS.COMMANDS)
        #@warn 'commands request'
        @sendItems stanza
        #@sendChat(stanza.from,"#{@XMLNS.COMMANDS} is not yet implemented.  (#{stanza.children[1].attrs.xmlns})") # FIXME

    if(stanza.getChild('query', @XMLNS.INFO))?
      @success 'info request'
      @sendInfo stanza


  sendItems: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.ITEMS, node:@XMLNS.COMMANDS})
    # TODO XEP-0146
    #for node, item of @REMOTECONTROL
    #  query.c('item',{jid: @JID , name: item.name, node: "http://jabber.org/protocol/rc##{node}"})

    # TODO XEP-0050
    from = new xmpp.JID stanza.from
    if @jidIsPrivileged(from)
      for node, item of @PRIVATE_ITEMS
        query.c('item',{jid: @JID , name: item.name, node: node})
    for node, item of @ITEMS
      query.c('item',{jid: @JID , name: item.name, node: node})
    @send iq


  jidIsPrivileged: (jid)->
    jid = new xmpp.JID(jid) if typeof jid == 'string'

    jid.bare().toString() == @JID.bare().toString() or
      jid.bare().toString() == new xmpp.JID(@config.maintainer_jid).bare().toString()




  sendInfo: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.INFO})
    for identity in @IDENTITIES
      query.c('identity', identity)
    for feature in @FEATURES
      query.c('feature', {var: feature})
    @send iq

  handleCommands: (commands) ->
    for command in commands
      if command.attrs.node in Object.keys @ITEMS
        @ITEMS[command.attrs.node].callback.call()
    if @jidIsPrivileged(command.parent.from)
      if command.attrs.node in Object.keys @PRIVATE_ITEMS
        @PRIVATE_ITEMS[command.attrs.node].callback.call()
