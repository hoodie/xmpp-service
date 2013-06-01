#!/usr/bin/env coffee

xmpp         = require "node-xmpp"
events       = require 'events'
repl         = require 'repl'
fs           = require 'fs'
request      = require 'request'
EventEmitter = events.EventEmitter

global.url = (station) -> "http://widgets.vvo-online.de/abfahrtsmonitor/Abfahrten.do?ort=Dresden&hst=#{station}&vz=0"

global.request = request

request url('slub'),(err, response, body) ->
  JSON.parse body

repl.start { prompt: "repl: ", input: process.stdin, output: process.stdout, useGlobal: yes }
