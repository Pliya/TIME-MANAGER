import { ref } from 'vue'

export const spinnerMessage = ref('')

export function showSpinner(msg = 'Synchronisation...') {
  if (window.SpinnerDialog) window.SpinnerDialog.show(null, msg, true)
  else spinnerMessage.value = msg
}

export function hideSpinner() {
  if (window.SpinnerDialog) window.SpinnerDialog.hide()
  spinnerMessage.value = ''
}