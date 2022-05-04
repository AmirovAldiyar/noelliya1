function makeInt(o) {
    return parseInt(o.join(""), 10)
}

function makeFloat(i, d) {
    return parseFloat(i.join("") + "." + d.join(""))
}

function makeString(s) {
    return s.join("")
}

function makeIdent(f, o) {
    if(o == undefined) {
        return f
    }
    return f + o.join("")
}

module.exports = {
    makeFloat,
    makeInt,
    makeString,
    makeIdent
}