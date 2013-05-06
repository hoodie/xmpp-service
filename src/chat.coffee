#!/usr/bin/env coffee

xmpp         = require "node-xmpp"
events       = require 'events'
repl         = require 'repl'
fs           = require 'fs'

xmppNode     = require './XmppNode'
xmppBasics   = require './XmppBasics'
config       = require "./config"

EventEmitter = events.EventEmitter

global.XmppNode     = XmppNode     = xmppNode.XmppNode
global.XmppBasics   = XmppBasics   = xmppBasics.XmppBasics

watchfiles = [
  'chat.coffee'
  'config.coffee'
  'XmppNode.coffee'
  'XmppBasics.coffee'
]
fs.watch '.', (event, path)-> process.exit() if (path in watchfiles)and event == 'change'


implementing = (mixins..., classReference) ->
  for mixin in mixins
    for key, value of mixin.prototype
      classReference.prototype[key] = value
  classReference

class XmppComposed extends XmppNode
XmppComposed = implementing XmppBasics, XmppNode, XmppComposed

global.xmpp = xmpp

#global.xn  = xn = new XmppNode config.client_vector
#global.xn = new XmppNode config.client_vector
#global.xb = new XmppBasics config.client_vector
global.xc = new XmppComposed config.client_vector

xc.handlePresence()
xc.dummyTest()


repl.start {
  prompt: "coffee-chat: "
  input: process.stdin
  output: process.stdout
  useGlobal: yes
}
