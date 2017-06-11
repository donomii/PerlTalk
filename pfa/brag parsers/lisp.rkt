#lang brag
s_expression : atomic_symbol
| "(" s_expression "." s_expression ")"
| list
list : "(" s_expression* ")"
atomic_symbol : letter atom_part
atom_part : empty
| letter atom_part
| number atom_part
letter : "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
number : "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" 
