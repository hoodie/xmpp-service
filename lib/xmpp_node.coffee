xmpp      = require "node-xmpp"
events    = require 'events'
clc        = require 'cli-color'

class exports.Node extends CliAble



  IDENTITY:
    { category: 'client', type: 'pc', name: 'sort of a client bot'}
  FEATURES: {}
  COMMANDS: {}

  constructor: ->

  addFeature: (feature) -> FEATURES.push feature
