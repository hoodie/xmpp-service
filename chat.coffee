#!/usr/bin/env coffee

xmpp      = require "node-xmpp"
events    = require 'events'
repl      = require 'repl'

xmppnode  = require './xmpp-node'
xmpp_util = require "./xmpp-util"
config    = require "./config"

XmppNode = xmppnode.XmppNode
EventEmitter    = events.EventEmitter
XepAdHocCommand = xmpp_util.XepAdHocCommand


global.xmpp = xmpp
global.xn  = xn = new XmppNode config.client_vector

xn.events.addListener 'dummy', ->
  console.log @

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

xn.connect()

repl.start {
  prompt: "coffee-chat: "
  input: process.stdin
  output: process.stdout
  useGlobal: yes
}
