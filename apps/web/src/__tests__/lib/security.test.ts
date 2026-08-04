import { sanitizeInput, sanitizeObject } from '@/lib/security'

describe('sanitizeInput', () => {
  it('returns empty string for null/undefined', () => {
    expect(sanitizeInput(null)).toBe('')
    expect(sanitizeInput(undefined)).toBe('')
  })

  it('trims whitespace', () => {
    expect(sanitizeInput('  hello  ')).toBe('hello')
  })

  it('removes script tags', () => {
    expect(sanitizeInput('<script>alert("xss")</script>')).toBe('alert("xss")')
  })

  it('removes HTML tags', () => {
    expect(sanitizeInput('<b>bold</b>')).toBe('bold')
  })

  it('preserves safe text', () => {
    expect(sanitizeInput('Hello World 123')).toBe('Hello World 123')
  })

  it('handles empty string', () => {
    expect(sanitizeInput('')).toBe('')
  })
})

describe('sanitizeObject', () => {
  it('sanitizes string values', () => {
    const input = { name: '<script>xss</script>John' }
    expect(sanitizeObject(input)).toEqual({ name: 'John' })
  })

  it('sanitizes nested objects', () => {
    const input = { user: { name: '<b>test</b>' } }
    expect(sanitizeObject(input)).toEqual({ user: { name: 'test' } })
  })

  it('preserves non-string values', () => {
    const input = { count: 42, active: true, tags: ['a', 'b'] }
    expect(sanitizeObject(input)).toEqual(input)
  })

  it('handles empty object', () => {
    expect(sanitizeObject({})).toEqual({})
  })
})
