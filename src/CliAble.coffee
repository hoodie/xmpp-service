clc        = require 'cli-color'
class module.exports.CliAble
 
  error     : (t) -> console.error clc.redBright.bold t
  warn      : (t) -> console.log   clc.redBright.bold t
  info      : (t) -> console.log   clc.blueBright.bold t
  incomming : (t) -> console.log   clc.blackBright t
  outgoing  : (t) -> console.log   clc.yellowBright t
  success   : (t) -> console.log   clc.greenBright t

