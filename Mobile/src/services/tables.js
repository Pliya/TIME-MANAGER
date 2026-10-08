// Sur mobile, les tableaux des vues web s'affichent en cartes (voir assets/main.css).
// Pour que chaque valeur garde son intitulé, on recopie le titre de la colonne
// (<th>) dans un attribut data-label sur chaque cellule (<td>).
function labelTables(root) {
  root.querySelectorAll('table').forEach((table) => {
    const heads = Array.from(table.querySelectorAll('thead th')).map((th) => th.textContent.trim())
    if (!heads.length) return
    table.querySelectorAll('tbody tr').forEach((tr) => {
      Array.from(tr.children).forEach((td, i) => {
        if (heads[i] && td.getAttribute('data-label') !== heads[i]) td.setAttribute('data-label', heads[i])
      })
    })
  })
}

// Les vues chargent leurs données après coup : on réétiquette à chaque changement du DOM
export function startTableLabels(root) {
  labelTables(root)
  new MutationObserver(() => labelTables(root)).observe(root, { childList: true, subtree: true })
}