import { Array as Arr, Predicate, String as Str } from 'effect'
import { css } from 'remix/ui'

export interface KanbanRoadmap {
  id: string
  title: string
  status: string
  prs: readonly string[]
  milestones: KanbanMilestone[]
}

export interface KanbanMilestone {
  id: string
  title: string
  status: string
  depends_on: readonly string[]
  prs: readonly string[]
  notes: string | null
}

const STATUSES = ['planned', 'active', 'completed', 'blocked', 'cancelled'] as const

const STATUS_LABELS: Record<string, string> = {
  active: 'Active',
  blocked: 'Blocked',
  cancelled: 'Cancelled',
  completed: 'Completed',
  planned: 'Planned',
}

const STATUS_COLORS: Record<string, string> = {
  active: '#3b82f6',
  blocked: '#ef4444',
  cancelled: '#6b7280',
  completed: '#22c55e',
  planned: '#94a3b8',
}

const toolbarStyle = css({
  '& a': { textDecoration: 'none' },
  alignItems: 'center',
  borderBottom: '1px solid #e2e8f0',
  display: 'flex',
  flexWrap: 'wrap',
  gap: '6px',
  marginBottom: '20px',
  paddingBottom: '12px',
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

const gridStyle = css({
  display: 'grid',
  gap: '12px',
  gridTemplateColumns: `200px repeat(${STATUSES.length}, 1fr)`,
})

const gridHeaderStyle = (status: string) =>
  css({
    '&::after': {
      background: STATUS_COLORS[status] ?? '#94a3b8',
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
  '& .roadmap-meta': { color: '#94a3b8', fontSize: '11px', marginTop: '2px' },
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

const milestoneCardStyle = (status: string) =>
  css({
    '& .ms-deps': { color: '#64748b', fontSize: '11px', marginTop: '6px' },
    '& .ms-header': { alignItems: 'center', display: 'flex', gap: '8px', marginBottom: '4px' },
    '& .ms-id': { color: '#64748b', fontSize: '11px', fontWeight: '500' },
    '& .ms-prs': { color: '#475569', fontSize: '11px', marginTop: '4px' },
    '& .ms-prs a': { color: '#2563eb', textDecoration: 'none' },
    '& .ms-prs a:hover': { textDecoration: 'underline' },
    '& .ms-status': {
      borderRadius: '4px',
      display: 'inline-block',
      fontSize: '9px',
      fontWeight: '600',
      letterSpacing: '0.5px',
      padding: '2px 6px',
      textTransform: 'uppercase',
    },
    '& .ms-title': { fontSize: '13px', fontWeight: '500', marginTop: '4px' },
    background: '#fff',
    border: 'none',
    borderLeft: `3px solid ${STATUS_COLORS[status] ?? '#94a3b8'}`,
    borderRadius: '6px',
    marginBottom: '8px',
    padding: '10px 12px',
  })

const toggleShow = (current: string[], id: string): string[] => {
  if (current.includes(id)) {
    return current.filter((s) => s !== id)
  }
  return [...current, id]
}

const buildUrl = (allIds: string[], show: string[], toggleId: string | undefined): string => {
  const next = Predicate.isNullish(toggleId) ? show : toggleShow(show, toggleId)
  if (next.length >= allIds.length) {
    return '?'
  }
  if (Arr.isArrayEmpty(next)) {
    return '?show='
  }
  return `?show=${next.join(',')}`
}

export interface KanbanProps {
  roadmaps: KanbanRoadmap[]
  show: string[]
}

const STATUS_BADGE_BG: Record<string, string> = {
  active: '#dbeafe',
  blocked: '#fee2e2',
  cancelled: '#f3f4f6',
  completed: '#dcfce7',
  planned: '#f1f5f9',
}

const STATUS_BADGE_COLOR: Record<string, string> = {
  active: '#1d4ed8',
  blocked: '#dc2626',
  cancelled: '#6b7280',
  completed: '#16a34a',
  planned: '#64748b',
}

export const Kanban = () => (props: KanbanProps) => {
  const { roadmaps, show: rawShow } = props
  const allIds = roadmaps.map((r) => r.id)
  const isAll = Arr.isArrayEmpty(rawShow) || rawShow[0] === 'all'
  const isNone = rawShow.length === 1 && Predicate.isNotNullish(rawShow[0]) && Str.isEmpty(rawShow[0])
  const resolveShow = (): string[] => {
    if (isAll) {
      return allIds
    }
    if (isNone) {
      return []
    }
    return rawShow.filter((id) => allIds.includes(id))
  }
  const show = resolveShow()
  const visible = roadmaps.filter((r) => show.includes(r.id))

  return (
    <div>
      <div mix={toolbarStyle}>
        <span style='color:#64748b;font-size:12px;margin-right:8px'>Filter:</span>
        {roadmaps.map((r) => (
          <a key={r.id} href={buildUrl(allIds, show, r.id)}>
            <button type='button' mix={toggleStyle(show.includes(r.id))}>
              {r.title}
            </button>
          </a>
        ))}
        <span style='color:#cbd5e1;margin:0 4px'>|</span>
        <a href='?'>
          <button type='button' mix={actionButtonStyle}>
            All
          </button>
        </a>
        <a href='?show='>
          <button type='button' mix={actionButtonStyle}>
            None
          </button>
        </a>
      </div>

      <div mix={gridStyle}>
        <div />
        {STATUSES.map((s) => (
          <div key={s} mix={gridHeaderStyle(s)}>
            {STATUS_LABELS[s]}
          </div>
        ))}

        {visible.flatMap((roadmap) => [
          <div key={`label-${roadmap.id}`} mix={roadmapLabelStyle}>
            <div class='roadmap-title'>{roadmap.title}</div>
            <div class='roadmap-meta'>
              {roadmap.id} · {roadmap.milestones.length} milestones
              {Arr.isReadonlyArrayNonEmpty(roadmap.prs) &&
                ` · ${roadmap.prs.length} PR${roadmap.prs.length === 1 ? '' : 's'}`}
            </div>
          </div>,
          ...STATUSES.map((status) => {
            const items = roadmap.milestones.filter((m) => m.status === status)
            if (Arr.isArrayEmpty(items)) {
              return (
                <div key={`${roadmap.id}-${status}`} mix={emptyCellStyle}>
                  —
                </div>
              )
            }
            return (
              <div key={`${roadmap.id}-${status}`}>
                {items.map((m) => (
                  <div key={m.id} mix={milestoneCardStyle(m.status)}>
                    <div class='ms-header'>
                      <span class='ms-id'>{m.id}</span>
                      <span
                        class='ms-status'
                        style={`background:${STATUS_BADGE_BG[m.status]};color:${STATUS_BADGE_COLOR[m.status]}`}
                      >
                        {STATUS_LABELS[m.status]}
                      </span>
                    </div>
                    <div class='ms-title'>{m.title}</div>
                    {Arr.isReadonlyArrayNonEmpty(m.depends_on) && (
                      <div class='ms-deps'>← depends on: {m.depends_on.join(', ')}</div>
                    )}
                    {Arr.isReadonlyArrayNonEmpty(m.prs) && (
                      <div class='ms-prs'>
                        PRs:{' '}
                        {m.prs.map((pr, i) => (
                          <span key={pr}>
                            {i > 0 && ', '}
                            {pr.startsWith('http') ? <a href={pr}>{pr}</a> : pr}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )
          }),
        ])}
      </div>
    </div>
  )
}
