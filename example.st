Trace on.

Current object: Common.

methodNotFound: name reason:  reason position: position | one two three | .
'Unable to call ' vprint. 
name vprint.
' at ' vprint.
position vprint.
' because ' vprint.
reason println.
^1.


multiTest: one two: two three: three | | .
'MultiTest: ' vprint.
one vprint.
two vprint.
three println.
^1.

Trace on.


Common multiTest: 1 two: 2 three: 3 .


Primitive adsfsdf.

'Starting tests...' println.
' 1 eq 1 ... ' vprint.
Set var: 's' to: 1 in: thisContext.
Set var: 't' to: (s equal: 1) in: thisContext.
t ifTrue: [ 'True' println. 'Hi' println. ] ifFalse: ['False' println.].
' 1 eq 2 ... ' vprint.
Set var: s to: 1 in: thisContext.
Set var: t to: ( s equal: 2) in: thisContext.
t ifTrue: ['True' println.] ifFalse: ['False' println.].

'Cloning object ...' vprint.
Set var: a to: ( Object clone ) in: thisContext.




Current object: a.
'done' println.
'Making property ...' vprint.
a makeprop: 'test'.
' done ' println.
'Setting and getting property ...' vprint.
a test: 'done'.
Set var: b to: ( a test ) in: thisContext.
b println.

myPrint: val |  | .
val println.
Define var: 'b'  to: 42 in: thisContext.
^'b'.

notRun |val| . 
'This should not have run' println.
^False.

factorial: n | z  | .
z = 1.
t = n equal: 1.
t ifFalse: [
x = n subtract: 1.
y = a factorial: x.
z = y multiply: n.
" sdfsad "
].
^z.


printFac: x | | .
"'Starting factorial...' println.".
c = a factorial: x.
'Factorial of ' vprint .
x vprint. 
' is ' vprint.
c println.
^0.

a printFac: 1.
a printFac: 2.
a printFac: 3.
a printFac: 4.
a printFac: 5.
a printFac: 6.



Trace off.
'Finished' println.
