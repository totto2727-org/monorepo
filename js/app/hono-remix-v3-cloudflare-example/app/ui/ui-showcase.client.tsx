import { clientEntry, css } from 'remix/ui'
import type { Handle, RemixNode, SerializableProps } from 'remix/ui'
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from 'remix/ui/accordion'
import { Breadcrumbs } from 'remix/ui/breadcrumbs'
import { Button } from 'remix/ui/button'
import {
  Combobox,
  ComboboxOption,
  inputStyle as comboboxInputStyle,
  popoverStyle as comboboxPopoverStyle,
} from 'remix/ui/combobox'
import { Glyph } from 'remix/ui/glyph'
import {
  glyphStyle as listboxGlyphStyle,
  labelStyle as listboxLabelStyle,
  listStyle as listboxListStyle,
  optionStyle as listboxOptionStyle,
} from 'remix/ui/listbox'
import {
  buttonStyle as menuButtonStyle,
  itemLabelStyle as menuItemLabelStyle,
  itemSlotStyle as menuItemSlotStyle,
  itemStyle as menuItemStyle,
  listStyle as menuListStyle,
  popoverStyle as menuPopoverStyle,
  triggerGlyphStyle as menuTriggerGlyphStyle,
} from 'remix/ui/menu'
import { contentStyle as popoverContentStyle, surfaceStyle as popoverSurfaceStyle } from 'remix/ui/popover'
import { triggerStyle as selectTriggerStyle } from 'remix/ui/select'
import { separatorStyle } from 'remix/ui/separator'

const pageStyle = css({
  display: 'flex',
  flexDirection: 'column',
  gap: '40px',
  margin: '0 auto',
  maxWidth: '880px',
  padding: '32px 16px 80px',
})

const sectionStyle = css({
  display: 'flex',
  flexDirection: 'column',
  gap: '12px',
})

const Section = (handle: Handle<{ title: string; children?: RemixNode }>) => () => (
  <section mix={sectionStyle}>
    <h2>{handle.props.title}</h2>
    {handle.props.children}
  </section>
)

