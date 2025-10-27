import { Predicate, String } from "@totto/function/effect"
import type { Adapter, Model } from "casbin"
import { Helper } from "casbin"
import { type Column, eq, or } from "drizzle-orm"
import type { BaseSQLiteDatabase } from "drizzle-orm/sqlite-core"
import { casbinRule } from "./table.js"

// biome-ignore lint/suspicious/noExplicitAny: required
export type AnyDrizzleDB = BaseSQLiteDatabase<any, any>

export class DrizzleAdapter implements Adapter {
  readonly #db: AnyDrizzleDB

  #filtered = false

  isFiltered(): boolean {
    return this.#filtered
  }

  enableFiltered(enabled: boolean): void {
    this.#filtered = enabled
  }

  constructor(db: AnyDrizzleDB) {
    this.#db = db
  }

  async loadPolicy(model: Model): Promise<void> {
    const lines = await this.#db.select().from(casbinRule)

    for (const line of lines) {
      this.#loadPolicyLine(line, model)
    }
  }

  #shouldFilter(v: string | undefined): v is string {
    return Predicate.isString(v) && String.isNonEmpty(v)
  }

  #generateNullableEqFilter(column: Column, value: string | undefined) {
    return this.#shouldFilter(value) ? eq(column, value) : undefined
  }

  #generateWhere(ptype: string, ruleArray: string[], fieldIndex = 0) {
    return [
      eq(casbinRule.ptype, ptype),
      this.#generateNullableEqFilter(casbinRule.v0, ruleArray[0]),
      this.#generateNullableEqFilter(casbinRule.v1, ruleArray[1]),
      this.#generateNullableEqFilter(casbinRule.v2, ruleArray[2]),
      this.#generateNullableEqFilter(casbinRule.v3, ruleArray[3]),
      this.#generateNullableEqFilter(casbinRule.v4, ruleArray[4]),
      this.#generateNullableEqFilter(casbinRule.v5, ruleArray[5]),
    ]
      .slice(fieldIndex + 1)
      .filter((v) => Predicate.isNotNullable(v))
  }

  async loadFilteredPolicy(
    model: Model,
    filter: { [key: string]: string[][] },
  ): Promise<void> {
    const lines = await this.#db
      .select()
      .from(casbinRule)
      .where(
        or(
          ...Object.entries(filter).flatMap(([ptype, policyPatterns]) =>
            policyPatterns.flatMap((policyPattern) =>
              this.#generateWhere(ptype, policyPattern),
            ),
          ),
        ),
      )

    for (const line of lines) {
      this.#loadPolicyLine(line, model)
    }

    this.enableFiltered(true)
  }

  #modelToDTOArray(
    model: Model,
    ptype: string,
  ): (typeof casbinRule.$inferInsert)[] {
    const astMap = model.model.get(ptype)
    if (!astMap) {
      return []
    }
    return astMap
      .entries()
      .flatMap(([ptype, ast]) =>
        ast.policy.map((rule) => [ptype, rule] as const),
      )
      .map(([ptype, rule]) => this.#arrayToDTO(ptype, rule))
      .toArray()
  }

  async savePolicy(model: Model): Promise<boolean> {
    await this.#db.delete(casbinRule)
    await this.#db
      .insert(casbinRule)
      .values([
        ...this.#modelToDTOArray(model, "p"),
        ...this.#modelToDTOArray(model, "g"),
      ])

    return true
  }

  async addPolicy(_: string, ptype: string, rule: string[]): Promise<void> {
    await this.#db.insert(casbinRule).values(this.#arrayToDTO(ptype, rule))
  }

  async addPolicies(
    _: string,
    ptype: string,
    rules: string[][],
  ): Promise<void> {
    await this.#db
      .insert(casbinRule)
      .values(rules.map((rule) => this.#arrayToDTO(ptype, rule)))
  }

  async removePolicy(_: string, ptype: string, rule: string[]): Promise<void> {
    await this.#db
      .delete(casbinRule)
      .where(or(...this.#generateWhere(ptype, rule)))
  }

  async removePolicies(
    _sec: string,
    ptype: string,
    rules: string[][],
  ): Promise<void> {
    await this.#db
      .delete(casbinRule)
      .where(or(...rules.flatMap((rule) => this.#generateWhere(ptype, rule))))
  }

  async removeFilteredPolicy(
    _sec: string,
    ptype: string,
    fieldIndex: number,
    ...fieldValues: string[]
  ): Promise<void> {
    await this.#db
      .delete(casbinRule)
      .where(or(...this.#generateWhere(ptype, fieldValues, fieldIndex)))
  }

  #loadPolicyLine(line: typeof casbinRule.$inferInsert, model: Model): void {
    Helper.loadPolicyLine(
      [line.ptype, line.v0, line.v1, line.v2, line.v3, line.v4, line.v5]
        .filter((n) => Predicate.isNotNullable(n))
        .join(", "),
      model,
    )
  }

  readonly #arrayToDTO = (
    ptype: string,
    rule: string[],
  ): typeof casbinRule.$inferInsert => ({
    ptype,
    v0: rule[0],
    v1: rule[1],
    v2: rule[2],
    v3: rule[3],
    v4: rule[4],
    v5: rule[5],
  })
}
