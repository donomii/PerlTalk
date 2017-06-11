This is PerlTalk, something that looks and feels almost like smalltalk, but has enough changes to infuriate the experienced smalltalker.

To run:

perl perltalk.pl < program.st

Important notes:

+There are no classes.  Everything is a prototype, and you can get a fresh copy of an object with 'clone' or 'new'.

Prototype objects are:  String Array Number Current Web AnonBlock True False While Object

+You have to put full stops in more places. 

* After the | var | declarations.

this: that: anotherarg: | | .
blah.
^0.

* At the end of an anonymous block [ x + y .]

True ifTrue: [ 'True!' print . ]


* After the return ^ 42 .  Return statements are now compulsory.

this: that: anotherarg: | | .
blah.
^42.

+To set the "Current object" for the compiler to add methods to, use 

Instead of the usual way of declaring an object then immediately declaring all the methods, perltalk works a lot more like perl - you declare which object you want to add routines to, then every method declaration that is executed after that applies to the 'Current' object.  This allows for shenanigans in loops and macros etc.

Current object: myObject.
myMethod | var | . 'Hi' println. ^42.

+ Using brackets for expressions doesn't work just yet.

+ Instance variables don't exist anymore.  Instead you make a 'property' on an object.  Properties are just instance variables, but you can't access them directly.

self makeprop: 'colour'.
self colour: 'red'.
a = self colour.

