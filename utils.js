const consts = require("./const");

function makeInt(o) {
  return { value: parseInt(o.join(""), 10), type: consts.TYPE_INT };
}

function makeFloat(i, d) {
  return {
    value: parseFloat(i.join("") + "." + d.join("")),
    type: consts.TYPE_FLOAT,
  };
}

function makeString(s) {
  return { value: s.join(""), type: consts.TYPE_STRING };
}

function makeIdent(f, o) {
  if (o == undefined) {
    return f;
  }
  return f + o.join("");
}

function generateId() {
  let symbols =
    "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890";
  let res = "";
  for (let i = 0; i < 10; i++) {
    res = res + symbols[Math.floor(Math.random() * symbols.length)];
  }
  return res;
}

function makeContext(scopes, payload) {
  return {
    scopes,
    payload,
  };
}

module.exports = {
  makeFloat,
  makeInt,
  makeString,
  makeIdent,
  generateId,
};