export const UiShowcase = clientEntry(
  '/assets/app/ui/ui-showcase.client.tsx#UiShowcase',
  (_handle: Handle<SerializableProps>) => () => (
    <div mix={pageStyle}>
      <header>
        <h1>remix/ui Components</h1>
        <p>Default shipped styles via the RMX_01 theme preset.</p>
      </header>

      <Section title='Accordion'>
        <Accordion collapsible defaultValue='item-1'>
          <AccordionItem value='item-1'>
            <AccordionTrigger>What is Remix?</AccordionTrigger>
            <AccordionContent>Remix is a server-first web framework built on Web standard APIs.</AccordionContent>
          </AccordionItem>
          <AccordionItem value='item-2'>
            <AccordionTrigger>Why server-first?</AccordionTrigger>
            <AccordionContent>Better performance, simpler mental model, and resilient hydration.</AccordionContent>
          </AccordionItem>
          <AccordionItem value='item-3'>
            <AccordionTrigger>Where to start?</AccordionTrigger>
            <AccordionContent>Read the docs at remix.run.</AccordionContent>
          </AccordionItem>
        </Accordion>

        <Accordion type='multiple' defaultValue={['a', 'c']}>
          <AccordionItem value='a'>
            <AccordionTrigger>First panel</AccordionTrigger>
            <AccordionContent>Multiple panels can be open at once.</AccordionContent>
          </AccordionItem>
          <AccordionItem value='b'>
            <AccordionTrigger>Second panel</AccordionTrigger>
            <AccordionContent>Independent open/close state per item.</AccordionContent>
          </AccordionItem>
          <AccordionItem value='c'>
            <AccordionTrigger>Third panel</AccordionTrigger>
            <AccordionContent>Open by default via the defaultValue array.</AccordionContent>
          </AccordionItem>
        </Accordion>
      </Section>

      <Section title='Breadcrumbs'>
        <Breadcrumbs
          items={[
            { href: '/', label: 'Home' },
            { href: '/ui', label: 'UI' },
            { href: '/ui/components', label: 'Components' },
            { current: true, label: 'Breadcrumbs' },
          ]}
        />
      </Section>

      <Section title='Button'>
        <Button tone='primary'>Primary</Button>
        <Button tone='secondary'>Secondary</Button>
        <Button tone='ghost'>Ghost</Button>
        <Button tone='danger'>Danger</Button>
        <Button tone='primary' startIcon={<Glyph name='add' />}>
          Add item
        </Button>
        <Button tone='secondary' endIcon={<Glyph name='chevronDown' />}>
          More
        </Button>
        <Button tone='ghost' disabled>
          Disabled
        </Button>
      </Section>

      <Section title='Combobox'>
        <Combobox name='fruit' defaultValue=''>
          <input mix={comboboxInputStyle} placeholder='Pick a fruit' />
          <ul mix={comboboxPopoverStyle}>
            <ComboboxOption value='apple' label='Apple'>
              Apple
            </ComboboxOption>
            <ComboboxOption value='banana' label='Banana'>
              Banana
            </ComboboxOption>
            <ComboboxOption value='cherry' label='Cherry'>
              Cherry
            </ComboboxOption>
            <ComboboxOption value='date' label='Date'>
              Date
            </ComboboxOption>
            <ComboboxOption value='elderberry' label='Elderberry'>
              Elderberry
            </ComboboxOption>
          </ul>
        </Combobox>
      </Section>

      <Section title='Glyph'>
        <Glyph name='add' />
        <Glyph name='check' />
        <Glyph name='chevronDown' />
        <Glyph name='close' />
        <Glyph name='search' />
        <Glyph name='spinner' />
        <Glyph name='trash' />
      </Section>

      <Section title='Listbox'>
        <ul mix={listboxListStyle} role='listbox' aria-label='Fruit'>
          <li mix={listboxOptionStyle} role='option' aria-selected='true'>
            <span mix={listboxGlyphStyle}>
              <Glyph name='check' />
            </span>
            <span mix={listboxLabelStyle}>Apple</span>
          </li>
          <li mix={listboxOptionStyle} role='option' aria-selected='false'>
            <span mix={listboxGlyphStyle} />
            <span mix={listboxLabelStyle}>Banana</span>
          </li>
          <li mix={listboxOptionStyle} role='option' aria-selected='false'>
            <span mix={listboxGlyphStyle} />
            <span mix={listboxLabelStyle}>Cherry</span>
          </li>
        </ul>
      </Section>

      <Section title='Menu'>
        <button type='button' mix={menuButtonStyle}>
          Actions
          <span mix={menuTriggerGlyphStyle}>
            <Glyph name='chevronDown' />
          </span>
        </button>
        <div mix={menuPopoverStyle}>
          <ul mix={menuListStyle} role='menu'>
            <li mix={menuItemStyle} role='menuitem'>
              <span mix={menuItemSlotStyle}>
                <Glyph name='add' />
              </span>
              <span mix={menuItemLabelStyle}>New</span>
            </li>
            <li mix={menuItemStyle} role='menuitem'>
              <span mix={menuItemSlotStyle}>
                <Glyph name='check' />
              </span>
              <span mix={menuItemLabelStyle}>Mark complete</span>
            </li>
            <li mix={menuItemStyle} role='menuitem' aria-disabled='true'>
              <span mix={menuItemSlotStyle} />
              <span mix={menuItemLabelStyle}>Disabled item</span>
            </li>
            <li mix={menuItemStyle} role='menuitem'>
              <span mix={menuItemSlotStyle}>
                <Glyph name='close' />
              </span>
              <span mix={menuItemLabelStyle}>Close</span>
            </li>
          </ul>
        </div>
      </Section>

      <Section title='Popover'>
        <div mix={popoverSurfaceStyle}>
          <div mix={popoverContentStyle}>
            <p>Popover content here.</p>
            <p>Default surface + content styling from remix/ui/popover.</p>
          </div>
        </div>
      </Section>

      <Section title='Select'>
        <button type='button' mix={selectTriggerStyle}>
          Choose an option
          <Glyph name='chevronDown' />
        </button>
        <ul mix={listboxListStyle} role='listbox' aria-label='Sample options'>
          <li mix={listboxOptionStyle} role='option' aria-selected='false'>
            <span mix={listboxGlyphStyle} />
            <span mix={listboxLabelStyle}>Option A</span>
          </li>
          <li mix={listboxOptionStyle} role='option' aria-selected='true'>
            <span mix={listboxGlyphStyle}>
              <Glyph name='check' />
            </span>
            <span mix={listboxLabelStyle}>Option B</span>
          </li>
          <li mix={listboxOptionStyle} role='option' aria-selected='false'>
            <span mix={listboxGlyphStyle} />
            <span mix={listboxLabelStyle}>Option C</span>
          </li>
        </ul>
      </Section>

      <Section title='Separator'>
        <hr mix={separatorStyle} />
        <div mix={separatorStyle} role='separator' aria-orientation='vertical' />
      </Section>
    </div>
  ),
)
