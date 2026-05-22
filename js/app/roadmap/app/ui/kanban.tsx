import { Array, Predicate, String } from 'effect'
import { css } from 'remix/ui'

const STATUSES = ['planned', 'active', 'completed', 'blocked', 'cancelled'] as const

const STATUS_LABELS = {
  active: 'Active',
  blocked: 'Blocked',
  cancelled: 'Cancelled',
  completed: 'Completed',
  planned: 'Planned',
} as const satisfies Record<string, string>

const STATUS_COLORS = {
  active: '#3b82f6',
  blocked: '#ef4444',
  cancelled: '#6b7280',
  completed: '#22c55e',
  planned: '#94a3b8',
} as const satisfies Record<string, string>

export type MilestoneStatus = keyof typeof STATUS_COLORS

export interface WorktreeView {
  id: string
  label: string
  color: string
  isMain: boolean
}

export interface KanbanMilestone {
  id: string
  title: string
  status: MilestoneStatus
  depends_on: readonly string[]
  prs: readonly string[]
  notes: string | null
  worktreeIds: readonly string[]
}

export interface KanbanRoadmap {
  id: string
  title: string
  worktreeIds: readonly string[]
  milestones: readonly KanbanMilestone[]
}

export interface KanbanProps {
  worktrees: readonly WorktreeView[]
  roadmaps: readonly KanbanRoadmap[]
  showRoadmaps: readonly string[]
  showWorktrees: readonly string[]
}

const toolbarStyle = css({
  '& a': { textDecoration: 'none' },
  alignItems: 'center',
  borderBottom: '1px solid #e2e8f0',
  display: 'flex',
  flexWrap: 'wrap',
  gap: '6px',
  marginBottom: '8px',
  paddingBottom: '8px',
})

const toolbarLabelStyle = css({
  color: '#64748b',
  fontSize: '12px',
  fontWeight: '600',
  marginRight: '8px',
  minWidth: '80px',
})

const toggleStyle = (active: boolean) =>
  css({
    '&:hover': { opacity: active ? '0.85' : '0.7' },
    background: active ? '#2563eb' : '#e2e8f0',
    border: 'none',
    borderRadius: '6px',
    color: active ? '#fff' : '#334155',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: active ? '600' : '400',
    opacity: active ? '1' : '0.6',
    padding: '6px 12px',
    transition: 'all 0.15s',
  })

const worktreeToggleStyle = (active: boolean, color: string) =>
  css({
    '& .swatch': {
      background: color,
      borderRadius: '50%',
      display: 'inline-block',
      height: '8px',
      marginRight: '6px',
      verticalAlign: 'middle',
      width: '8px',
    },
    '&:hover': { opacity: active ? '0.85' : '0.7' },
    alignItems: 'center',
    background: active ? color : '#e2e8f0',
    border: 'none',
    borderRadius: '6px',
    color: active ? '#fff' : '#334155',
    cursor: 'pointer',
    display: 'inline-flex',
    fontSize: '12px',
    fontWeight: active ? '600' : '400',
    opacity: active ? '1' : '0.6',
    padding: '6px 12px',
    transition: 'all 0.15s',
  })

const actionButtonStyle = css({
  '&:hover': { background: '#e2e8f0' },
  background: 'transparent',
  border: '1px solid #cbd5e1',
  borderRadius: '6px',
  color: '#475569',
  cursor: 'pointer',
  fontSize: '11px',
  fontWeight: '500',
  padding: '5px 10px',
})

const masterButtonStyle = css({
  '&:hover': { background: '#1e3a8a' },
  background: '#1e40af',
  border: 'none',
  borderRadius: '6px',
  color: '#fff',
  cursor: 'pointer',
  fontSize: '12px',
  fontWeight: '600',
  padding: '6px 14px',
})

const gridStyle = css({
  display: 'grid',
  gap: '12px',
  gridTemplateColumns: `220px repeat(${STATUSES.length}, 1fr)`,
  marginTop: '16px',
})

