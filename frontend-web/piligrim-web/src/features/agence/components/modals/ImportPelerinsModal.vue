<template>
  <DashboardModalShell title="Importer des pelerins" :error="error" @close="$emit('close')">
    <div class="import-modal">
      <div class="form-field">
        <div class="import-header-row">
          <label>Fichier Excel ou CSV</label>
          <button type="button" class="template-download-btn" @click="downloadTemplate">
            Telecharger le modele
          </button>
        </div>
        <input
          ref="fileInput"
          type="file"
          accept=".xlsx,.xls,.csv"
          class="file-input"
          @change="handleFileChange"
        />
        <p class="import-hint">
          Colonnes attendues :
          <code>prenom</code>,
          <code>nom</code>,
          <code>email</code>,
          <code>telephone</code>,
          <code>dateNaissance</code>,
          <code>numeroPasseport</code>,
          <code>nationalite</code>
        </p>
      </div>

      <div v-if="parseError" class="import-error">{{ parseError }}</div>

      <div v-if="parsedRows.length > 0" class="import-summary">
        <strong>{{ parsedRows.length }}</strong> ligne(s) prete(s) a importer
      </div>

      <div v-if="parsedRows.length > 0" class="preview-wrap">
        <table class="preview-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Prenom</th>
              <th>Nom</th>
              <th>Email</th>
              <th>Telephone</th>
              <th>Passeport</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, index) in previewRows" :key="`${row.email}-${index}`">
              <td>{{ index + 1 }}</td>
              <td>{{ row.prenom || '-' }}</td>
              <td>{{ row.nom || '-' }}</td>
              <td>{{ row.email || '-' }}</td>
              <td>{{ row.telephone || '-' }}</td>
              <td>{{ row.numeroPasseport || '-' }}</td>
            </tr>
          </tbody>
        </table>
        <p v-if="parsedRows.length > previewRows.length" class="import-hint">
          Apercu limite aux {{ previewRows.length }} premieres lignes.
        </p>
      </div>

      <div v-if="importErrors.length > 0" class="import-errors-card">
        <p class="import-errors-title">Erreurs detectees</p>
        <ul class="import-errors-list">
          <li v-for="(item, index) in importErrors" :key="`${item}-${index}`">{{ item }}</li>
        </ul>
      </div>
    </div>

    <template #actions>
      <button class="btn-secondary" @click="$emit('close')">Annuler</button>
      <button class="btn-primary" :disabled="loading || parsedRows.length === 0" @click="$emit('submit', parsedRows)">
        {{ loading ? 'Import...' : 'Confirmer l import' }}
      </button>
    </template>
  </DashboardModalShell>
</template>

<script setup>
import { computed, ref } from 'vue'
import * as XLSX from 'xlsx'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'

const props = defineProps({
  error: { type: String, default: '' },
  loading: { type: Boolean, default: false },
  importErrors: {
    type: Array,
    default: () => [],
  },
})

defineEmits(['close', 'submit'])

const fileInput = ref(null)
const parsedRows = ref([])
const parseError = ref('')

const previewRows = computed(() => parsedRows.value.slice(0, 8))

const TEMPLATE_ROWS = [
  {
    prenom: 'Ahmed',
    nom: 'Ben Ali',
    email: 'ahmed.benali@example.com',
    telephone: '+21620123456',
    dateNaissance: '1982-05-14',
    numeroPasseport: 'XK123456',
    nationalite: 'Tunisie',
  },
  {
    prenom: 'Fatma',
    nom: 'Trabelsi',
    email: 'fatma.trabelsi@example.com',
    telephone: '+21622123456',
    dateNaissance: '1978-11-03',
    numeroPasseport: 'TR987654',
    nationalite: 'Tunisie',
  },
]

const HEADER_ALIASES = {
  prenom: 'prenom',
  first_name: 'prenom',
  firstname: 'prenom',
  nom: 'nom',
  last_name: 'nom',
  lastname: 'nom',
  email: 'email',
  mail: 'email',
  telephone: 'telephone',
  phone: 'telephone',
  telephone1: 'telephone',
  datenaissance: 'dateNaissance',
  date_de_naissance: 'dateNaissance',
  date_naissance: 'dateNaissance',
  dateofbirth: 'dateNaissance',
  numeropasseport: 'numeroPasseport',
  no_passeport: 'numeroPasseport',
  passeport: 'numeroPasseport',
  passport: 'numeroPasseport',
  nationalite: 'nationalite',
  nationality: 'nationalite',
}

