const TYPE_INT = "TYPE_INT";
const TYPE_STRING = "TYPE_STRING";
const TYPE_FLOAT = "TYPE_FLOAT";
const TYPE_BOOL = "TYPE_BOOL";
const TYPE_UNDEFINED = "TYPE_UNDEFINED";

var typeNullValue = (() => {
  let res = new Map();
  res.set(TYPE_INT, 0);
  res.set(TYPE_STRING, "");
  res.set(TYPE_FLOAT, 0.0);
  res.set(TYPE_BOOL, false);
  res.set(TYPE_UNDEFINED, undefined);
  return res;
})();

module.exports = {
  TYPE_BOOL,
  TYPE_FLOAT,
  TYPE_INT,
  TYPE_STRING,
  TYPE_UNDEFINED,
  typeNullValue
};
