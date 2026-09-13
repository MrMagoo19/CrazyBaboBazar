import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  SWIPE_SESSION_STORAGE_KEY,
  clearSwipeSessionId,
  getOrCreateSwipeSessionId,
  getStoredSwipeSessionId,
  removeLegacySwipeSessionId,
} from './swipe-session'

const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'

beforeEach(() => {
  localStorage.clear()
  sessionStorage.clear()
  vi.spyOn(globalThis.crypto, 'randomUUID').mockReturnValue(SESSION_ID)
})

describe('swipe-session', () => {
  it('legt beim reinen Lesen keine Kennung an', () => {
    expect(getStoredSwipeSessionId()).toBeNull()
    expect(sessionStorage.length).toBe(0)
    expect(localStorage.length).toBe(0)
  })

  it('legt die Kennung erst beim aktiven Aufruf im sessionStorage an', () => {
    expect(getOrCreateSwipeSessionId()).toBe(SESSION_ID)
    expect(sessionStorage.getItem(SWIPE_SESSION_STORAGE_KEY)).toBe(SESSION_ID)
    expect(localStorage.length).toBe(0)
  })

  it('entfernt auch die alte dauerhafte localStorage-Kennung', () => {
    localStorage.setItem('cbb-swipe-session', SESSION_ID)
    removeLegacySwipeSessionId()
    expect(localStorage.getItem('cbb-swipe-session')).toBeNull()
  })

  it('räumt neue und alte Kennungen beim Widerruf ab', () => {
    sessionStorage.setItem(SWIPE_SESSION_STORAGE_KEY, SESSION_ID)
    localStorage.setItem('cbb-swipe-session', SESSION_ID)
    clearSwipeSessionId()
    expect(sessionStorage.getItem(SWIPE_SESSION_STORAGE_KEY)).toBeNull()
    expect(localStorage.getItem('cbb-swipe-session')).toBeNull()
  })
})
