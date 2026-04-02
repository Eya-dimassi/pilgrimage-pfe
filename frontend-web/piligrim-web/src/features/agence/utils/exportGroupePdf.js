function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
}

function formatDate(value) {
  if (!value) return ''
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: '2-digit' })
}

function statusLabel(status) {
  if (status === 'EN_COURS') return 'En cours'
  if (status === 'TERMINE') return 'Termine'
  if (status === 'ANNULE') return 'Annule'
  return 'Planifie'
}

function buildHtml({ groupe, agencyName, exportedAt }) {
  const groupeName = escapeHtml(groupe?.nom ?? 'Groupe')
  const typeVoyage = escapeHtml(groupe?.typeVoyage ?? '-')
  const status = escapeHtml(statusLabel(groupe?.status))
  const annee = escapeHtml(groupe?.annee ?? '-')
  const description = escapeHtml(groupe?.description ?? '')
  const dateDepart = formatDate(groupe?.dateDepart)
  const dateRetour = formatDate(groupe?.dateRetour)

  const guides = Array.isArray(groupe?.guides) ? groupe.guides : []
  const pelerins = Array.isArray(groupe?.pelerins) ? groupe.pelerins : []

  const guidesHtml =
    guides.length === 0
      ? '<div class="muted">Aucun guide assigne.</div>'
      : `<ul class="list">
          ${guides
            .map((guide) => {
              const prenom = guide?.utilisateur?.prenom ?? ''
              const nom = guide?.utilisateur?.nom ?? ''
              const email = guide?.utilisateur?.email ?? ''
              const fullName = escapeHtml(`${prenom} ${nom}`.trim() || 'Guide')
              const emailHtml = email ? `<div class="sub">${escapeHtml(email)}</div>` : ''
              return `<li><div class="name">${fullName}</div>${emailHtml}</li>`
            })
            .join('')}
        </ul>`

  const pelerinsRowsHtml =
    pelerins.length === 0
      ? '<div class="muted">Aucun pelerin dans ce groupe.</div>'
      : `<table class="table">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Email</th>
              <th>Telephone</th>
            </tr>
          </thead>
          <tbody>
            ${pelerins
              .map((pelerin) => {
                const prenom = pelerin?.utilisateur?.prenom ?? ''
                const nom = pelerin?.utilisateur?.nom ?? ''
                const email = pelerin?.utilisateur?.email ?? ''
                const telephone = pelerin?.utilisateur?.telephone ?? pelerin?.telephone ?? '-'
                return `<tr>
                    <td>${escapeHtml(`${prenom} ${nom}`.trim())}</td>
                    <td>${escapeHtml(email)}</td>
                    <td>${escapeHtml(telephone || '-')}</td>
                  </tr>`
              })
              .join('')}
          </tbody>
        </table>`

  const subtitleParts = [
    agencyName ? escapeHtml(agencyName) : '',
    exportedAt ? escapeHtml(exportedAt) : '',
  ].filter(Boolean)

  const subtitle = subtitleParts.join(' · ')

  const dateLineParts = [
    `Annee: ${annee}`,
    dateDepart ? `Depart: ${escapeHtml(dateDepart)}` : '',
    dateRetour ? `Retour: ${escapeHtml(dateRetour)}` : '',
  ].filter(Boolean)

  const dateLine = dateLineParts.join(' · ')

  return `<!doctype html>
  <html lang="fr">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <title>${groupeName} - Export PDF</title>
      <style>
        :root { color-scheme: light; }
        @page { size: A4; margin: 16mm; }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial, 'Noto Sans', 'Liberation Sans', sans-serif; color: #111; }
        .wrap { max-width: 820px; margin: 0 auto; }
        .header { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; border-bottom: 2px solid #eee; padding-bottom: 14px; margin-bottom: 16px; }
        .title { font-size: 22px; font-weight: 800; margin: 0; }
        .subtitle { margin-top: 6px; color: #555; font-size: 12px; }
        .badge-row { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 10px; }
        .badge { display: inline-flex; align-items: center; border: 1px solid #ddd; border-radius: 999px; padding: 4px 10px; font-size: 11px; font-weight: 700; color: #333; background: #fafafa; }
        .badge--gold { border-color: rgba(201, 168, 76, 0.6); color: #7a5a12; background: rgba(201, 168, 76, 0.12); }
        .badge--blue { border-color: rgba(74, 158, 255, 0.5); color: #0b4f9a; background: rgba(74, 158, 255, 0.12); }
        .badge--gray { border-color: #d5d5d5; color: #444; background: #f6f6f6; }
        .section { margin-top: 16px; }
        .section-title { font-size: 12px; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; color: #444; margin: 0 0 8px; }
        .meta { color: #555; font-size: 12px; line-height: 1.45; }
        .muted { color: #666; font-size: 12px; }
        .list { margin: 0; padding-left: 18px; }
        .list li { margin: 0 0 6px; }
        .name { font-weight: 700; font-size: 13px; color: #111; }
        .sub { color: #555; font-size: 12px; margin-top: 2px; }
        .table { width: 100%; border-collapse: collapse; border: 1px solid #e5e5e5; border-radius: 10px; overflow: hidden; }
        .table th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: 0.06em; background: #fafafa; color: #444; padding: 10px; border-bottom: 1px solid #eaeaea; }
        .table td { font-size: 12px; padding: 10px; border-bottom: 1px solid #f0f0f0; vertical-align: top; }
        .table tr:last-child td { border-bottom: none; }
        .footer { margin-top: 18px; border-top: 1px solid #eee; padding-top: 10px; color: #777; font-size: 11px; }
        @media print {
          a[href]:after { content: ""; }
          .no-print { display: none !important; }
        }
      </style>
    </head>
    <body>
      <div class="wrap">
        <div class="header">
          <div>
            <h1 class="title">${groupeName}</h1>
            ${subtitle ? `<div class="subtitle">${subtitle}</div>` : ''}
            <div class="badge-row">
              <span class="badge badge--gold">${typeVoyage}</span>
              <span class="badge badge--gray">${status}</span>
            </div>
          </div>
          <div class="meta" style="text-align:right;">
            ${dateLine ? `<div>${dateLine}</div>` : ''}
            <div>Pelerins: <strong>${pelerins.length}</strong></div>
            <div>Guides: <strong>${guides.length}</strong></div>
          </div>
        </div>

        <div class="section">
          <div class="section-title">Description</div>
          <div class="meta">${description || '<span class="muted">Pas de description.</span>'}</div>
        </div>

        <div class="section">
          <div class="section-title">Guides</div>
          ${guidesHtml}
        </div>

        <div class="section">
          <div class="section-title">Pelerins</div>
          ${pelerinsRowsHtml}
        </div>

        <div class="footer">
          Export genere depuis l'espace agence.
        </div>

        <div class="no-print" style="margin-top: 14px; display:flex; gap: 10px;">
          <button onclick="window.print()" style="padding:10px 14px; border:1px solid #ddd; border-radius:10px; background:#111; color:#fff; cursor:pointer; font-weight:700;">
            Imprimer / Enregistrer en PDF
          </button>
          <button onclick="window.close()" style="padding:10px 14px; border:1px solid #ddd; border-radius:10px; background:#fff; color:#111; cursor:pointer; font-weight:700;">
            Fermer
          </button>
        </div>
      </div>

      <script>
        window.addEventListener('load', () => {
          setTimeout(() => { window.print(); }, 350);
        });
      </script>
    </body>
  </html>`
}

export function exportGroupePdf(groupe, options = {}) {
  const exportedAt = new Date().toLocaleString('fr-FR')
  let fallbackAgencyName = ''
  try {
    const raw = JSON.parse(localStorage.getItem('user') || '{}')
    fallbackAgencyName = raw?.nomAgence || raw?.agence?.nom || raw?.nom || ''
  } catch {
    fallbackAgencyName = ''
  }
  const html = buildHtml({
    groupe,
    agencyName: options.agencyName ?? fallbackAgencyName,
    exportedAt,
  })

  const blob = new Blob([html], { type: 'text/html;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const win = window.open(url, '_blank', 'noopener,noreferrer')

  if (!win) {
    URL.revokeObjectURL(url)
    throw new Error("Popup bloque. Autorisez les popups pour exporter en PDF.")
  }

  win.addEventListener('beforeunload', () => URL.revokeObjectURL(url), { once: true })
}
