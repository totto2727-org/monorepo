import { getContext } from '#@/feature/share/lib/tanstack-query/provider.tsx'
import { Button } from '@package/ui/components/ui/button'
import { queryCollectionOptions } from '@tanstack/query-db-collection'
import { createCollection, useLiveQuery } from '@tanstack/react-db'
import { ClientOnly, createFileRoute, Link } from '@tanstack/react-router'
import { createStore, useStore } from '@tanstack/react-store'
import { Function, Schema } from 'effect'

const countStore = createStore(0)

const Counter = () => {
  const count = useStore(countStore, Function.identity)
  return (
    <div>
      <div>{count}</div>
      <Button onClick={() => countStore.setState((c) => c + 1)}>Increment</Button>
      <div>{count}</div>
      <Button onClick={() => countStore.setState((c) => c + 1)}>Increment</Button>
    </div>
  )
}

const pokemonSchema = Schema.Struct({ name: Schema.String, url: Schema.String })
const pokeAPISchema = Schema.Struct({ results: Schema.Array(pokemonSchema) })
const decodePokeAPI = Schema.decodeSync(pokeAPISchema)

const pokemonCollection = createCollection(
  queryCollectionOptions({
    getKey: (item) => item.name,
    queryClient: getContext().queryClient,
    queryFn: async () => {
      const response = await fetch('https://pokeapi.co/api/v2/pokemon/?limit=20')
      //
      return [...decodePokeAPI(await response.json()).results]
    },
    queryKey: ['pokemon'],
    schema: Schema.toStandardSchemaV1(pokemonSchema),
  }),
)

const loadMoreButton = async (length: number) => {
  const response = await fetch(`https://pokeapi.co/api/v2/pokemon/?limit=20&offset=${length}`)
  const { results } = decodePokeAPI(await response.json())
  pokemonCollection.utils.writeBatch(() => {
    for (const pokemon of results) {
      pokemonCollection.utils.writeInsert(pokemon)
    }
  })
  return { refetch: false }
}

const PokemonList = () => {
  const { data: pokemon } = useLiveQuery((q) =>
    q.from({ pokemon: pokemonCollection }).orderBy((v) => v.pokemon.name, 'asc'),
  )

  return (
    <div>
      <ul>
        <div>{pokemon.length}</div>
        {pokemon?.map((p) => (
          <li key={p.name}>
            {p.name}: {p.url}
          </li>
        ))}
      </ul>
      <Button onClick={() => loadMoreButton(pokemon.length)}>Load More</Button>
    </div>
  )
}

const App = () => (
  <main>
    <h1>Hello, World!</h1>
    <p>Welcome to the Saas Example App.</p>
    <Link to='/'>Home</Link>

    <Counter />

    {/* Tanstack DBがSSRに対応しておらず、useSyncExternalStore周りでエラーとなるため、ClientOnlyでラップする */}
    <ClientOnly fallback={<div>Loading...</div>}>
      <PokemonList />
    </ClientOnly>
  </main>
)

export const Route = createFileRoute('/')({ component: App })
