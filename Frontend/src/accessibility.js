import { reactive, watch } from 'vue'

const STORAGE_KEY = 'accessibility'

function load() {
  try {
    return { contrast: false, largeText: false, voice: false, ...JSON.parse(localStorage.getItem(STORAGE_KEY)) }
  } catch {
    return { contrast: false, largeText: false, voice: false }
  }
}

export const accessibility = reactive(load())

export function speak(text) {
  if (!('speechSynthesis' in window) || !text) return
  window.speechSynthesis.cancel()
  const utterance = new SpeechSynthesisUtterance(text)
  utterance.lang = 'fr-FR'
  window.speechSynthesis.speak(utterance)
}

function textOf(el) {
  const label = el.closest('label')?.innerText
  return el.getAttribute('aria-label') || el.placeholder || label || el.innerText
}

function readFocused(event) {
  if (accessibility.voice) speak(textOf(event.target))
}

function apply() {
  document.documentElement.classList.toggle('high-contrast', accessibility.contrast)
  document.documentElement.classList.toggle('large-text', accessibility.largeText)
  localStorage.setItem(STORAGE_KEY, JSON.stringify(accessibility))
}

export function setupAccessibility() {
  apply()
  watch(accessibility, apply)
  document.addEventListener('focusin', readFocused)
}