const gridHeaderStyle = (status: MilestoneStatus) =>
  css({
    '&::after': {
      background: STATUS_COLORS[status],
      borderRadius: '2px',
      content: "''",
      display: 'inline-block',
      height: '6px',
      marginLeft: '6px',
      width: '6px',
    },
    alignItems: 'center',
    color: '#64748b',
    display: 'flex',
    fontSize: '12px',
    fontWeight: '600',
    letterSpacing: '0.5px',
    padding: '8px 4px',
    textTransform: 'uppercase',
  })

const roadmapLabelStyle = css({
  '& .roadmap-meta': { color: '#94a3b8', fontSize: '11px', marginTop: '4px' },
  '& .roadmap-swatches': { display: 'flex', flexWrap: 'wrap', gap: '3px', marginTop: '6px' },
  '& .roadmap-swatches > span': { borderRadius: '2px', height: '10px', width: '10px' },
  '& .roadmap-title': { fontSize: '14px', fontWeight: '600' },
  padding: '8px 4px',
})

const emptyCellStyle = css({
  alignItems: 'center',
  color: '#cbd5e1',
  display: 'flex',
  fontSize: '12px',
  fontStyle: 'italic',
  justifyContent: 'center',
  minHeight: '60px',
})

const milestoneCardStyle = (status: MilestoneStatus, stripe: string) =>
  css({
    '& .ms-deps': { color: '#64748b', fontSize: '11px', marginTop: '6px' },
    '& .ms-id': { color: '#64748b', fontSize: '11px', fontWeight: '500', marginBottom: '4px' },
    '& .ms-prs': { color: '#475569', fontSize: '11px', marginTop: '4px' },
    '& .ms-prs a': { color: '#2563eb', textDecoration: 'none' },
    '& .ms-prs a:hover': { textDecoration: 'underline' },
    '& .ms-title': { fontSize: '13px', fontWeight: '500', marginTop: '4px' },
    '& .ms-worktrees': { color: '#94a3b8', fontSize: '10px', marginTop: '6px' },
    background: '#fff',
    backgroundImage: stripe,
    backgroundPosition: 'top',
    backgroundRepeat: 'no-repeat',
    backgroundSize: '100% 3px',
    border: 'none',
    borderLeft: `3px solid ${STATUS_COLORS[status]}`,
    borderRadius: '6px',
    marginBottom: '8px',
    padding: '12px 12px 10px',
  })

const buildStripe = (worktreeColors: readonly string[]): string => {
  if (Array.isReadonlyArrayEmpty(worktreeColors)) {
    return 'none'
  }
  if (worktreeColors.length === 1) {
    return `linear-gradient(${worktreeColors[0]}, ${worktreeColors[0]})`
  }
  const step = 100 / worktreeColors.length
  const stops = worktreeColors
    .flatMap((c, i) => [`${c} ${(i * step).toFixed(2)}%`, `${c} ${((i + 1) * step).toFixed(2)}%`])
    .join(', ')
  return `linear-gradient(to right, ${stops})`
}

interface FilterParams {
  roadmaps: readonly string[]
  worktrees: readonly string[]
}

const isAll = (raw: readonly string[]): boolean => Array.isReadonlyArrayEmpty(raw)

const isNone = (raw: readonly string[]): boolean =>
  raw.length === 1 && Predicate.isNotNullish(raw[0]) && String.isEmpty(raw[0])

const resolveSelection = (raw: readonly string[], allIds: readonly string[]): readonly string[] => {
  if (isAll(raw)) {
    return allIds
  }
  if (isNone(raw)) {
    return []
  }
  return raw.filter((id) => allIds.includes(id))
}

const toggle = (current: readonly string[], id: string): readonly string[] =>
  current.includes(id) ? current.filter((s) => s !== id) : [...current, id]

const encodeParam = (selected: readonly string[], all: readonly string[]): string | null => {
  if (selected.length >= all.length) {
    return null
  }
  if (Array.isReadonlyArrayEmpty(selected)) {
    return ''
  }
  return selected.join(',')
}

