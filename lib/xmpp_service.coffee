xmpp      = require "node-xmpp"
events    = require 'events'
clc        = require 'cli-color'

EventEmitter = events.EventEmitter
XmppPresence = require('./xmpp_presence').XmppPresence

# TODO: Donate tu Uganda (VIM is Charityware)
# TODO: PubSub                    (XEP-0060)
# TODO: Entity Capabilities       (XEP-0115)
# TODO: Delayed Delivery          (XEP-0203)
# TODO: Message Delivery Receipts (XEP-0184)
#
# TODO: service discovery         (XEP-0030, XEP-0128)
# TODO: ad-hoc commands           (XEP-0050)
# TODO: xml:lang for localization (read XEP-0030)
#
# http://xmpp.org/registrar/disco-features.html
# http://xmpp.org/registrar/disco-categories.html
#
# TODO: rethink:
# NODES
#   NODE
#     IDENTITY
#     FEATURES
#     COMMANDS



## basically routes stanza events to different dispatchrs
class exports.XmppService

  XMLNS:
    ITEMS:    'http://jabber.org/protocol/disco#items'
    INFO:     'http://jabber.org/protocol/disco#info'
    PING:     'urn:xmpp:ping'
    TIME:     'urn:xmpp:time'
    ROSTER:   'jabber:iq:roster'
    COMMANDS: 'http://jabber.org/protocol/commands'


  FEATURES: [
    'http://jabber.org/protocol/disco#info'  # (XEP-0030 Service Discovery)
    'http://jabber.org/protocol/disco#items' # (XEP-0030 Service Discovery)
    'urn:xmpp:ping'                          # (XEP-0199) XMPP Ping
    'urn:xmpp:receipts'                      # (XEP-0199) XMPP Ping
    'urn:xmpp:time'                          # (XEP-0202) Entity Time
   #'urn:xmpp:version'                       # (XEP-0092) Software Version # NOT IMPLEMENTED
    'http://jabber.org/protocol/commands'
  ]

  TYPES:
    CLIENT: 'client'
    COMPONENT: 'component'

  IDENTITIES: [
    #name = @JID.domain.split('.')[0]
    { category: 'client', type: 'pc', name: 'Coffeescript XmppService'}
  ]

  ITEMS:
    node_alpha:
      name:'item alpha-parent', subjid: 'alpha', type: 'node', category: 'test', nodes:
        node_alpha_child:
          name:'item alpha-child', subjid: 'alpha2'
    node_beta:
      name:'item beta', subjid: 'beta', type: 'directory', category: 'test', nodes:
        name:'item beta-child', subjid: 'beta2', type: 'node', category: 'test'


  ## attrs: jid?, subjid?,
  #  identity: type, category
  #addItem: (name, attrs, identity?, callback = undefined) ->


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
    {@host, @jid, @type} = @config
    @__defineGetter__ 'JID' , -> new xmpp.JID @jid

    @events = new EventEmitter()
    @presence = new XmppPresence this

    if @TYPES[@config.type] == @TYPES.CLIENT
      @events.on 'online', => @requestRoster()

    @stanzas = []
    @events.on 'send',     @stanzaPrint
    #@events.on 'stanza',   @stanzaPrint
    @events.on 'stanza',   (stanza) => @stanzas.push stanza
    @events.on 'message',  ->
    @events.on 'presence', ->
    @events.on 'iq',       ->
    @events.on 'iq.get',   @stanzaPrint
    @events.on 'iq.set',   ->

  connect: () ->
    @info 'connecting...'
    @timelabel = "connecting #{@JID}"
    console.time @timelabel
    switch @TYPES[@type]
      when 'client' then @connection = new xmpp.Client @config
      when 'component' then @connection = new xmpp.Component @config
      else
        @connection = undefined
        throw new Error "Undefined type off connection - Check config.coffee"

    @connection.on 'online', =>
      console.timeEnd @timelabel
      @success '...connected!'
      @events.emit 'online'
      @presence.send() if @TYPES[@type] == 'client'

    @connection.on 'stanza', (stanza) =>
      @dispatchStanza stanza

    @connection.on 'error', (error) ->
      throw error
    return

  send: (stanza) ->
    @events.emit 'send', stanza
    @connection.send stanza

  sendChat: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @send(stanza)

  sendMessage: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'message' })
    stanza.c('body').t(message)
    @send(stanza)

  sendHeadline: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'headline' })
    stanza.c('body').t(message)
    @send(stanza)

  requestRoster:  ->
    # TODO: implement watching for return ids
    iq = new xmpp.Iq { id: 'roster42', type: 'get' }
    iq.c 'query', { xmlns: @XMLNS.ROSTER }
    @send iq


  ###
  # Dispatchers
  ###
  dispatchStanza: (stanza) ->
    @events.emit 'stanza', stanza
    switch stanza.name
      when 'message'  then @dispatchMessage stanza
      when 'presence' then @dispatchPresence stanza
      when 'iq'       then @dispatchIq stanza
      else @error "!", stanza.toString()

  dispatchPresence: (stanza) ->
    @events.emit 'presence', stanza

  dispatchIq: (stanza) ->
    @events.emit 'iq', stanza
    switch stanza.type
      when 'get' then @dispatchIqGet stanza
      when 'set' then @dispatchIqSet stanza
      when 'result' then @dispatchIqResult stanza
      else console.log stanza.type, stanza.attrs

  dispatchIqGet: (stanza) ->
    @events.emit 'iq.get', stanza
    @handleGetPing(stanza) for ping in stanza.getChildren('ping', @XMLNS.PING) # (XEP-0199) XMPP Ping
    @handleGetTime(stanza) for time in stanza.getChildren('time', @XMLNS.TIME) # (XEP-0202) Entity Time
    if(query = stanza.getChild('query', @XMLNS.ITEMS))?
      if query.attrs.node == @XMLNS.COMMANDS
        @warn "commands request from  #{stanza.from}"
        @handleGetIqCommands stanza
      else
        @info "items request to node \"#{query.attrs.node}\" subjid: \"#{@getSubJid stanza.to}\""
        @handleGetIqItems stanza

    if(stanza.getChild('query', @XMLNS.INFO))?
      @success 'info request'
      @handleGetIqInfo stanza

  dispatchIqSet: (stanza) ->
    @warn 'iq type=set'
    commands = stanza.getChildren('command', @XMLNS.COMMANDS)
    @handleSetCommands commands

  dispatchIqResult: (stanza) ->
    @handleGetRoster(roster) for roster in stanza.getChildren('query', @XMLNS.ROSTER)

    #@handleGetRoster stanza if stanza.getChild()

  dispatchMessage: (stanza) ->
    @handleGetMessage stanza


  ###
  # handleGets
  ###
  handleGetMessage: (message) =>
    console.log "#{clc.magenta.bold(message.from)}:
    #{clc.white.bold(message.getChildText('body'))}"

  # XEP-0202: Entity Time
  handleGetTime: (stanza) ->
    date = new Date()
    iq = new xmpp.Iq {type: 'result', from: @JID, to: stanza.from, id: stanza.id}
    iq.c('time', {xmlns: @XMLNS.TIME})
      .c('tzo').t(date.getTimezoneOffset()).up()
      .c('utc').t(date.toISOString())
    @connection.send iq

  # XEP-0199: XMPP Ping
  handleGetPing: (stanza) ->
    @warn 'PING', @XMLNS.PING
    iq = new xmpp.Iq {type: 'result', from: @JID, to: stanza.from, id: stanza.id}
    @connection.send iq

  handleGetRoster: (query) ->
    @roster = for item in query.getChildren 'item'
      {name,jid} = item.attrs
      {name,jid}

  handleGetIqItems: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.ITEMS})
    for node, item of @ITEMS
      if item.subjid?
        query.c('item',{jid: item.subjid+'@'+@JID.bare() , name: item.name, node: node})
      else
        query.c('item',{jid: item.jid , name: item.name, node: node})
    @send iq

  handleGetIqCommands: (stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.ITEMS, node:@XMLNS.COMMANDS})
    # TODO XEP-0146
    #for node, item of @REMOTECONTROL
    #  query.c('item',{jid: @JID , name: item.name, node: "http://jabber.org/protocol/rc##{node}"})

    # TODO XEP-0050
    from = new xmpp.JID stanza.from

    if @jidIsPrivileged(from)
      @success "#{from} is priviledged"
      for node, item of @PRIVATE_COMMANDS
        query.c('item',{jid: @JID , name: item.name, node: node})
    else
      @warn "#{from} not priviledged"

    for node, item of @COMMANDS
      query.c('item',{jid: @JID , name: item.name, node: node})
    @send iq


  handleGetIqInfo: (stanza = new xmpp.Stanza) ->
    iq = new xmpp.Iq {type: 'result', to:stanza.from, from:@JID, id:stanza.id}
    query = iq.c('query', {xmlns:@XMLNS.INFO})
    for identity in @IDENTITIES
      query.c('identity', identity)
    for feature in @FEATURES
      query.c('feature', {var: feature})
    @send iq



  handleSetCommands: (commands) ->
    for command in commands
      @COMMANDS[command.attrs.node]?.callback.call()

      if @jidIsPrivileged(command.parent.from)
        @PRIVATE_COMMANDS[command.attrs.node]?.callback.call()

  # TODO: push upstream node-xmpp/lib/xmpp/jid.js
  # TODO: also FIX equals() and constructor to accept string and jid
  sanitizeJid: (jid) ->
    jid = new xmpp.JID(jid) if typeof jid == 'string'
    jid.bare()

  getSubJid: (jid) ->
    jid = @sanitizeJid jid
    jid.user if @JID.user != jid.user

  jidIsPrivileged: (jid) ->
    jid = @sanitizeJid jid
    maintainer_jid = @sanitizeJid @config.maintainer_jid

    jid.bare().equals(@JID.bare())or jid.bare().equals maintainer_jid

  stanzaPrint: (stanza) =>
    unless stanza.type == 'error' or not stanza.to?
      to = new xmpp.JID(stanza.to)
      if to.bare().equals @JID.bare()
        if @getSubJid(to)?
          @incomming2 stanza.toString()
        else
          @incomming stanza.toString()
      else
        @outgoing stanza.toString()
    else
      @error stanza.toString()

  error      : (t) -> console.error clc.redBright.bold   "\n☠\n#{t}"
  warn       : (t) -> console.log   clc.redBright.bold   "!#{t}"
  info       : (t) -> console.log   clc.blueBright.bold  "#{t}"
 #incomming  : (t) -> console.log   clc.blackBright      "#{t}"
  incomming  : (t) -> console.log   clc.xterm(120)       "\n→ #{t}"
  incomming2 : (t) -> console.log   clc.xterm(250)       "\n→ #{t}"
  outgoing   : (t) -> console.log   clc.xterm(230)       "\n← #{t}"
  success    : (t) -> console.log   clc.greenBright      "#{t}"

