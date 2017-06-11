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
s = 1.
t = s equal: 1.
t ifTrue: [ 'True' println. 'Hi' println. ] ifFalse: ['False' println.].
' 1 eq 2 ... ' vprint.
s = 1.
t = s equal: 2.
t ifTrue: ['True' println.] ifFalse: ['False' println.].

'Cloning object ...' vprint.
a = Object clone.




Current object: a.
'done' println.
'Making property ...' vprint.
a makeprop: 'test'.
' done ' println.
'Setting and getting property ...' vprint.
a test: 'done'.
b = a test.
b println.

myPrint: val |  | .
val println.
b  = 42.
^b.

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
