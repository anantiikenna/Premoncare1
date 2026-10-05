import '@testing-library/jest-dom'

// Polyfill Web API globals required by Next.js server modules
if (typeof globalThis.Request === 'undefined') {
  globalThis.Request = class Request {
    url: string
    init?: RequestInit
    constructor(url: string | URL, init?: RequestInit) {
      this.url = typeof url === 'string' ? url : url.toString()
      this.init = init
    }
  } as unknown as typeof Request
}
if (typeof globalThis.Response === 'undefined') {
  globalThis.Response = class Response {
    status = 200
    ok = true
    headers = new Headers()
    constructor(_body?: BodyInit | null, _init?: ResponseInit) {}
    json() { return Promise.resolve({}) }
    text() { return Promise.resolve('') }
  } as unknown as typeof Response
}
if (typeof globalThis.Headers === 'undefined') {
  globalThis.Headers = class Headers {
    _map = new Map<string, string>()
    constructor(_init?: HeadersInit) {}
    append(name: string, value: string) { this._map.set(name, value) }
    delete(name: string) { this._map.delete(name) }
    get(name: string) { return this._map.get(name) ?? null }
    has(name: string) { return this._map.has(name) }
    set(name: string, value: string) { this._map.set(name, value) }
    forEach(cb: (value: string, key: string) => void) { this._map.forEach(cb) }
  } as unknown as typeof Headers
}

// Mock next/server for jsdom environment.
// Must support the full surface used by src/proxy.ts + src/lib/supabase-middleware.ts:
// NextRequest cookie jar (get/getAll/set), NextResponse.next/redirect/json with
// mutable response cookies (incl. options) and init.status.
jest.mock('next/server', () => {
  const { Request: Req, Response: Resp } = globalThis

  const toHeaderEntries = (headers: unknown): Array<[string, string]> => {
    if (!headers) return []
    if (!Array.isArray(headers) && typeof (headers as { forEach?: unknown }).forEach === 'function') {
      const out: Array<[string, string]> = []
      ;(headers as { forEach: (cb: (value: string, key: string) => void) => void }).forEach((value, key) =>
        out.push([key, value])
      )
      return out
    }
    if (Array.isArray(headers)) return headers as Array<[string, string]>
    return Object.entries(headers as Record<string, string>)
  }

  const cookieHeaderFromInit = (init?: { headers?: unknown }): string | null => {
    for (const [key, value] of toHeaderEntries(init?.headers)) {
      if (key.toLowerCase() === 'cookie') return value
    }
    return null
  }

  class CookieJar {
    private jar = new Map<string, string>()
    private options = new Map<string, Record<string, unknown>>()

    constructor(header?: string | null) {
      if (!header) return
      for (const pair of header.split(';')) {
        const idx = pair.indexOf('=')
        if (idx > 0) this.jar.set(pair.slice(0, idx).trim(), pair.slice(idx + 1).trim())
      }
    }

    get(name: string) {
      const value = this.jar.get(name)
      return value === undefined ? undefined : { name, value }
    }

    getAll() {
      return Array.from(this.jar, ([name, value]) => ({ name, value }))
    }

    set(nameOrCookie: string | { name: string; value: string }, value?: string, options?: Record<string, unknown>) {
      const name = typeof nameOrCookie === 'string' ? nameOrCookie : nameOrCookie.name
      this.jar.set(name, typeof nameOrCookie === 'string' ? (value ?? '') : nameOrCookie.value)
      if (options) this.options.set(name, options)
    }

    getOptions(name: string): Record<string, unknown> | undefined {
      return this.options.get(name)
    }

    delete(name: string) {
      this.jar.delete(name)
    }
  }

  class NextRequest extends Req {
    nextUrl: URL
    private requestCookies: CookieJar

    constructor(input: string | URL | Request, init?: RequestInit) {
      super(input, init)
      this.nextUrl = new URL(this.url)
      let header: string | null = null
      try {
        header = (this as unknown as { headers?: { get(name: string): string | null } }).headers?.get('cookie') ?? null
      } catch {
        header = null // polyfill Request has no headers — fall back to init
      }
      this.requestCookies = new CookieJar(header ?? cookieHeaderFromInit(init as { headers?: unknown }))
    }

    get cookies() {
      return this.requestCookies
    }
    get geo() {
      return undefined
    }
    get ip() {
      return undefined
    }
  }

  class NextResponse extends Resp {
    cookies = new CookieJar(null)

    constructor(body?: BodyInit | null, init?: ResponseInit) {
      super(body, init)
      try {
        if (init?.status !== undefined) (this as { status: number }).status = init.status
        ;(this as { ok: boolean }).ok = this.status >= 200 && this.status < 300
      } catch {
        // native Response.status/ok are read-only getters — super() already applied init
      }
      if (init?.headers) {
        for (const [key, value] of toHeaderEntries(init.headers)) this.headers.set(key, value)
      }
    }

    static json(data: unknown, init?: ResponseInit) {
      return new NextResponse(JSON.stringify(data), {
        ...init,
        headers: { 'content-type': 'application/json', ...(init?.headers ?? {}) },
      })
    }
    static redirect(url: string | URL, status?: number) {
      const res = new NextResponse(null, { status: status ?? 307 })
      res.headers.set('location', String(url))
      return res
    }
    static rewrite(target: string | URL, init?: ResponseInit) {
      return new NextResponse(null, init)
    }
    static next(_init?: { request?: unknown }) {
      return new NextResponse(null, { status: 200 })
    }
  }

  return { NextRequest, NextResponse }
})

// Mock supabase-server
jest.mock('@/lib/supabase-server', () => ({
  createClient: jest.fn(),
}))