const buildUrl = (
  current: FilterParams,
  allRoadmaps: readonly string[],
  allWorktrees: readonly string[],
  override: Partial<FilterParams>,
): string => {
  const rSel = override.roadmaps ?? resolveSelection(current.roadmaps, allRoadmaps)
  const wSel = override.worktrees ?? resolveSelection(current.worktrees, allWorktrees)
  const r = encodeParam(rSel, allRoadmaps)
  const w = encodeParam(wSel, allWorktrees)
  const parts: string[] = []
  if (Predicate.isNotNullish(r)) {
    parts.push(`roadmaps=${r}`)
  }
  if (Predicate.isNotNullish(w)) {
    parts.push(`worktrees=${w}`)
  }
  return Array.isArrayEmpty(parts) ? '?' : `?${parts.join('&')}`
}

const formatPrLabel = (pr: string): string => {
  const match = /\/(?:pull|issues)\/(\d+)/.exec(pr)
  return Predicate.isNullish(match) ? pr : `#${match[1]}`
}

export const Kanban = () => (props: KanbanProps) => {
  const { roadmaps, showRoadmaps: rawR, showWorktrees: rawW, worktrees } = props
  const allRoadmapIds = roadmaps.map((r) => r.id)
  const allWorktreeIds = worktrees.map((w) => w.id)
  const visibleRoadmapIds = resolveSelection(rawR, allRoadmapIds)
  const visibleWorktreeIds = resolveSelection(rawW, allWorktreeIds)
  const visibleWorktreeSet = new Set(visibleWorktreeIds)
  const worktreeColor = (id: string): string => worktrees.find((w) => w.id === id)?.color ?? '#94a3b8'
  const worktreeLabel = (id: string): string => worktrees.find((w) => w.id === id)?.label ?? id

  const filteredRoadmaps = roadmaps
    .filter((r) => visibleRoadmapIds.includes(r.id))
    .map((r) => {
      const milestones = r.milestones
        .map((m) => ({ ...m, worktreeIds: m.worktreeIds.filter((wid) => visibleWorktreeSet.has(wid)) }))
        .filter((m) => Array.isReadonlyArrayNonEmpty(m.worktreeIds))
      const roadmapWorktreeIds = r.worktreeIds.filter((wid) => visibleWorktreeSet.has(wid))
      return { ...r, milestones, worktreeIds: roadmapWorktreeIds }
    })
    .filter((r) => Array.isReadonlyArrayNonEmpty(r.worktreeIds))

  const current: FilterParams = { roadmaps: rawR, worktrees: rawW }

  return (
    <div>
      <div mix={toolbarStyle}>
        <span mix={toolbarLabelStyle}>Master:</span>
        <a href='?'>
          <button type='button' mix={masterButtonStyle}>
            All
          </button>
        </a>
        <a href={buildUrl(current, allRoadmapIds, allWorktreeIds, { roadmaps: [], worktrees: [] })}>
          <button type='button' mix={masterButtonStyle}>
            None
          </button>
        </a>
      </div>

      <div mix={toolbarStyle}>
        <span mix={toolbarLabelStyle}>Roadmaps:</span>
        <a href={buildUrl(current, allRoadmapIds, allWorktreeIds, { roadmaps: allRoadmapIds })}>
          <button type='button' mix={actionButtonStyle}>
            All
          </button>
        </a>
        <a href={buildUrl(current, allRoadmapIds, allWorktreeIds, { roadmaps: [] })}>
          <button type='button' mix={actionButtonStyle}>
            None
          </button>
        </a>
        <span style={{ color: '#cbd5e1', margin: '0 4px' }}>|</span>
        {roadmaps.map((r) => {
          const active = visibleRoadmapIds.includes(r.id)
          const next = toggle(visibleRoadmapIds, r.id)
          return (
            <a key={r.id} href={buildUrl(current, allRoadmapIds, allWorktreeIds, { roadmaps: next })}>
              <button type='button' mix={toggleStyle(active)}>
                {r.title}
              </button>
            </a>
          )
        })}
      </div>

      <div mix={toolbarStyle}>
        <span mix={toolbarLabelStyle}>Worktrees:</span>
        <a href={buildUrl(current, allRoadmapIds, allWorktreeIds, { worktrees: allWorktreeIds })}>
          <button type='button' mix={actionButtonStyle}>
            All
          </button>
        </a>
        <a href={buildUrl(current, allRoadmapIds, allWorktreeIds, { worktrees: [] })}>
          <button type='button' mix={actionButtonStyle}>
            None
          </button>
        </a>
        <span style={{ color: '#cbd5e1', margin: '0 4px' }}>|</span>
        {worktrees.map((w) => {
          const active = visibleWorktreeIds.includes(w.id)
          const next = toggle(visibleWorktreeIds, w.id)
          return (
            <a key={w.id} href={buildUrl(current, allRoadmapIds, allWorktreeIds, { worktrees: next })}>
              <button type='button' mix={worktreeToggleStyle(active, w.color)}>
                <span class='swatch' />
                {w.label}
                {w.isMain ? ' ★' : ''}
              </button>
            </a>
          )
        })}
      </div>

      <div mix={gridStyle}>
        <div />
        {STATUSES.map((s) => (
          <div key={s} mix={gridHeaderStyle(s)}>
            {STATUS_LABELS[s]}
          </div>
        ))}

        {filteredRoadmaps.flatMap((roadmap) => [
          <div key={`label-${roadmap.id}`} mix={roadmapLabelStyle}>
            <div class='roadmap-title'>{roadmap.title}</div>
            <div class='roadmap-meta'>
              {roadmap.id} · {roadmap.milestones.length} milestones · {roadmap.worktreeIds.length} wt
            </div>
            <div class='roadmap-swatches'>
              {roadmap.worktreeIds.map((wid) => (
                <span key={wid} style={{ background: worktreeColor(wid) }} title={worktreeLabel(wid)} />
              ))}
            </div>
          </div>,
          ...STATUSES.map((status) => {
            const items = roadmap.milestones.filter((m) => m.status === status)
            if (Array.isReadonlyArrayEmpty(items)) {
              return (
                <div key={`${roadmap.id}-${status}`} mix={emptyCellStyle}>
                  —
                </div>
              )
            }
            return (
              <div key={`${roadmap.id}-${status}`}>
                {items.map((m) => {
                  const stripeColors = m.worktreeIds.map(worktreeColor)
                  const stripe = buildStripe(stripeColors)
                  return (
                    <div key={`${m.id}-${m.worktreeIds.join('|')}`} mix={milestoneCardStyle(m.status, stripe)}>
                      <div class='ms-id'>{m.id}</div>
                      <div class='ms-title'>{m.title}</div>
                      {Array.isReadonlyArrayNonEmpty(m.depends_on) && (
                        <div class='ms-deps'>← depends on: {m.depends_on.join(', ')}</div>
                      )}
                      {Array.isReadonlyArrayNonEmpty(m.prs) && (
                        <div class='ms-prs'>
                          PRs:{' '}
                          {m.prs.map((pr, i) => (
                            <span key={pr}>
                              {i > 0 && ', '}
                              {pr.startsWith('http') ? (
                                <a href={pr} target='_blank' rel='noopener noreferrer'>
                                  {formatPrLabel(pr)}
                                </a>
                              ) : (
                                pr
                              )}
                            </span>
                          ))}
                        </div>
                      )}
                      <div class='ms-worktrees'>
                        {m.worktreeIds.length === worktrees.length
                          ? 'all worktrees'
                          : m.worktreeIds.map(worktreeLabel).join(', ')}
                      </div>
                    </div>
                  )
                })}
              </div>
            )
          }),
        ])}
      </div>
    </div>
  )
}
