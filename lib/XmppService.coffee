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
    node_alpha:
      name:'item alpha', jid: 'blub.nodejs.localhost'
    node_beta:
      name:'item beta', subjid: 'blub'

  COMMANDS:
    alpha:
      name:'command alpha', callback: -> console.log 'alpha'
    beta:
      name:'command beta', callback: -> console.log 'beta'

  PRIVATE_COMMANDS: # only visible to same JID
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

    if(query = stanza.getChild('query', @XMLNS.ITEMS))?
      if query.attrs.node == @XMLNS.COMMANDS
        @warn 'commands request'
        @handleIqCommands stanza
      else
        @warn 'items request'
        @handleIqItems stanza

    if(stanza.getChild('query', @XMLNS.INFO))?
      @success 'info request'
      @handleIqInfo stanza


  handleIqItems: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.ITEMS})
    for node, item of @ITEMS
      if item.subjid?
        query.c('item',{jid: item.subjid+'@'+@JID.bare() , name: item.name, node: node})
      else
        query.c('item',{jid: item.jid , name: item.name, node: node})
    @send iq

  handleIqCommands: (stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.ITEMS, node:@XMLNS.COMMANDS})
    # TODO XEP-0146
    #for node, item of @REMOTECONTROL
    #  query.c('item',{jid: @JID , name: item.name, node: "http://jabber.org/protocol/rc##{node}"})

    # TODO XEP-0050
    from = new xmpp.JID stanza.from
    if @jidIsPrivileged(from)
      for node, item of @PRIVATE_COMMANDS
        query.c('item',{jid: @JID , name: item.name, node: node})
    for node, item of @COMMANDS
      query.c('item',{jid: @JID , name: item.name, node: node})
    @send iq


  handleIqInfo: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.INFO})
    for identity in @IDENTITIES
      query.c('identity', identity)
    for feature in @FEATURES
      query.c('feature', {var: feature})
    @send iq



  jidIsPrivileged: (jid)->
    jid = new xmpp.JID(jid) if typeof jid == 'string'

    jid.bare().toString() == @JID.bare().toString() or
      jid.bare().toString() == new xmpp.JID(@config.maintainer_jid).bare().toString()


  handleCommands: (commands) ->
    for command in commands
      if command.attrs.node in Object.keys @COMMANDS
        @COMMANDS[command.attrs.node].callback.call()
    if @jidIsPrivileged(command.parent.from)
      if command.attrs.node in Object.keys @PRIVATE_COMMANDS
        @PRIVATE_COMMANDS[command.attrs.node].callback.call()
