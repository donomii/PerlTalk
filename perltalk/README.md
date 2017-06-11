# PerlTalk

Failed project

PerlTalk was an attempt to write a Smalltalk interpreter in Perl.  It partially works - it can parse a SmallTalk program (written in a variant of smalltalk), but can't fully execute it.  Most types of function calls work, but defining functions does not work.

## Post Mortem

There were several issues that ocntributed to this not working.  The main problem was that I didn't fully understand, or plan, the execution model I was using.  Instead of choosing a clear execution model and following it, I simply hacked bits of functionality together as the need arose, resulting in a model that is extremely difficult to understand, and finally resulting in a bug that causes the interpreter to go into a loop when trying to return from a function.

The situation was further complicated by attempting a new kind of parser that didn't work as well as I had hoped.  I based the parser on the nanopass compiler described in https://www.cs.indiana.edu/~dyb/pubs/nano-jfp.pdf (A Nanopass Framework for Compiler Education: Sarkar, Waddell, Dybvig).  This was not an ideal choice for several reasons:

* The compiler described is targetted to a functional dialect of Scheme, which makes applying it to SmallTalk more difficult.

Scheme is at heart a procedural language, but it can pretend to be functional when needed.  SmallTalk is an OO language that can pretend to be functional, but it takes a lot more work, and the functional features are heavily obscured behind the OO features.  For instance, Smalltalk supports lambda functions, and they are first class, but smalltalk lambdas are made of Statements, rather than Expressions, adding a complication that scheme lacks (as everything is an expression in scheme).

* I didn't use the recommended data structure (S-Expressions), making it harder to adapt the techniques from the paper.

Instead I used a tree of objects, and used inheritence to provide methods for manipulating the parse tree.  This way I could override default actions wuth specific actions for certain special functions (like return!).  This worked well to begin with, but became a nightmare to debug, because I couldn't see which function was actually being called.

* I attempted to use the techniques for the parser, as well as the compiler.

I tried to get fancy and write a parser by creating a generic node for each token in the input stream, and then having each node examine the nodes around it to decide how to build itself into the tree.  Effectively, I made a tree that was one long line (one branch), and then tried to re-organise it into a tree by applying many transforms to each node.

This is roughly what was recommended in the paper, except that the paper didn't suggest applying it to such a primitive parse (it talked about applying transformations to a pre-built parse tree)

This actually worked pretty well, but maintaining the transformation rules quickly became confusing and irritating.  It relied very heavily on precedence of the rules to build a correct parse tree.

e.g. the rules for building an expression had to run before the rules for building a statement, so I had to introduce an intermediate node type, PROTO-EXPRESSION, while building numbers and operators into a real EXPRESSION.  These intermediate types complicate the code, because it isn't easy to understand why PROTO-EXPRESSION exists without knowing all the other rules involving expressions and statements.  I see this as the important problem with the nanopass idea.

* I wasn't actually writing a compiler, but an interpreter, so there wasn't much need for compiler techniques anyway.

All I really needed was a parse tree and a functioning interpreter engine.  There wasn't really a call for compiler transformations, a simple recursive descent parser would produce an acceptable tree.  These techniques would work much better in a host language like C, where the language provides much less help in manipulating arrays and trees.
