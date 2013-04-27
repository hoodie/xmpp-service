#!/usr/bin/env coffee

xmpp      = require "node-xmpp"
events    = require 'events'
repl      = require 'repl'
fs      = require 'fs'

xmppnode  = require './xmpp-node'
xmpp_util = require "./xmpp-util"
config    = require "./config"

XmppNode = xmppnode.XmppNode
EventEmitter    = events.EventEmitter
XepAdHocCommand = xmpp_util.XepAdHocCommand

watchfiles = [
  'chat.coffee'
  'config.coffee'
  'xmpp-node.coffee'
  'xmpp-util.coffee'
]
fs.watch '.', (event, path)-> process.exit() if (path in watchfiles)and event == 'change'


global.xmpp = xmpp
global.xmpp_util = xmpp_util
global.xn  = xn = new XmppNode config.client_vector

xn.implement xmpp_util.xmpp_util
xn.connect()

xn.events.addListener 'iq.get', (stanza, xn = xn)->
  if stanza.getChild('ping')?
    console.log 'ping'
    stanza.to = stanza.from
    stanza.from = @profile.jid
    @client.send stanza

xn.events.addListener 'iq.get', (stanza, xn = xn)->
  if stanza.getChild('time')?
    console.log "time, #{stanza.from}"
    @send_message(stanza.from, "entity time is not yet implemented")


repl.start {
  prompt: "coffee-chat: "
  input: process.stdin
  output: process.stdout
  useGlobal: yes
}
