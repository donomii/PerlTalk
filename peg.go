package main

import (
    "strings"
    "fmt"
    "os"
    "log"
    "io/ioutil"
    "github.com/yhirose/go-peg"
)


var indent = 0
var indentStep = 4

func startParse(ast *peg.Ast, rulesTable map[string]*peg.Ast,  input, startRule, chain string, start int) (int, bool) {
    pos, ok := doParse(rulesTable[startRule], rulesTable, input, chain, start)
    return pos, ok
}
func doParse(ast *peg.Ast, rulesTable map[string]*peg.Ast,  input, chain string, start int) (int, bool) {
    pos := start
    ok := false
    newchain := fmt.Sprintf("%v->%v(%v)", chain, ast.Name, ast.Token)
    if len(newchain) > 2000 {
        log.Fatal("Deep recursion")
    }
    switch ast.Name {
        case "expression":
        for i, v := range ast.Nodes {
            pos, ok = doParse(v, rulesTable, input, newchain, pos)
            if !ok {
                //But wait!  If the next item in the expression has the optional flag, we can try that instead of failing
                //Are we at the last node?
                if !(i < len(ast.Nodes)-1) {
                    log.Println("Failed to match last element in expression ", ast," aborting")
                    return start, false
                }
                //Is the next node optional?
                if findChildNamed(ast.Nodes[i+1], "optionalMarker") == nil {
                    log.Println("Next element is optional, continuing loop")
                    return start, false
                }
                //Continue loop at next node
            } else {
                return pos, ok
            }
        }
        return start, false
        /*case "rule":
            pos, ok = doParse(findChildNamed(ast, "ruleDecl"), rulesTable, input, newchain, pos)
                if !ok {
                    return start, ok
                }
            pos, ok = doParse(findChildNamed(ast, "expression"), rulesTable, input, newchain, pos)
                if !ok {
                    return start, ok
                }
            return pos, true
        */
        case "WHITESPACE":
            return pos, true
        /*    if input[pos:pos+1] == " " {
                pos = pos + 1
                pos, ok = doParse(ast, rulesTable, input, newchain, pos)
            }
            return pos, true
        */
        case "optWs":
            if input[pos:pos+1] == " " {
                pos = pos + 1
                pos, ok = doParse(ast, rulesTable, input, newchain, pos)
            }
            return pos, true
        case "identifier":
            name := findChildNamed(ast, "ruleName").Token
            fmt.Println("Activating rule '", name, "' in ruleName ", ast)
            pos, ok = doParse(rulesTable[name], rulesTable, input, newchain, pos)
            if ok {
                log.Println("Returning success in ruleName")
                return pos, ok
            }
        log.Println("Returning failure in ruleName")
        return start, false
        
    }


    fmt.Println(newchain, "(", ast.Token, ") vs '", input[pos:pos+len(ast.Token)], "' at ", pos)

    if ast.Name != "ruleName" && ast.Token != "" && len(ast.Token)>0 {
        if ast.Token != "|" {
            fmt.Println("Checking for literal '", ast.Token, "'")
            if input[pos:pos+len(ast.Token)] == ast.Token {
                log.Printf("Found literal: %v(%v) at %v", ast.Name, ast.Token, pos)
                pos = pos + len(ast.Token)
                return pos, true
            }
        } else {
            return start, true
        }
    }

    if len(ast.Nodes) ==0 {
        return start, false
    }


    for _, v := range ast.Nodes {
        pos, ok = doParse(v, rulesTable, input, newchain, pos)
        if !ok {
            log.Println("Returning failure from default loop (", ast.Name, ")")
            return start, ok
        }
    }

    log.Println("Returning success at end of func")
    return pos, true
}


func findChildNamed(ast *peg.Ast, s string) *peg.Ast {
    for _, v := range ast.Nodes {
        if v.Name == s  {
            return v
        }
    }
    return nil
}

func buildRules(ast *peg.Ast, rules map[string]*peg.Ast) map[string]*peg.Ast {
    switch ast.Name {
        case "rule":
            fmt.Println(ast)
            fmt.Println("+++",findChildNamed(ast, "ruleDecl").Nodes[1].Token, findChildNamed(ast, "expression"))
            rhs := findChildNamed(ast, "expression") 
            if rhs == nil {
                rhs =  findChildNamed(ast, "list")
            }
            if rhs == nil {
                rhs =  findChildNamed(ast, "identifier")
            }
            if rhs == nil {
                rhs =  findChildNamed(ast, "literal2")
            }
            if rhs == nil {
                rhs =  findChildNamed(ast, "literal1")
            }
            if rhs == nil {
                log.Fatal("Could not find expression for ", findChildNamed(ast, "ruleDecl").Nodes[1].Token)
            }
            rules[findChildNamed(ast, "ruleDecl").Nodes[1].Token] = rhs
    }

    for _, v := range ast.Nodes {
        buildRules(v, rules)
    }
    return rules
}



