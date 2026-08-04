import { render, screen } from '@testing-library/react'
import { Badge } from '@/components/ui/badge'

describe('Badge', () => {
  it('renders children text', () => {
    render(<Badge>Test Badge</Badge>)
    expect(screen.getByText('Test Badge')).toBeInTheDocument()
  })

  it('applies default variant class', () => {
    render(<Badge data-testid="badge">Default</Badge>)
    const badge = screen.getByTestId('badge')
    expect(badge.className).toContain('bg-primary')
  })

  it('applies secondary variant class', () => {
    render(<Badge variant="secondary" data-testid="badge">Secondary</Badge>)
    const badge = screen.getByTestId('badge')
    expect(badge.className).toContain('bg-secondary')
  })

  it('applies destructive variant class', () => {
    render(<Badge variant="destructive" data-testid="badge">Destructive</Badge>)
    const badge = screen.getByTestId('badge')
    expect(badge.className).toContain('bg-destructive')
  })

  it('applies outline variant class', () => {
    render(<Badge variant="outline" data-testid="badge">Outline</Badge>)
    const badge = screen.getByTestId('badge')
    expect(badge.className).toContain('text-foreground')
  })

  it('accepts custom className', () => {
    render(<Badge className="custom-class" data-testid="badge">Custom</Badge>)
    const badge = screen.getByTestId('badge')
    expect(badge.className).toContain('custom-class')
  })
})
