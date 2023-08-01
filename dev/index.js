const fs = require("fs");
const jsonabc = require("jsonabc");
const xmlFormatter = require("./xml-formatter");

const directory = process.argv[2];
const files = fs.readdirSync(directory);
for (const file of files) {
  if (file.includes("json")) {
    let inputStr = fs.readFileSync(`${directory}/${file}`, "utf-8");
    inputStr = jsonabc.cleanJSON(inputStr);
    obj = JSON.parse(inputStr);
    r = jsonabc.sortObj(obj, true);
    output = JSON.stringify(r, null, 2);
    fs.writeFileSync(`dist/${file}`, output + "\n");
  }
  if (file.includes("html")) {
    const inputStr = fs.readFileSync(`${directory}/${file}`, "utf-8");
    const output = xmlFormatter(inputStr, {
      indentation: "",
      lineSeparator: "\n",
      strictMode: true,
    });
    fs.writeFileSync(`dist/${file}`, output + "\n");
  }
}
