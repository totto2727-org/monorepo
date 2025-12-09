import path from "node:path"
import type { PlopTypes } from "@turbo/gen"

const workspace = path.resolve(__dirname, "../..")
const template = path.resolve(__dirname, "template")

function makeTargetPath(targetPath: string) {
  return path.join(workspace, targetPath)
}

function makeTemplatePath(templatePath: string) {
  return path.join(template, templatePath)
}

export default function generator(plop: PlopTypes.NodePlopAPI): void {
  plop.setGenerator("schema", {
    actions: [
      {
        path: "{{ targetPath }}/{{snakeCase name}}.ts",
        templateFile: makeTemplatePath("schema/schema.ts.hbs"),
        type: "add",
      },
    ],
    description: "Adds a new schema",
    prompts: [
      {
        message: "What is the target path of the schema?",
        name: "targetPath",
        type: "input",
      },
      {
        message: "What is the name of the schema?",
        name: "name",
        type: "input",
      },
    ],
  })

  plop.setGenerator("package", {
    actions: [
      {
        base: makeTemplatePath("package"),
        destination: makeTargetPath("package/{{kebabCase name}}"),
        templateFiles: makeTemplatePath("package/**/*.hbs"),
        type: "addMany",
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
