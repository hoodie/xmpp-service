clc        = require 'cli-color'
class module.exports.CliAble
 
  error     : (t) -> console.error clc.redBright.bold   "\n☠\n#{t}"
  warn      : (t) -> console.log   clc.redBright.bold   "!#{t}"
  info      : (t) -> console.log   clc.blueBright.bold  "#{t}"
 #incomming : (t) -> console.log   clc.blackBright      "#{t}"
  incomming : (t) -> console.log   clc.blackBright      "\n→\n#{t}"
  outgoing  : (t) -> console.log   clc.yellowBright     "\n←\n#{t}"
  success   : (t) -> console.log   clc.greenBright      "#{t}"

