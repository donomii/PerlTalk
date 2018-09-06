package main

import (
	"fmt"
	"github.com/yhirose/go-peg"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

var debug = false
var indent = 0
var indentStep = 4

func startParse(ast *peg.Ast, rulesTable map[string]*peg.Ast, input, startRule, chain string, start int) (int, bool, *peg.Ast) {
	ruleAst := lookupRule(startRule, rulesTable)
	fmt.Println("Starting with rule ", ruleAst)
	pos, ok, newAst := doParse(ruleAst, rulesTable, input, chain, start)
	return pos, ok, newAst
}
func lookupRule(name string, rulesTable map[string]*peg.Ast) *peg.Ast {
	ast, ok := rulesTable[name]
	if ok {
		return ast
	}
	log.Fatal("Rule does not exist: ", name)
	return nil
}

var parseCache map[string]bool

func registerFail(ast *peg.Ast, rulesTable map[string]*peg.Ast, input, chain string, start int) {
	key := fmt.Sprintf("%v%v%v%v%v", ast, rulesTable, input, chain, start)
	parseCache[key] = true
}

func willFail(ast *peg.Ast, rulesTable map[string]*peg.Ast, input, chain string, start int) bool {
	key := fmt.Sprintf("%v%v%v%v%v", ast, rulesTable, input, chain, start)
	_, ok := parseCache[key]
	return ok
}

func doParse(ast *peg.Ast, rulesTable map[string]*peg.Ast, input, chain string, start int) (int, bool, *peg.Ast) {
	if willFail(ast, rulesTable, input, chain, start) {
		return start, false, nil
	}
	pos := start
	ok := false
	newchain := fmt.Sprintf("%v->%v(%v)", chain, ast.Name, ast.Token)
	newAst := peg.Ast{Name: ast.Name, Token: ast.Token, Nodes: []*peg.Ast{}, Parent: &peg.Ast{}}
	fmt.Println("Parsed so far: ", input[0:start])
	//if len(newchain) > 2000 {
	//log.Fatal("Deep recursion")
	//}
	switch ast.Name {
	case "expression":
		for i, v := range ast.Nodes {
			if v.Name != "WHITESPACE" {
				var childAst *peg.Ast
				pos, ok, childAst = doParse(v, rulesTable, input, newchain, pos)
				//log.Println("Current AST: ", childAst)
				if !ok {
					//Are we at the last node?
					if !(i < len(ast.Nodes)-1) {
						if debug {
							log.Println("Failed to match last element in expression ", ast, " aborting")
						}
						registerFail(ast, rulesTable, input, chain, start)
						return start, false, nil
					}
					//But wait!  If the next item in the expression has the optional flag, we can try that instead of failing
					//Is the next node optional?
					if findChildNamed(ast.Nodes[i+1], "optionalMarker") == nil {
						if debug {
							log.Println("Next element is optional, continuing loop in expression")
						}
						registerFail(ast, rulesTable, input, chain, start)
						return start, false, nil
					}
					//Continue loop at next node
				} else {
					if childAst != nil {
						newAst.Nodes = append(newAst.Nodes, childAst)
					}
					if debug {
						log.Println("Returning success from expression", newchain)
					}
					return pos, ok, &newAst

					//But wait!  If the next item in the expression has the optional flag, we can try that instead of failing
					//Is the next node optional?
					if findChildNamed(ast.Nodes[i+1], "optionalMarker") == nil {
						if debug {
							log.Println("Next element is optional, exiting expression with success")
						}
						return start, true, nil
					}

				}
			}
		}
		if debug {
			log.Println("Returning true after completing whole expression")
		}
		return start, true, nil
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
	/*    log.Println("Returning success from whitespace")
	      return pos, true, &newAst
	      if input[pos:pos+1] == " " {
	          pos = pos + 1
	          pos, ok, _ = doParse(ast, rulesTable, input, newchain, pos)
	      }
	      return pos, true
	*/
	case "optWs":
		if input[pos:pos+1] == " " {
			pos = pos + 1
			var childAst *peg.Ast
			pos, ok, childAst = doParse(ast, rulesTable, input, newchain, pos)
			//log.Println("Current AST: ", childAst)
			if childAst != nil {
				newAst.Nodes = append(newAst.Nodes, childAst)
			}
		}
		if debug {
			log.Println("Returning success from optional whitespace")
		}
		return pos, true, &newAst
	case "identifier":
		name := findChildNamed(ast, "ruleName").Token
		ruleAst := lookupRule(name, rulesTable)
		//fmt.Println("Activating rule '", name, "' in ruleName ", ruleAst)
		var childAst *peg.Ast
		pos, ok, childAst = doParse(ruleAst, rulesTable, input, newchain, pos)
		//log.Println("Current AST: ", childAst)
		if ok {
			if debug {
				log.Println("Returning success in ruleName (", ast.Name, ")")
			}
			if childAst != nil {
				newAst.Nodes = append(newAst.Nodes, childAst)
			}
			return pos, ok, &newAst
		}
		if debug {
			log.Println("Returning failure in ruleName (", ast.Name, ")")
		}
		registerFail(ast, rulesTable, input, chain, start)
		return start, false, nil
	}

	if debug {
		log.Printf("%v (%v)(%v) vs '%v' at %v\n", ast.Name, ast.Token, []byte(ast.Token), input[pos:pos+len(ast.Token)], pos)
	}

	if ast.Name != "ruleName" && ast.Name != "optionalMarker" && ast.Token != "" && len(ast.Token) > 0 {
		//fmt.Println("Checking for literal '", ast.Token, "'")
		//if ast.Token != "|" {
		if pos+len(ast.Token) < len(input) {
			if input[pos:pos+len(ast.Token)] == ast.Token {
				if debug {
					log.Printf("Found literal: %v(%v) at %v", ast.Name, ast.Token, pos)
				}
				pos = pos + len(ast.Token)
				if debug {
					log.Println("Returning success from literal (", ast.Token, ")")
				}
				return pos, true, &newAst
			}
		}
	}

	if len(ast.Nodes) == 0 && ast.Token == "" {
		if debug {
			log.Println("Returning true from empty literal")
		}
		return start, true, nil
	}

	if len(ast.Nodes) == 0 {
		if debug {
			log.Println("Returning false from terminal node")
		}
		registerFail(ast, rulesTable, input, chain, start)
		return start, false, nil
	}

	for _, v := range ast.Nodes {
		if v.Name != "WHITESPACE" && v.Name != "optionalMarker" {
			var childAst *peg.Ast
			pos, ok, childAst = doParse(v, rulesTable, input, newchain, pos)
			//log.Println("Current AST: ", childAst)
			if childAst != nil {
				newAst.Nodes = append(newAst.Nodes, childAst)
			}
			if !ok {
				if debug {
					log.Println("Returning failure from default loop (", ast.Name, ")")
				}
				return start, ok, nil
			}
		}
	}

	if debug {
		log.Println("Returning success at end of func(", ast.Name, ")")
	}
	return pos, true, &newAst
}

func findChildNamed(ast *peg.Ast, s string) *peg.Ast {
	for _, v := range ast.Nodes {
		if v.Name == s {
			return v
		}
	}
	return nil
}

func buildRules(ast *peg.Ast, rules map[string]*peg.Ast) map[string]*peg.Ast {
	switch ast.Name {
	case "rule":
		//fmt.Println(ast)
		//fmt.Println("+++",findChildNamed(ast, "ruleDecl").Nodes[1].Token, findChildNamed(ast, "expression"))
		rhs := findChildNamed(ast, "expression")
		if rhs == nil {
			rhs = findChildNamed(ast, "list")
		}
		if rhs == nil {
			rhs = findChildNamed(ast, "identifier")
		}
		if rhs == nil {
			rhs = findChildNamed(ast, "literal2")
		}
		if rhs == nil {
			rhs = findChildNamed(ast, "literal1")
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
	brief := true
	if ast == nil {
		return
	}
	prune := map[string]bool{}
	skip := map[string]bool{}
	prune["optWs"] = true
	prune["WHITESPACE"] = true
	prune["ruleEnd"] = true
	prune["optionalMarker"] = true
	skip["list"] = true
	skip["mexpression"] = true
	switch ast.Name {
	case "CONFIG":
	case "DBNAME":
	case "KEY":
		// dey = ast.Token
	case "VALUE":
	}
	_, sok := skip[ast.Name]
	_, ok := prune[ast.Name]
	if brief && ast.Token != "" {
		if !ok && !sok {
			if len(ast.Nodes) > 0 {
				fmt.Printf("\n%v[ %v(%v) ", strings.Repeat(" ", indent), ast.Name, ast.Token)
				indent = indent + indentStep
			} else {
				fmt.Printf("\n%v%v(%v) ", strings.Repeat(" ", indent), ast.Name, ast.Token)
			}
		}
	}
	for _, v := range ast.Nodes {
		if _, ok := prune[ast.Name]; !ok {
			walkAST(v)
		}
	}
	if brief && ast.Token != "" {
		if !ok && !sok {
			if len(ast.Nodes) > 0 {
				indent = indent - indentStep
				fmt.Println(strings.Repeat(" ", indent), "]")
			}
		}
	}
}

func parseString(parser *peg.Parser, str string) *peg.Ast {
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
	parseCache = map[string]bool{}
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
	//fmt.Println(ast)

	//walkAST(ast)
	fmt.Println("Building rules")
	rules := buildRules(ast, map[string]*peg.Ast{})
	//Let's add some useful symbols
	rules["EOL"] = &peg.Ast{Name: "literal2", Token: "\n", Nodes: []*peg.Ast{}}
	rules["EOL"].Parent = rules["EOL"]
	//fmt.Println(rules)
	log.Println("Rules built")

	fmt.Println("parsing")
	file2, err := ioutil.ReadFile(dataName)
	_, ok, tree := startParse(ast, rules, string(file2), startRule, "", 0)
	if ok {
		fmt.Println("Parse completed successfully")
		if tree != nil {
			fmt.Println(tree.Name, tree.Token)
			walkAST(tree)
			//fmt.Println(tree)
		}
	}
}
