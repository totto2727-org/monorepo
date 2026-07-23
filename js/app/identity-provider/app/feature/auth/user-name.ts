import { String } from 'effect'

interface UserNameSource {
  readonly email: string
  readonly name: string
}

export const initialUserName = ({ email, name }: UserNameSource): string => {
  if (String.isNonEmpty(name.trim())) {
    return name
  }

  const separatorIndex = email.lastIndexOf('@')
  return separatorIndex > 0 ? email.slice(0, separatorIndex) : email
}
