#!/usr/bin/env coffee

xmpp         = require "node-xmpp"
events       = require 'events'
repl         = require 'repl'
fs           = require 'fs'
EventEmitter = events.EventEmitter


config      = require "./config"

global.XmppNode    = XmppNode    = require('./XmppNode').XmppNode
global.XmppService = XmppService = require('./XmppService').XmppService

watchfiles = [
  'chat.coffee'
  'config.coffee'
  'XmppNode.coffee'
  'XmppBasics.coffee'
  'XmppService.coffee'
  'XmppPresence.coffee'
]

fs.watch '.', (event, path)-> process.exit() if (path in watchfiles)and event == 'change'

global.xmpp = xmpp

global.xn  = xn = new XmppService config
xn.connect()
#xs.composeFeatures()

repl.start { prompt: "coffee-chat: ", input: process.stdin, output: process.stdout, useGlobal: yes }
