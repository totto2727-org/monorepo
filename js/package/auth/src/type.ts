export interface User {
  readonly email: string
  readonly id: string
}

export interface AuthVariables {
  readonly user: User
}

export interface OptionalAuthVariables {
  readonly user: User | null
}
