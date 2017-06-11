package main

//import "github.com/davecgh/go-spew/spew"
import (
    "strings"
    "github.com/antlr/antlr4/runtime/Go/antlr"
    "./c"
    "os"
    "fmt"
    "reflect"
)

var indentLevel int = 0

func indent() string {
    return strings.Repeat(" ", indentLevel)
}

type TreeShapeListener struct {
    *parser.BaseCListener
}

func NewTreeShapeListener() *TreeShapeListener {
    return new(TreeShapeListener)
}

func (this *TreeShapeListener) EnterTerminal(ctx antlr.ParserRuleContext) {
       fmt.Println( "content: ", ctx.GetPayload())
}
func (this *TreeShapeListener) EnterEveryRule(ctx antlr.ParserRuleContext) {
    //r := ctx.GetRuleContext()
    //fmt.Println("Rules: ", ctx.GetRuleNames()[ctx.GetRuleIndex()])
    //fmt.Println("Rule: ", ctx.BaseParserRuleContext.BaseRuleContext.RuleIndex)
    //fmt.Println("Rule: ", ctx.(antlr.ParserRuleContext))
    //spew.Dump(ctx)
    //c := ctx.GetChildCount()
    nodeType := ""
    if len(ctx.GetChildren()) > 0 {
        nodeType = fmt.Sprintf("%v", reflect.TypeOf(ctx.GetChildren()[0]))
    }
    if nodeType != "*antlr.TerminalNodeImpl" {
        fmt.Printf("\n%v(%v", indent(), reflect.TypeOf(ctx))
        //fmt.Printf("\n%v(", indent())
        indentLevel = indentLevel +1
    } else {
       fmt.Printf(" %v", ctx.GetText())
    }
    //fmt.Println(indent(), "Type: ", reflect.TypeOf(ctx))
    //fmt.Println(indent(), "Children: ", ctx.GetChildren(), reflect.TypeOf(ctx.GetChildren()[0]))
    //fmt.Println(indent(), "+ ", ctx.GetPayload())
    //fmt.Printf("%v- %V\n",indent(), r)
}

func (this *TreeShapeListener) ExitEveryRule(ctx antlr.ParserRuleContext) {
    nodeType := ""
    if len(ctx.GetChildren()) > 0 {
        nodeType = fmt.Sprintf("%v", reflect.TypeOf(ctx.GetChildren()[0]))
    }
    if nodeType != "*antlr.TerminalNodeImpl" {
        indentLevel = indentLevel -1
        fmt.Println(indent(), ")")
    }
}

func main() {
    input, _ := antlr.NewFileStream(os.Args[1])
    lexer := parser.NewCLexer(input)
    stream := antlr.NewCommonTokenStream(lexer,0)
    p := parser.NewCParser(stream)
    p.AddErrorListener(antlr.NewDiagnosticErrorListener(true))
    p.BuildParseTrees = true
    tree := p.CompilationUnit()
    //spew.Dump(tree)
    antlr.ParseTreeWalkerDefault.Walk(NewTreeShapeListener(), tree)
}