function normalizeHeader(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .toLowerCase()
}

function mapRow(raw) {
  const mapped = {
    prenom: '',
    nom: '',
    email: '',
    telephone: '',
    dateNaissance: '',
    numeroPasseport: '',
    nationalite: '',
  }

  Object.entries(raw ?? {}).forEach(([key, value]) => {
    const normalizedKey = normalizeHeader(key)
    const targetKey = HEADER_ALIASES[normalizedKey]
    if (!targetKey) return
    mapped[targetKey] = String(value ?? '').trim()
  })

  return mapped
}

function downloadTemplate() {
  const worksheet = XLSX.utils.json_to_sheet(TEMPLATE_ROWS, {
    header: [
      'prenom',
      'nom',
      'email',
      'telephone',
      'dateNaissance',
      'numeroPasseport',
      'nationalite',
    ],
  })

  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Pelerins')
  XLSX.writeFile(workbook, 'modele-import-pelerins.xlsx')
}

async function handleFileChange(event) {
  parseError.value = ''
  parsedRows.value = []

  const file = event.target.files?.[0]
  if (!file) return

  try {
    const buffer = await file.arrayBuffer()
    const workbook = XLSX.read(buffer, { type: 'array' })
    const firstSheetName = workbook.SheetNames[0]

    if (!firstSheetName) {
      parseError.value = 'Le fichier ne contient aucune feuille exploitable.'
      return
    }

    const worksheet = workbook.Sheets[firstSheetName]
    const rows = XLSX.utils.sheet_to_json(worksheet, { defval: '' })
    const normalizedRows = rows
      .map(mapRow)
      .filter((row) => Object.values(row).some((value) => value))

    if (normalizedRows.length === 0) {
      parseError.value = 'Aucune ligne exploitable n a ete trouvee dans le fichier.'
      return
    }

    parsedRows.value = normalizedRows
  } catch (error) {
    parseError.value = 'Impossible de lire ce fichier. Verifiez le format Excel ou CSV.'
  } finally {
    if (fileInput.value) {
      fileInput.value.value = ''
    }
  }
}
</script>

<style scoped>
.import-modal {
  display: grid;
  gap: 14px;
}

.file-input {
  width: 100%;
}

.import-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 8px;
}

.template-download-btn {
  border: 1px solid rgba(201, 168, 76, 0.24);
  background: rgba(201, 168, 76, 0.08);
  color: #f3e3b2;
  padding: 7px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.18s ease, border-color 0.18s ease;
}

.template-download-btn:hover {
  background: rgba(201, 168, 76, 0.14);
  border-color: rgba(201, 168, 76, 0.35);
}

.import-hint {
  margin-top: 8px;
  font-size: 12.5px;
  color: rgba(246, 238, 223, 0.66);
  line-height: 1.5;
}

.import-hint code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 12px;
  color: rgba(255, 245, 224, 0.92);
}

.import-summary {
  padding: 10px 12px;
  border-radius: 14px;
  border: 1px solid rgba(201, 168, 76, 0.22);
  background: rgba(201, 168, 76, 0.08);
}

.import-error {
  padding: 10px 12px;
  border-radius: 14px;
  background: rgba(255, 138, 101, 0.12);
  border: 1px solid rgba(255, 138, 101, 0.28);
  color: #ffb8a3;
  font-size: 13px;
}

.preview-wrap {
  overflow: auto;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
}

.preview-table {
  width: 100%;
  border-collapse: collapse;
}

.preview-table th,
.preview-table td {
  padding: 10px 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  text-align: left;
  font-size: 13px;
}

.preview-table th {
  background: rgba(255, 255, 255, 0.03);
  font-weight: 700;
}

.import-errors-card {
  padding: 14px;
  border-radius: 16px;
  background: rgba(255, 138, 101, 0.08);
  border: 1px solid rgba(255, 138, 101, 0.2);
}

.import-errors-title {
  font-weight: 700;
  margin-bottom: 8px;
}

.import-errors-list {
  margin: 0;
  padding-left: 18px;
  display: grid;
  gap: 6px;
  font-size: 13px;
  color: rgba(255, 232, 224, 0.9);
}
</style>
