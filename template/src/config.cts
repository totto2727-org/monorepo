import type { PlopTypes } from "@turbo/gen"

module.exports = function generator(plop: PlopTypes.NodePlopAPI): void {
  plop.setGenerator("package", {
    actions: [
      {
        path: "../../../package/{{snakeCase name}}/package.json",
        templateFile: "./template/package/package.json.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/src/index.ts",
        templateFile: "./template/package/src/index.ts.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/.gitignore",
        templateFile: "./template/package/.gitignore.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/biome.jsonc",
        templateFile: "./template/package/biome.jsonc.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/dprint.json",
        templateFile: "./template/package/dprint.json.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/README.md",
        templateFile: "./template/package/README.md.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/tsconfig.json",
        templateFile: "./template/package/tsconfig.json.hbs",
        type: "add",
      },
      {
        path: "../../../package/{{snakeCase name}}/tsdown.config.ts",
        templateFile: "./template/package/tsdown.config.ts.hbs",
        type: "add",
      },
    ],
    description: "Adds a new package",
    prompts: [
      {
        message: "What is the name of the package?",
        name: "name",
        type: "input",
      },
    ],
  })
}
