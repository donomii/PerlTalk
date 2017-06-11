package main

import (
    "fmt"
    "os"
    "log"
    "io/ioutil"
    "github.com/yhirose/go-peg"
)


func walkAST(ast *peg.Ast) {
    switch ast.Name {
        case "CONFIG":
        case "DBNAME":
        case "KEY":
           // dey = ast.Token
        case "VALUE":
    }   
    for _, v := range ast.Nodes {
        walkAST(v)
    }   
}

func parseString(parser *peg.Parser, str string)  *peg.Ast {
    // Parse
    parser.EnableAst()
    ret, err := parser.ParseAndGetValue(str, nil)
    if err != nil {
        log.Fatal(err)
    }
    ast := ret.(*peg.Ast)

    // Optimize AST
    opt := peg.NewAstOptimizer(nil)
    ast = opt.Optimize(ast, nil)
    return ast
}

func buildParser() *peg.Parser {
// expression    ← list ( optWs "|" optWs expression) optWs newLine
parser, err := peg.NewParser(`
  syntax        ←  rule*
  rule            ← WHITESPACE*  identifier optWs assign optWs expression optWs newLine
  starExpression ← "{" optWs expression "}" "*"? "+"?
  optExpression ← "[" optWs expression optWs "]"
  grpExpression ← "(" optWs expression optWs ")"
  mexpression    ← list / optWs "|" optWs list
  expression    ← mexpression*
  list            ← term list?
  term            ← literal1 / literal2 / identifier / starExpression / optExpression / grpExpression / ellipsis / hex / NUMBER / WHITESPACE+ / literal3
  literal1         ← "'''" / "'" literalString1* "'"
  literal2         ← '"'  literalString2* '"'
  literal3         ← literalString3
  identifier      ← "<" ruleName ">"
  lineEnd        ← (optWs / newLine) / newLine
  optWs          ← WHITESPACE*
  assign          ← "::="
  ellipsis        ← "..."
  ruleName        ← [-a-zA-Z0-9 ]+
  STRING          ←  [-a-zA-Z0-9#;_,.*/\\! ]
  literalString1   ←  symbol/ [-a-zA-Z0-9;_,.*/\\! <>{}"+]
  literalString2   ←  symbol/ [-a-zA-Z0-9;_,.*/\\! <>{}'+]
  literalString3   ←  [a-zA-Z0-9]
  NUMBER          ←  < [x0-9]+ >
  hex             ← NUMBER / 'A' / 'B' / 'C' / 'D' / 'E' / 'F' / 'a' / 'b' / 'c' / 'd' / 'e' / 'f' / 'x'
  symbol ← '!' /  '#' / '$' / '%' / '&' / '(' / ')' / '*' / '+' / ',' / '-' / '.' / '/' / '<' / '=' / '>' / '?' / '@' / '[' / [\\]  / ']' / '^' / '_' / '|' / '}' / '{' / '~' / '/' / ';' / ':' / '` +
"`" +
`'
  WHITESPACE     ← [ \t]
  newLine         ← [\n+]
`)
    if err != nil {
        log.Fatal("Error in internal parser rules: ", err)
    }

return parser
}


func main() {
    fileName := os.Args[1]

    file, err := ioutil.ReadFile(fileName)
    log.Println("Parsing ", string(file))
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(parseString(buildParser(), string(file))) 

    walkAST(parseString(buildParser(), string(file)))
}