func walkAST(ast *peg.Ast) {
    prune := map[string]bool{}
    skip := map[string]bool{}
    prune["optWs"] = true
    prune["WHITESPACE"] = true
    prune["ruleEnd"] = true
    skip["list"] = true
    skip["mexpression"] = true
    switch ast.Name {
        case "CONFIG":
        case "DBNAME":
        case "KEY":
           // dey = ast.Token
        case "VALUE":
    }   
        _,sok := skip[ast.Name]
        _, ok := prune[ast.Name]
        if !ok && !sok  {
            if len(ast.Nodes)>1 {
            fmt.Printf("\n%v[ %v(%v) ", strings.Repeat(" ", indent),  ast.Name, ast.Token)
            indent=indent+indentStep
            } else {
                fmt.Printf("\n%v%v(%v) ", strings.Repeat(" ", indent),  ast.Name, ast.Token)
            }
    }
    for _, v := range ast.Nodes {
        if _, ok := prune[ast.Name]; !ok  {
            walkAST(v)
        }
    }
        if !ok && !sok  {
            if len(ast.Nodes)>1 {
            indent = indent - indentStep
            fmt.Println(strings.Repeat(" ", indent), "]")
}
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



var bnf = `
  syntax        ←  rule*
  rule            ← optWs  ruleDecl optWs assign optWs expression optWs ruleEnd
  starExpression ← "{" optWs expression "}" "*"? "+"?
  optExpression ← "[" optWs expression optWs "]"
  grpExpression ← "(" optWs expression optWs ")"
  mexpression    ← list / optWs optionalMarker optWs list
  optionalMarker ← "|"
  expression    ← mexpression*
  list            ← term list?
  term            ← literal1 / literal2 / identifier / starExpression / optExpression / grpExpression / ellipsis / NUMBER / WHITESPACE+ / literal3
  literal1         ← "'''" / "'" < literalString1* > "'"
  literal2         ← '"' < literalString2* > '"'
  literal3         ← literalString3
  identifier      ←  startident  ruleName  endident
  ruleDecl      ←  startident  identDecl  endident
  startident     ←  "<"
  endident     ←  ">"
  ruleEnd        ← optWs newLine
  optWs          ← WHITESPACE*
  assign          ← "::="
  ellipsis        ← "..."
  ruleName        ← [-a-zA-Z0-9 ]+
  identDecl        ← [-a-zA-Z0-9 ]+
  STRING          ←  [-a-zA-Z0-9#;_,./*\\! ]
  literalString1   ←  symbol/ [-a-zA-Z0-9;_,./*\\! <>{}"+]
  literalString2   ←  symbol/ [-a-zA-Z0-9;_,./*\\! <>{}'+]
  literalString3   ←  [a-zA-Z0-9]
  NUMBER          ←  < [x0-9]+ >
  hex             ← NUMBER / 'A' / 'B' / 'C' / 'D' / 'E' / 'F' / 'a' / 'b' / 'c' / 'd' / 'e' / 'f' / 'x'
  symbol ← '!' /  '#' / '$' / '%' / '&' / '(' / ')' / '*' / '+' / ',' / '-' / '.' / '/' / '<' / '=' / '>' / '?' / '@' / '[' / [\\]  / ']' / '^' / '_' / '|' / '}' / '{' / '~' / '/' / ';' / ':' / '` +
"`" +
`'
  WHITESPACE     ← [ \t]
  newLine         ← [\n+]
`
var bnf_multiline = `
  syntax        ←  rule*
  rule            ← ruleEnd  identifier optWs assign optWs expression_root
  starExpression  ← "{" optWs expression_root "}" "*"? "+"?
  optExpression   ← "[" optWs expression_root optWs "]"
  grpExpression   ← "(" optWs expression_root optWs ")"
  expression      ← list / optWs "|"  optWs  list
  expression_root  ← expression*
  list            ← term list?
  term            ← literal1 / literal2 / identifier / starExpression / optExpression / grpExpression / ellipsis / hex / NUMBER / WHITESPACE+ / literal3
  literal1         ← "'''" / "'" literalString1* "'"
  literal2         ← '"'  literalString2* '"'
  literal3         ← literalString3
  identifier      ← "<" ruleName ">"
  ruleEnd        ← newLine newLine
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
  WHITESPACE     ← [ \t\n]
  newLine         ← [\n]
`



func buildParser() *peg.Parser {
    parser, err := peg.NewParser(bnf)

    if err != nil {
       log.Fatal("Error in internal parser rules: ", err)
    }
    return parser
}


func main() {
    fileName := os.Args[1]
    dataName := os.Args[2]
    startRule := os.Args[3]

    file, err := ioutil.ReadFile(fileName)
    //log.Println("Parsing ", string(file))
    if err != nil {
        log.Fatal(err)
    }
    ast := parseString(buildParser(), string(file))
    ast = ast
    fmt.Println(ast)

    //walkAST(ast)
    fmt.Println("Building rules")
    rules := buildRules(ast, map[string]*peg.Ast{})
    fmt.Println(rules)
    log.Println("Rules built")

    fmt.Println("parsing")
    file2, err := ioutil.ReadFile(dataName)
    _, ok := startParse(ast, rules,  string(file2), startRule, "", 0)
    if ok {
        fmt.Printf("Parse completed successfully")
    }
}
