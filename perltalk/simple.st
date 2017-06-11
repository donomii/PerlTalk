'Starting file' println.
Current object: Common.
a := Object clone.
b := a.
c := b asString.
c vprint.
'---------' vprint.
c hashdump.
testArg: arg1 testThing: arg2
| var1 var2 var3 var |
file := file.
arr := Array new.  "Unary send"
arr := Array new: 20 .  "send with arg"
subArr := arr from: 0 to: 10.  "multi send"
otherArray := Array with: 123 with: 'ab''c' copy with: 2.44. "unary precedence in multi call"
anonBlock := [ 1 add: 2 ] .
anonBlock := [ :x :y | x add: y ] .
arr := [ Array new ].  "Unary send"
arr :=  [ Array new: 20 ] .  "send with arg"
subArr := [ arr from: 0 to: 10 ] .  "multi send"
otherArray := [ Array with: 123 with: 'ab''c' copy with: 2.44 ] . "unary precedence in multi call"
anonBlock := [ 1 add: 2 ] .

^file close.

'File done' println.

'asdf' notamethod.
