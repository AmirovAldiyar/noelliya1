{
    let utils = require("./utils")
    var vars = new Map()
}

start
  = program

program 
    = statementsList

statementsList
    = (statement ";") +

statement
    = assignment / print

assignment
    = "var" s ident:ident s type:type s ":=" s value:value { vars.set(ident, value); }

ident
    = first:[a-z] others:[a-z0-9]* { return utils.makeIdent(first, others); }

print 
    = "print" s ident:ident { console.log(vars.get(ident)); }

type
    = "int" / "string" / "float"

value
    = intliteral / floatliteral / stringliteral

intliteral
    = digits:[0-9]+ { return utils.makeInt(digits); }
    / "-" [0-9]+ { return utils.makeInt(digits) * -1; }

floatliteral
    = intpart:[0-9]+ "." floatpart:[0-9]+ {  return utils.makeFloat(intpart, floatpart); }
    / "-" intpart:[0-9]+ "." floatpart:[0-9]+ {  return utils.makeFloat(intpart, floatpart) * -1.0; }

stringliteral
    = '"' str:[0-9a-zA-Z]+ '"' { return utils.makeString(str); }

s
    = " "