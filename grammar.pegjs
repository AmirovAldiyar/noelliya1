{

    const ps = require('prompt-sync')
    const prompt = ps()
    const consts = require("./const")
    let utils = require("./utils")
    var vars = new Map()
    var compVars = new Map()
    let funcs = []
    let scopeHistory = []
    let tmpScope = ""
    let blockStack = []
    let returned = [false, undefined]
    let lastType = undefined
    
    function declarationValue(ctx, ident, type, value) {
        if(type != value.type) {
            console.error("something went wrong");
        }
        
    }

    function getCompVar(history, scope, ident) {
        let key = scope+"$"+ident;
        let val = compVars.get(key)
        if(val != undefined) {
            return val
        }
        for(let i = 0; i < history.length; i ++) {
            let key = history[i]+"$"+ident;
            let val = compVars.get(key)
            if(val != undefined) {
                return val
            }
        }
        return undefined
    }

    function setCompVar(scope, ident, value) {
        compVars.set(scope+'$'+ident, value)
    }

    function getVar(history, scope, ident) {
        let key = scope+"$"+ident;
        let val = vars.get(key)
        if(val != undefined) {
            return val
        }
        for(let i = 0; i < history.length; i ++) {
            let key = history[i]+"$"+ident;
            let val = vars.get(key)
            if(val != undefined) {
                return val
            }
        }
        return undefined
    }

    function setVar(scope, ident, value) {
        vars.set(scope+'$'+ident, value)
    }

    function declareIdentCheck(location, ident1, ident2, type) {
        return (history, scope) => {
            if(compVars.get(scope+'$'+ident1) != undefined) {
                return `${location.start.line}:${location.start.column} variable ${ident1} is already defined`;
            }
            let val = getCompVar(history, scope, ident2);
            if(val == undefined) {
                return `${location.start.line}:${location.start.column} variable ${ident2} not defined`;
            } 
            if (val.type != type) {
                return `${location.start.line}:${location.start.column} type ${val.type} is not assignable to type ${type}`
            }
            setCompVar(scope, ident1, val);
            return undefined; 
        }
    }

    function declareIdent(location, ident1, ident2) {
        return (history, scope) => {
            let val = getVar(ident2);
            if(val == undefined) {
                return `${location.start.line}:${location.start.column} variable not defined ${ident2}`;
            }
            setVar(scope, ident1, val);
            return undefined; 
        }
    }

    
    function declareCheck(location, ident1, expr, type) {
        return (history, scope) => {
            if(compVars.get(scope+'$'+ident1) != undefined) {
                return `${location.start.line}:${location.start.column} variable ${ident1} is already defined`;
            }
            let check = expr[0](history, scope)
            if (check[1] != undefined) {
                return check[1]
            }
            if (check[0] != type) {
                return `${location.start.line}:${location.start.column} type ${check[0]} is not assignable to type ${type}`
            }
            let value = {type: check[0]}
            setCompVar(scope, ident1, value);
            return undefined; 
        }
    }

    function declare(location, ident1, expr) {
        return (history, scope) => {
            let value = expr[1](history, scope)
            setVar(scope, ident1, value);
            return undefined;
        }
    }

    function printCheck(location, exp) {
        return (history, scope) => {
            let check = exp[0](history, scope)
            if(check[1] != undefined) {
                return check[1]
            }
            return undefined
        }
    }

    function print(location, exp) {
        return (history, scope) => {
            let val = exp[1](history, scope)
            if(val == undefined) {
                return `${location.start.line}:${location.start.column} value to print is undefined`
            }
            console.log(val.value)
            return undefined
        }
    }

    function wrapper(history, scope, func) {
        return () => {
            func(history, scope)
        }
    }

    function assignmentIdentCheck(location, ident1, ident2) {
        return (history, scope) => {
            let var1 = getCompVar(history, scope, ident1)
            if(var1 == undefined) {
                return `${location.start.line}:${location.start.column} varaible ${ident1} is not defined`
            }
            let var2 = getCompVar(history, scope, ident2)
            if(var2 == undefined) {
                return `${location.start.line}:${location.start.column} varaible ${ident2} is not defined`
            }
            if(var1.type != var2.type) {
                return `${location.start.line}:${location.start.column} type ${var2.type} is assignable to type ${var1.type}`
            }
            return undefined
        }
    }

    function assignmentIdent(location, ident1, ident2) {
        return (history, scope) => {
            setVar(scope, ident1, getVar(history, scope, ident2))
            return undefined
        }
    }
    
    function assignmentValueCheck(location, ident1, value) {
        return (history, scope) => {
            let var1 = getCompVar(history, scope, ident1)
            if(var1 == undefined) {
                return `${location.start.line}:${location.start.column} varaible ${ident1} is not defined`
            }
            if(var1.type != value.type) {
                return `${location.start.line}:${location.start.column} type ${value.type} is assignable to type ${var1.type}`
            }
            return undefined
        }
    }

    function assignmentValue(location, ident1, value) {
        return (history, scope) => {
            setVar(scope, ident1, value)
            return undefined
        }
    }

    function unaryCheck(location, op, value) {
        switch (op) {
            case "+":
                if (value.type == consts.TYPE_INT || value.type == consts.TYPE_FLOAT) {
                    return [value.type, undefined]
                }
                return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply unary operator "${op}" to type ${value.type}`]
                break;
            case "-":
                if (value.type == consts.TYPE_INT || value.type == consts.TYPE_FLOAT) {
                    return [value.type, undefined]
                }
                return  [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply unary operator "${op}" to type ${value.type}`]
                break;
            case "!":
                if (value.type == consts.TYPE_BOOL) {
                    return [consts.TYPE_BOOL, undefined]
                }
                return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply unary operator "${op}" to type ${value.type}`]
                break;
            default:
                break;
        }
    }

    function unary(location, op, value) {
        switch (op) {
            case "+":
                return value
                break;
            case "-":
                console.log(value.value)
                value.value = -value.value
                return value
                break;
            case "!":
                value.value = !value.value
                return value
                break;
            default:
                break;
        }
    }

    function binaryCheck(location, op, value1, value2) {
        switch (op) {
            case "&&":
            case "||":
                if (value1.type == consts.TYPE_BOOL && value2.type == consts.TYPE_BOOL) {
                    return [consts.TYPE_BOOL, undefined]
                }
                return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply operator "${op}" to type ${value1.type} or type ${value2.type}`]
                break;
            case "!=":
            case "==":
                if (value1.type == consts.TYPE_BOOL && value2.type == consts.TYPE_BOOL) {
                    return [consts.TYPE_BOOL, undefined]
                }
                if ((value1.type == consts.TYPE_INT || value1.type === consts.TYPE_FLOAT) && (value2.type == consts.TYPE_INT || value2.type == consts.TYPE_FLOAT)) {
                    return [consts.TYPE_BOOL, undefined]
                }
                if (value1.type == consts.TYPE_STRING && value2.type == consts.TYPE_STRING) {
                    return [consts.TYPE_BOOL, undefined]
                }
                return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply operator "${op}" to type ${value1.type} and type ${value2.type}`]
                break;
            case "<":
            case "<=":
            case ">":
            case ">=":
                if ((value1.type == consts.TYPE_INT || value1.type === consts.TYPE_FLOAT) && (value2.type == consts.TYPE_INT || value2.type == consts.TYPE_FLOAT)) {
                    let returnType = (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) ? consts.TYPE_FLOAT : consts.TYPE_INT
                    return [returnType, undefined]
                }
                return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply operator "${op}" to type ${value1.type} and type ${value2.type}`]
                break;
            default:
                break;
        }
    }

    function binary(location, op, value1, value2) {
        let res
        switch (op) {
            case "&&":
                res = { value: value1.value && value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case "||":
                res = { value: value1.value || value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case "!=":
                res = { value: value1.value != value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case "==":
                res = { value: value1.value == value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case "<":
                res = { value: value1.value < value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case "<=":
                res = { value: value1.value <= value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case ">":
                res = { value: value1.value > value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            case ">=":
                res = { value: value1.value >= value2.value, type: consts.TYPE_BOOL }
                return res
                break;
            default:
                break;
        }
    }

    function multiCheck(location, op, value1, value2) {
        if ((value1.type == consts.TYPE_INT || value1.type === consts.TYPE_FLOAT) && (value2.type == consts.TYPE_INT || value2.type == consts.TYPE_FLOAT)) {
            let returnType = (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) ? consts.TYPE_FLOAT : consts.TYPE_INT
            return [returnType, undefined]
        }
        return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply operator "${op}" to type ${value1.type} or type ${value2.type}`]     
    }

    function multi(location, op, value1, value2) {
        switch (op) {
            case "*":
                let res = { value: value1.value * value2.value, type: consts.TYPE_INT}
                if (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) {
                    res.type = consts.TYPE_FLOAT
                }
                return res
                break;
            case "/":
                res = { value: value1.value / value2.value, type: consts.TYPE_INT}
                if (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) {
                    res.type = consts.TYPE_FLOAT
                }
                return res
                break;
        
            default:
                break;
        }
    }

    function addCheck(location, op, value1, value2) {
        if ((value1.type == consts.TYPE_INT || value1.type === consts.TYPE_FLOAT) && (value2.type == consts.TYPE_INT || value2.type == consts.TYPE_FLOAT)) {
            let returnType = (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) ? consts.TYPE_FLOAT : consts.TYPE_INT
            return [returnType, undefined]
        }
        return [consts.TYPE_UNDEFINED, `${location.start.line}:${location.start.column} cannot apply operator "${op}" to type ${value1.type} or type ${value2.type}`]     
    }

    function add(location, op, value1, value2) {
        let res
        switch (op) {
            case "+":
                res = { value: value1.value + value2.value, type: consts.TYPE_INT}
                if (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) {
                    res.type = consts.TYPE_FLOAT
                }
                return res
                break;
            case "-":
                res = { value: value1.value - value2.value, type: consts.TYPE_INT}
                if (value1.type == consts.TYPE_FLOAT || value2.type == consts.TYPE_FLOAT) {
                    res.type = consts.TYPE_FLOAT
                }
                return res
                break;
        
            default:
                break;
        }
    }

    function expCheckTwoWrap(func, history, scope, location, op, value1, value2) {
        let res1 = value1[0](history, scope)
        let type1 = res1[0]
        let err1 = res1[1]
        if(err1 != undefined) {
            return [consts.TYPE_UNDEFINED, err1]
        }
        let res2 = value2[0](history, scope)
        let type2 = res2[0]
        let err2 = res2[1]
        if(err2 != undefined) {
            return [consts.TYPE_UNDEFINED, err2]
        }
        return func(location, op, {type: type1}, {type: type2})
    }
    function expCheckOneWrap(func, history, scope, location, op, value1) {
        let res1 = value1[0](history, scope)
        let type1 = res1[0]
        let err1 = res1[1]
        if(err1 != undefined) {
            return [consts.TYPE_UNDEFINED, err1]
        }
        return func(location, op, {type: type1})
    }
    function expTwoWrap(func, history, scope, location, op, value1, value2) {
        let var1 = value1[1](history, scope)
        let var2 = value2[1](history, scope)
        return func(location, op, var1, var2)
    }
    function expOneWrap(func, history, scope, location, op, value) {
        let var1 = value[1](history, scope)
        return func(location, op, var1)
    }
    function operandCheckIdent(history, scope, location, ident) {
        let variable = getCompVar(history, scope, ident)
        if (variable == undefined) {
            return [undefined, `${location.start.line}:${location.start.column} variable ${ident} is not declared in the scope`]
        }
        let type = variable.type
        if (type == undefined) {
            return [undefined, `${location.start.line}:${location.start.column} variable ${ident} is not declared in the scope`]
        }
        return [type, undefined, variable]
    }
    function ifcheck(location, expr, block) {
        return (history, scope) => {
            let val = expr[0](history, scope)
            if (val[1] != undefined) {
                return val[1]
            }
            if (val[0] != consts.TYPE_BOOL) {
                return `${location.start.line}:${location.start.column} expression should evaluate to boolean`
            }
            blockStack.push("block")
            let blockCheck = block[0](history, scope)
            blockStack.pop()
            if(blockCheck != undefined) {
                return blockCheck
            }
            return undefined
        }
    }
    function ifElsecheck(location, expr, block, block2) {
        return (history, scope) => {
            let val = expr[0](history, scope)
            if (val[1] != undefined) {
                return val[1]
            }
            if (val[0] != consts.TYPE_BOOL) {
                return `${location.start.line}:${location.start.column} expression should evaluate to boolean`
            }
            let err = ""
            blockStack.push("block")
            let blockCheck = block[0](history, scope)
            blockStack.pop()
            if(blockCheck != undefined) {
                err = err + blockCheck
            }
            blockStack.push("block")
            let blockCheck2 = block2[0](history, scope)
            blockStack.pop()
            if(blockCheck2 != undefined) {
                err = err + "\n" + blockCheck2
            }
            if (err != "") {
                return err
            }
            return undefined
        }
    }
    function ifState(location, expr, block) {
        return (history,scope) => {
            let val = expr[1](history, scope)
            if (val.value == true) {
                blockStack.push("block")
                let res = block[1](history, scope)
                blockStack.pop()
                return res
            }
            return undefined
        }
    }
    function ifElseState(location, expr, block, block2) {
        return (history,scope) => {
            let val = expr[1](history, scope)
            if (val.value == true) {
                blockStack.push("block")
                let res = block[1](history, scope)
                blockStack.pop()
                return res
            }
            blockStack.push("block")
            let res = block2[1](history, scope)
            blockStack.pop()
            return res
        }
    }
}

start
  = _ program _

program 
    = r:statementsList { 
        setCompVar("0", "input", {type: consts.TYPE_STRING, params: []})
        setVar("0", "input", {type: consts.TYPE_STRING, params: [], value: (history, scope) => {
            return {type: consts.TYPE_STRING, value: prompt("")}
        }})
        let hasError = false
        let report = []
        for(let i = 0; i < r[0].length; i ++) {
            report.push(r[0][i]([], "0"))
        }
        for(let i = 0; i < report.length; i ++) {
            if(report[i] != undefined) {
                console.log(report[i])
                hasError = true
            }
        }
        if (!hasError) {
            let runtimes = []
            for(let i = 0; i < r[1].length; i ++) {
                let err = r[1][i]([], "0")
                if (err != undefined) {
                    console.log("runtime error:", err)
                    break;
                }
            }
        }
     }

ifstatement
    = "if" _ "(" _ expr:expression _")" _ block:block _ {return [ifcheck(location(), expr, block), ifState(location(), expr, block)]}
    / "if" _ "("_ expr:expression _ ")" _ block1:block _ "else" _ block2:block { return [ifElsecheck(location(), expr, block1, block2), ifElseState(location(), expr, block1, block2)]}
    
funccall
    = ident:ident _ "(" _ ")" _ ";" _ {
        let locat = location(); 
        return [(history, scope) => {
            let func = getCompVar(history, scope, ident)
            if (func == undefined) {
                return `${locat.start.line}:${locat.start.column} function ${ident} was not declared in the scope`
            }
            if (func.params == undefined) {
                return `${locat.start.line}:${locat.start.column} ${ident} is not a function`
            }
            return undefined;
        }, (history, scope) => {
            let func = getVar(history, scope, ident)
            blockStack.push("func")
            let res = func.value(history, scope, [])
            blockStack.pop()
            return res
        }]
    }
    / ident:ident _ "(" _ args:arglist _ ")" _ ";" { let locat = location(); 
        return [(history, scope) => {
            let func = getCompVar(history, scope, ident)
            if (func == undefined) {
                return `${locat.start.line}:${locat.start.column} function ${ident} was not declared in the scope`
            }
            if (func.params == undefined) {
                return `${locat.start.line}:${locat.start.column} ${ident} is not a function`
            }
            if (args.length != func.params.length) {
                return `${locat.start.line}:${locat.start.column} argument number expected ${func.params.length} got ${args.length}`
            }
            for (let i = 0; i < func.params.length; i++) {
                let err = args[i][0](history, scope)
                if (err[1] != undefined) {
                    return err[1]
                }
                if (err[0] != func.params[i][1]) {
                    return `${locat.start.line}:${locat.start.column} argument ${i} should be type ${func.params[i][1]}, got ${err[0]}`
                }
            }
            return undefined;
        }, (history, scope) => {
            let func = getVar(history, scope, ident)
            let argList = []
            for (let i = 0; i < args.length; i ++) {
                argList.push([func.params[i][0], func.params[i][1], args[i][1](history, scope).value])
            }
            blockStack.push("func")
            let res = func.value(history, scope, argList)
            blockStack.pop()
            return res
        }]
    }

statementsList
    = stmt:statement  _ stmtlst:statementsList _ { return [[stmt[0], ...stmtlst[0]], [stmt[1], ...stmtlst[1]]]; }
    / stmt:statement  _ { return [[stmt[0]], [stmt[1]]]; }
   

statement
    = decl:declaration _ ";" { return decl; }
    / prnt:print _ ";" { return prnt; }   
    / assign:assignment _ ";" { return assign; }
    / ifstate:ifstatement {return ifstate; }
    / fd:funcdeclare { return fd; }
    / fc:funccall {return fc;}
    / r:returnstatement {return r;}

declaration
    = "var" __ ident:ident __ type:type _ ":=" _ expr:expression { return [declareCheck(location(), ident, expr, type), declare(location(), ident, expr)]; }

assignment
    = ident:ident _ "=" _ value:value { return [assignmentValueCheck(location(), ident, value), assignmentValue(location(), ident, value)] }
    / ident1:ident _ "=" _ ident2:ident { return [assignmentIdentCheck(location(), ident1, ident2), assignmentIdent(location(), ident1, ident2)]}

block
    = "{" _ r:statementsList _ "}" {
        return [(history, scope, args=[]) => {
            let newHistory = [...history, scope]
            let newScope = utils.generateId()
            for(let i = 0; i < args.length; i ++) {
                setCompVar(newScope, args[i][0], {type: args[i][1]})
            }
            let report = []
            for(let i = 0; i < r[0].length; i ++) {
                let err = r[0][i](newHistory, newScope)
                if (err != undefined){
                    report.push(err)
                }
            }
            if(report.length != 0) {
                return report.join("\n")
            }
            return undefined
        }, (history, scope, args=[]) => {
            let newHistory = [...history, scope]
            let newScope = utils.generateId()
            for(let i = 0; i < args.length; i ++) {
                setVar(newScope, args[i][0], {type: args[i][1], value: args[i][2]})
            }
            for(let i = 0; i < r[1].length; i ++) {
                let err = r[1][i](newHistory, newScope)
                if (err != undefined) {
                    return err
                }
                if (returned[0]) {
                    if (blockStack[blockStack.length-1] == "func"){
                        returned[0] = false
                        return returned[1]
                    }
                    break
                }
            }
            return undefined
        }
        ]
    }

funcdeclare
    = "func" __ ident:ident _ params:parameters _ type:type _ block:block _ {
        return [(history, scope) => {
            lastType = type
            setCompVar(scope, ident, {params: params, type: type})
            blockStack.push("func")
            let check = block[0](history, scope, params)
            blockStack.pop()
            if (check != undefined) {
                return check
            }
            return 
        }, (history, scope) => {
            setVar(scope, ident, {params: params, type: type, value: block[1]})
            return undefined
        }]
    }
    / "func" __ ident:ident _ params:parameters _ block:block _ {
        return [(history, scope) => {
            setCompVar(scope, ident, {params: params, type: consts.TYPE_UNDEFINED})
            let check = block[0](history, scope, params)
            if (check != undefined) {
                return check
            }
            return 
        }, (history, scope) => {
            setVar(scope, ident, {params: params, type: consts.TYPE_UNDEFINED, value: block[1]})
            return undefined
        }]
    }

ident
    = first:[a-z] others:[a-z0-9]* { return utils.makeIdent(first, others); }

print 
    = "print" __  exp:expression { return [printCheck(location(), exp), print(location(), exp)]; }


type
    = "int" { return consts.TYPE_INT; }
    / "string"  { return consts.TYPE_STRING; }
    / "float"  { return consts.TYPE_FLOAT; }

value
    = floatliteral 
    / intliteral 
    / stringliteral 
    / boolliteral
    / functionliteral


boolliteral 
    = "true" { return {
        value: true,
        type: consts.TYPE_BOOL,
    }}
    / "false" {return {
        value: false,
        type: consts.TYPE_BOOL,
    }
    }

intliteral
    = digits:[0-9]+ { return utils.makeInt(digits); }

returnstatement
    = "return" _ ";" { 
        return [(history, scope) => {
            return undefined
        }, 
        (history, scope) => {
            returned = [true, undefined]
            return undefined
        }]
    }
    / "return" _ exp:expression _ ";" { let locat = location();
        return [(history, scope) => {
            if(lastType == undefined) {
                return `${locat.start.line}:${locat.start.column} function do not return anything`;
            }
            let val = exp[0](history,scope)
            if(val[1] != undefined) {
                return val[1]
            }
            if (lastType != val[0]) {
                return `${locat.start.line}:${locat.start.column} return type should be ${lastType}, got ${val[0]}`;
            }
            return undefined
        }, 
        (history, scope) => {
            returned = [true, exp[1](history, scope)]
            return undefined
        }]
    }

floatliteral
    = intpart:[0-9]+ "." floatpart:[0-9]+ {  return utils.makeFloat(intpart, floatpart); }
   
stringliteral
    = '"' str:[0-9a-zA-Z ]+ '"' { return utils.makeString(str); }

functionliteral
    = "func" __ parameters _ result _ functionbody 

signature 
    = parameters result*

result 
    = type

parameters 
    = "(" _ pl:parameterlist _ ")" { return pl; }
    / "("_")" { return []; }

parameterlist
    = param:parameter _ "," _ params:parameterlist { return [...params, param]; }
    / parameter:parameter { return [parameter]; }

parameter
    = ident:ident _ type:type { return [ident, type]; }

identifierlist
    = ident / ident _ "," _ identifierlist

functionbody
    = block

arglist
    = e:expression _ "," _ a:arglist { return [...a, e]}
    / expression:expression { return [expression] }

operand 
    = value:value { return [(history, scope) => [value.type, undefined], (history, scope) => value] }
    / ident:ident { let loc = location(); return [(history, scope) => operandCheckIdent(history, scope, loc, ident), (history, scope) => {return getVar(history, scope, ident)}] }

primaryexpr
    = oper:operand _ "(" _ args:arglist _ ")" _ { let locat = location();
     return [(history, scope) => {
            let part = oper[0](history, scope)
            if (part[1] != undefined) {
                return [consts.TYPE_UNDEFINED, part[1]]
            }
            let check = part[2]
            if (check.params == undefined) {
                return  [consts.TYPE_UNDEFINED, `${locat.start.line}:${locat.start.column} given expression is not callable`]
            }
            if (args.length != check.params.length) {
                return [consts.TYPE_UNDEFINED, `${locat.start.line}:${locat.start.column} argument number expected ${check.params.length} got ${args.length}`]
            }
            for (let i = 0; i < check.params.length; i++) {
                let err = args[i][0](history, scope)
                if (err[1] != undefined) {
                    return [consts.TYPE_UNDEFINED, err[1]]
                }
                if (err[0] != check.params[i][1]) {
                    return [consts.TYPE_UNDEFINED, `${locat.start.line}:${locat.start.column} argument ${i} should be type ${check.params[i][1]}, got ${err[0]}`]
                }
            }
            return [check.type, undefined]
        }, (history, scope) => {
            let value = oper[1](history, scope)
            let argList = []
            for (let i = 0; i < args.length; i ++) {
                argList.push([value.params[i][0], value.params[i][1], args[i][1](history, scope).value])
            }
            blockStack.push("func")
            let res = value.value(history, scope, argList)
            blockStack.pop()
            return res
        }]}
    / oper:operand _ "(" _ ")" _ { let locat = location();
     return [(history, scope) => {
            let part = oper[0](history, scope)
            if (part[1] != undefined) {
                return [consts.TYPE_UNDEFINED, part[1]]
            }
            let check = part[2]
            if (check.params == undefined) {
                return  [consts.TYPE_UNDEFINED, `${locat.start.line}:${locat.start.column} given expression is not callable`]
            }
            return [check.type, undefined]
        }, (history, scope) => {
            let value = oper[1](history, scope)
            blockStack.push("func")
            let res = value.value(history, scope, [])
            blockStack.pop()
            return res
        }]}
    / oper:operand { return oper }
    

index
    = "["_ expression _ "]"

expression
    = value1:addexpr _ op:binary_op _ value2:expression { return [(history, scope) => expCheckTwoWrap(binaryCheck, history, scope, location(), op, value1, value2), (history, scope) => expTwoWrap(binary, history, scope, location(), op, value1, value2)] }
    / value:addexpr {return value}

addexpr
    = value1:mulexpr _ op:add_op _ value2:addexpr { return [(history, scope) => expCheckTwoWrap(addCheck, history, scope, location(), op, value1, value2), (history, scope) => expTwoWrap(add, history, scope, location(), op, value1, value2)] }
    / value:mulexpr { return value }
    
mulexpr
    = value1:unaryexpr _ op:mul_op _ value2:mulexpr { return [(history, scope) => expCheckTwoWrap(multiCheck, history, scope, location(), op, value1, value2), (history, scope) => expTwoWrap(multi, history, scope, location(), op, value1, value2)] }
    / value:unaryexpr { return value }

unaryexpr
    = op:unary_op _ value:unaryexpr { return [(history, scope) => expCheckOneWrap(unaryCheck, history, scope, location(), op, value), (history, scope) => expOneWrap(unary, history, scope, location(), op, value)]}
    / "(" _ value:expression _ ")" {return value}
    / value:primaryexpr { return value }

binary_op 
    = "||"
    / "&&"
    / rel_op

rel_op = "==" / "!=" / "<" / "<=" / ">" / ">="

add_op = "+" / "-" 

mul_op = "*" / "/"

unary_op = "+" / "-" / "!"


// optional whitespace
_  = [ \t\r\n]*

// mandatory whitespace
__ = [ \t\r\n]+