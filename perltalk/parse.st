Trace off.

Current object: Common.


methodNotFound: name reason:  reason position: position | one two three | .
'Unable to call ' vprint. 
name vprint.
' at ' vprint.
position vprint.
' because ' vprint.
reason println.
^1.

Trace off.


'Please enter a program, on one line' println.
prog = Io readLine.
'Read this program' println.
prog println.
letters = prog explode.

For = String new.
Current object: For.
all: array do: routine | one two three | .
'Iterating over ' vprint.
array vprint.
' with ' vprint.
routine vprint.
routine exec.
^1 .

For all: letters do: [ stuff |
'Did exec!' vprint.
b = letters at: 1.
'Selected: ' vprint.
b println.
] .

'Finished' println.
