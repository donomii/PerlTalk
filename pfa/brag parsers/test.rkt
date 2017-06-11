#lang racket
(require "bnf.rkt")
(require br-parser-tools/lex)
> (define (tokenize ip)
    (port-count-lines! ip)
    
    (define my-lexer
      (let ((res
      (lexer
       ["\\" (begin (displayln "A fucking slash, was that so hard") 'SLASH)]
       [any-char (begin (display lexeme) lexeme)]
       [(eof)
        (void)])))
      ;s(displayln (res ip))
      res))
    (define (next-token) (my-lexer ip))
    
    next-token)
> (define a-sample-input-port (open-input-file "bnf/gentee.bnf"))
(port-count-lines! a-sample-input-port)
> (define token-thunk (tokenize a-sample-input-port))
; Now we can pass token-thunk to the parser:
> (define another-stx (parse "bnf/gentee.bnf" token-thunk))
> (syntax->datum another-stx)