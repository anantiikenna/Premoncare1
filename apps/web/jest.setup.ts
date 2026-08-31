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

// Mock next/server for jsdom environment
jest.mock('next/server', () => {
  const { Request: Req, Response: Resp, Headers: H } = globalThis
  return {
    NextRequest: class NextRequest extends Req {
      nextUrl = new URL(this.url)
      get cookies() { return { get: () => undefined, getAll: () => [], set: () => {}, delete: () => {} } }
      get geo() { return undefined }
      get ip() { return undefined }
    },
    NextResponse: Object.assign(
      class NextResponse extends Resp {
        static json(data: unknown, init?: ResponseInit) {
          return new Resp(JSON.stringify(data), {
            ...init,
            headers: { 'content-type': 'application/json', ...(init?.headers ?? {}) },
          })
        }
        static redirect(url: string | URL, status?: number) {
          return new Resp(null, { status: status ?? 307, headers: { location: String(url) } })
        }
        static rewrite(target: string | URL, init?: ResponseInit) {
          return new Resp(null, init)
        }
      },
      { nextUrl: { clone: () => new URL('http://localhost') } }
    ),
  }
})

// Mock supabase-server
jest.mock('@/lib/supabase-server', () => ({
  createClient: jest.fn(),
}))
