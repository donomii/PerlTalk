#lang brag
syntax : statement*.
statement : identifier "=" expression ".".
identifier : letter (letter|digit)*.
letter : "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
digit : "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" 
expression : term ("|" term)*.
term : factor factor*.
factor : identifier | string | "(" expression ")" | "[" expression "]" | "{" expression "}".
string : (letter | digit) ( letter | digit ) ( letter | digit )*
