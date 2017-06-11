#lang brag
  syntax         : rule [ syntax ] .
  rule           : opt-ws  identifier opt-ws "::=" opt-ws expression opt-ws EOL .
  expression     : list [ "|" expression ] .
  line-end       : opt-ws EOL | line-end line-end .
  list           : term [ WHITESPACE list ] .
  term           : literal | identifier .
  identifier     : "<" character+ ">" .
  literal        : "'" character* "'" | '"'  character* '"' .
  opt-ws         : WHITESPACE* .
  character      : lowercase-char | uppercase-char | digit | special-char .
  lowercase-char : "a" | "b" | "..." | "z" .
  uppercase-char : "A" | "B" | "..." | "Z" .
  digit          : "0" | "1" | "..." | "2" .
  special-char   : "-" | "_" .