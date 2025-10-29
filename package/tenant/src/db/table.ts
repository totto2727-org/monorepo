/** biome-ignore-all lint/performance/noBarrelFile: package endpoint */

export { table as organizationTable } from "./table/organization.js"

export {
  organizationLinkRelation,
  organizationRelation as organizationLinkOrganizationRelation,
  table as organizationLinkTable,
} from "./table/organization-link.js"

export {
  primaryProviderRelation,
  table as primaryUserLinkTable,
  userLinkRelation as primaryUserLinkUserLinkRelation,
  userRelation as primaryUserLinkUserRelation,
} from "./table/primary-user-link.js"

export { table as userTable } from "./table/user.js"

export {
  table as userLinkTable,
  userLinkRelation,
  userRelation as userLinkUserRelation,
} from "./table/user-link.js"
