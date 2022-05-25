peg = require("./grammar");
const fs = require("fs");

fs.readFile("./main.kwa", "utf8", (err, data) => {
  if (err) {
    console.error(err);
    return;
  }
  peg.parse(data);
});