export function confirmDialog(message, title = 'Confirmation') {
  return new Promise((resolve) => {
    if (navigator.notification?.confirm) {
      navigator.notification.confirm(message, (i) => resolve(i === 1), title, ['Oui', 'Annuler'])
    } else {
      resolve(window.confirm(message))
    }
  })
}