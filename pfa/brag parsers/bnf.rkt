#lang brag
  syntax          : rule [ syntax ] .
  rule            : opt-ws  identifier opt-ws assign opt-ws expression opt-ws EOL .
  one-expression  : list [ "|" expression ] .
  star-expression : "{" opt-ws expression opt-ws "}" .
  opt-expression  : "[" opt-ws one-expression opt-ws "]" .
  grp-expression  : "(" opt-ws one-expression opt-ws ")" .
  expression      : one-expression | opt-expression .
  line-end        : opt-ws EOL | line-end line-end .
  list            : term [ WHITESPACE list ] .
  term            : literal | identifier .
  identifier      : "<" character+ ">" .
  literal         : "'" character* "'" | '"'  character* '"' .
  opt-ws          : WHITESPACE* .
  character       : lowercase-char | uppercase-char | digit | special-char .
  assign          : ":" ":" "="
  lowercase-char  : "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" .
  uppercase-char : "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" .
  digit : "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" 
  special-char   : "-" | "_" .
  space          : " " .
  WHITESPACE     : " " | "  " | "\n" .
  symbol         :  "|" | " " | "-" | "!" | "#" | "$" | "%" | "&" | "(" | ")" | "*" | "+" | "," | "-" | "." | "/" | ":" | ";" | "<" | "=" | ">" | "?" | "@" | "["  | "]" | "^" | "_" | "`" | "{" | "|" | "}" | "~" .
  slash    : "SLASH" .