import { Badge, badgeVariants } from '@/components/ui/badge'

describe('Badge', () => {
  it('returns default variant classes', () => {
    const classes = badgeVariants({ variant: 'default' })
    expect(classes).toContain('bg-primary')
  })

  it('returns secondary variant classes', () => {
    const classes = badgeVariants({ variant: 'secondary' })
    expect(classes).toContain('bg-secondary')
  })

  it('returns destructive variant classes', () => {
    const classes = badgeVariants({ variant: 'destructive' })
    expect(classes).toContain('bg-destructive')
  })

  it('returns outline variant classes', () => {
    const classes = badgeVariants({ variant: 'outline' })
    expect(classes).toContain('text-foreground')
  })

  it('accepts custom className', () => {
    const classes = badgeVariants({ className: 'custom-class' })
    expect(classes).toContain('custom-class')
  })

  it('exports Badge component', () => {
    expect(typeof Badge).toBe('function')
  })
})
