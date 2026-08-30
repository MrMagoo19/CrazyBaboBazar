import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { CLICK_SESSION_STORAGE_KEY, clearClickSessionId, getOrCreateClickSessionId } from './click-session'
import { isConsentedSessionId } from './affiliate'

const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'

beforeEach(() => {
  window.sessionStorage.clear()
  window.localStorage.clear()
})

afterEach(() => {
  vi.unstubAllGlobals()
  window.sessionStorage.clear()
  window.localStorage.clear()
})

describe('getOrCreateClickSessionId', () => {
  it('legt beim ersten Aufruf eine UUID im sessionStorage an', () => {
    vi.stubGlobal('crypto', { randomUUID: () => SESSION_ID })

    const id = getOrCreateClickSessionId()

    expect(id).toBe(SESSION_ID)
    expect(isConsentedSessionId(id)).toBe(true)
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBe(SESSION_ID)
  })

  it('speichert nichts im localStorage und setzt kein Cookie', () => {
    vi.stubGlobal('crypto', { randomUUID: () => SESSION_ID })

    getOrCreateClickSessionId()

    expect(window.localStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
    expect(window.localStorage.length).toBe(0)
    expect(document.cookie).toBe('')
  })

  it('liefert bei wiederholtem Aufruf dieselbe Kennung', () => {
    let calls = 0
    vi.stubGlobal('crypto', {
      randomUUID: () => {
        calls += 1
        return SESSION_ID
      },
    })

    expect(getOrCreateClickSessionId()).toBe(SESSION_ID)
    expect(getOrCreateClickSessionId()).toBe(SESSION_ID)
    expect(calls).toBe(1)
  })

  it('verwirft einen fremden oder manipulierten Wert und legt einen neuen an', () => {
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, 'besucher-42')
    vi.stubGlobal('crypto', { randomUUID: () => SESSION_ID })

    expect(getOrCreateClickSessionId()).toBe(SESSION_ID)
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBe(SESSION_ID)
  })

  it('liefert ohne Web-Crypto null statt einer schwach zufaelligen Kennung', () => {
    vi.stubGlobal('crypto', {})

    expect(getOrCreateClickSessionId()).toBeNull()
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('liefert null, wenn die Kennung nicht die UUID-Form haette', () => {
    vi.stubGlobal('crypto', { randomUUID: () => 'nicht-uuid' })

    expect(getOrCreateClickSessionId()).toBeNull()
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })
})

describe('clearClickSessionId', () => {
  it('entfernt eine bestehende Kennung — Voraussetzung fuer einen sauberen Widerruf', () => {
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, SESSION_ID)

    clearClickSessionId()

    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('bleibt ohne bestehende Kennung wirkungslos statt zu werfen', () => {
    expect(() => clearClickSessionId()).not.toThrow()
  })
})
