peg = require("./grammar");
peg.parse(`var v int := 1;
func main(a int) {
    print v;
}
main(123);
`);
