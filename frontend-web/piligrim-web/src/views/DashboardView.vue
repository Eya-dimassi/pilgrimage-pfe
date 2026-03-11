<template>
  <div class="dashboard" :class="{ dark: isDark }">
    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-logo">
        <span class="logo-icon">🕌</span>
        <div>
          <div class="logo-name">SmartHajj</div>
          <div class="logo-sub">Espace Agence</div>
        </div>
      </div>

      <nav class="sidebar-nav">
        <div class="nav-section-label">Navigation</div>
        <a v-for="item in navItems" :key="item.view"
          @click.prevent="currentView = item.view"
          :class="['nav-item', { active: currentView === item.view }]">
          <span class="nav-icon" v-html="item.icon"></span>
          <span>{{ item.label }}</span>
          <span v-if="item.badge && getBadge(item.badge) > 0" class="nav-badge">{{ getBadge(item.badge) }}</span>
        </a>
      </nav>

      <div class="sidebar-footer">
        <div class="user-card">
          <div class="user-avatar">{{ userInitials }}</div>
          <div class="user-info">
            <div class="user-name">{{ user?.prenom }} {{ user?.nom }}</div>
            <div class="user-role">Agence</div>
          </div>
        </div>
        <button @click="handleLogout" class="logout-btn" title="Déconnecter">
          <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
          </svg>
        </button>
      </div>
    </aside>

    <!-- Main -->
    <div class="main-area">
      <!-- Topbar -->
      <header class="topbar">
        <div class="topbar-left">
          <div class="breadcrumb">
            <span class="breadcrumb-root">Agence</span>
            <span class="breadcrumb-sep">›</span>
            <span class="breadcrumb-current">{{ viewTitle }}</span>
          </div>
        </div>
        <div class="topbar-right">
          <button @click="loadAll" class="topbar-btn" title="Actualiser">
            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
            </svg>
          </button>
          <button @click="isDark = !isDark" class="topbar-btn">
            <svg v-if="isDark" width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364-6.364l-.707.707M6.343 17.657l-.707.707M17.657 17.657l-.707-.707M6.343 6.343l-.707-.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
            </svg>
            <svg v-else width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
            </svg>
          </button>
        </div>
      </header>

      <div class="content">
        <!-- Loading -->
        <div v-if="loading" class="state-center">
          <div class="spinner"></div>
          <p>Chargement...</p>
        </div>

        <!-- Error -->
        <div v-else-if="fetchError" class="state-center">
          <p class="error-text">{{ fetchError }}</p>
          <button @click="loadAll" class="btn-primary">Réessayer</button>
        </div>

        <template v-else>
          <!-- ── DASHBOARD ─────────────────────────────────────── -->
          <div v-if="currentView === 'dashboard'" class="view-dashboard">
            <div class="stats-grid">
              <div class="stat-card gold">
                <div class="stat-icon">🕌</div>
                <div class="stat-body">
                  <div class="stat-value">{{ groupes.length }}</div>
                  <div class="stat-label">Groupes</div>
                </div>
                <div class="stat-sub">{{ groupes.filter(g=>g.typeVoyage==='HAJJ').length }} Hajj · {{ groupes.filter(g=>g.typeVoyage==='UMRAH').length }} Umrah</div>
              </div>
              <div class="stat-card blue">
                <div class="stat-icon">🧎</div>
                <div class="stat-body">
                  <div class="stat-value">{{ pelerins.length }}</div>
                  <div class="stat-label">Pèlerins</div>
                </div>
                <div class="stat-sub">{{ pelerins.filter(p=>p.utilisateur?.actif).length }} actifs</div>
              </div>
              <div class="stat-card green">
                <div class="stat-icon">🧭</div>
                <div class="stat-body">
                  <div class="stat-value">{{ guides.length }}</div>
                  <div class="stat-label">Guides</div>
                </div>
                <div class="stat-sub">{{ guides.filter(g=>g.utilisateur?.actif).length }} actifs</div>
              </div>
              <div class="stat-card orange">
                <div class="stat-icon">⏳</div>
                <div class="stat-body">
                  <div class="stat-value">{{ pelerins.filter(p=>!p.utilisateur?.actif).length }}</div>
                  <div class="stat-label">En attente</div>
                </div>
                <div class="stat-sub">Activation email</div>
              </div>
            </div>

            <!-- Recent tables -->
            <div class="recent-grid">
              <div class="card">
                <div class="card-header">
                  <h3>Derniers Pèlerins</h3>
                  <button @click="currentView='pelerins'" class="card-link">Voir tout →</button>
                </div>
                <div class="mini-table">
                  <div v-if="pelerins.length === 0" class="empty-row">Aucun pèlerin</div>
                  <div v-for="p in pelerins.slice(0,5)" :key="p.id" class="mini-row">
                    <div class="mini-avatar">{{ initials(p.utilisateur?.prenom, p.utilisateur?.nom) }}</div>
                    <div class="mini-info">
                      <div class="mini-name">{{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}</div>
                      <div class="mini-sub">{{ p.groupe?.nom || 'Sans groupe' }}</div>
                    </div>
                    <span :class="['status-pill', p.utilisateur?.actif ? 'active' : 'pending']">
                      {{ p.utilisateur?.actif ? 'Actif' : 'En attente' }}
                    </span>
                  </div>
                </div>
              </div>

              <div class="card">
                <div class="card-header">
                  <h3>Groupes</h3>
                  <button @click="currentView='groupes'" class="card-link">Voir tout →</button>
                </div>
                <div class="mini-table">
                  <div v-if="groupes.length === 0" class="empty-row">Aucun groupe</div>
                  <div v-for="g in groupes.slice(0,5)" :key="g.id" class="mini-row">
                    <div class="mini-avatar gold-av">{{ g.typeVoyage === 'HAJJ' ? '🕌' : '🌙' }}</div>
                    <div class="mini-info">
                      <div class="mini-name">{{ g.nom }}</div>
                      <div class="mini-sub">{{ g.annee }} · {{ g._count?.pelerins ?? 0 }} pèlerins</div>
                    </div>
                    <span class="type-pill">{{ g.typeVoyage }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- ── PÈLERINS ───────────────────────────────────────── -->
          <div v-if="currentView === 'pelerins'" class="view-section">
            <div class="section-topbar">
              <input v-model="searchP" class="search-input" placeholder="Rechercher un pèlerin..." />
              <button @click="openModal('createPelerin')" class="btn-primary">+ Nouveau pèlerin</button>
            </div>

            <div class="card">
              <div v-if="filteredPelerins.length === 0" class="empty-state">Aucun pèlerin trouvé</div>
              <table v-else class="data-table">
                <thead>
                  <tr>
                    <th>Pèlerin</th>
                    <th>Contact</th>
                    <th>Passeport</th>
                    <th>Groupe</th>
                    <th>Statut</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="p in filteredPelerins" :key="p.id">
                    <td>
                      <div class="cell-user">
                        <div class="cell-avatar">{{ initials(p.utilisateur?.prenom, p.utilisateur?.nom) }}</div>
                        <div>
                          <div class="cell-name">{{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}</div>
                          <div class="cell-sub">{{ p.nationalite || '—' }}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="cell-name">{{ p.utilisateur?.email }}</div>
                      <div class="cell-sub">{{ p.utilisateur?.telephone || '—' }}</div>
                    </td>
                    <td class="cell-sub">{{ p.numeroPasseport || '—' }}</td>
                    <td>
                      <span v-if="p.groupe" class="group-tag">{{ p.groupe.nom }}</span>
                      <span v-else class="cell-sub">—</span>
                    </td>
                    <td>
                      <span :class="['status-pill', p.utilisateur?.actif ? 'active' : 'pending']">
                        {{ p.utilisateur?.actif ? 'Actif' : 'En attente' }}
                      </span>
                    </td>
                    <td>
                      <div class="action-btns">
                        <button @click="openEdit('pelerin', p)" class="act-btn edit" title="Modifier">✏️</button>
                        <button @click="confirmDelete('pelerin', p)" class="act-btn del" title="Supprimer">🗑</button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- ── GUIDES ─────────────────────────────────────────── -->
          <div v-if="currentView === 'guides'" class="view-section">
            <div class="section-topbar">
              <input v-model="searchG" class="search-input" placeholder="Rechercher un guide..." />
              <button @click="openModal('createGuide')" class="btn-primary">+ Nouveau guide</button>
            </div>
            <div class="card">
              <div v-if="filteredGuides.length === 0" class="empty-state">Aucun guide trouvé</div>
              <table v-else class="data-table">
                <thead>
                  <tr>
                    <th>Guide</th>
                    <th>Contact</th>
                    <th>Spécialité</th>
                    <th>Groupes</th>
                    <th>Statut</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="g in filteredGuides" :key="g.id">
                    <td>
                      <div class="cell-user">
                        <div class="cell-avatar green-av">{{ initials(g.utilisateur?.prenom, g.utilisateur?.nom) }}</div>
                        <div>
                          <div class="cell-name">{{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="cell-name">{{ g.utilisateur?.email }}</div>
                      <div class="cell-sub">{{ g.utilisateur?.telephone || '—' }}</div>
                    </td>
                    <td class="cell-sub">{{ g.specialite || '—' }}</td>
                    <td class="cell-sub">{{ g.groupes?.length ?? 0 }} groupe(s)</td>
                    <td>
                      <span :class="['status-pill', g.utilisateur?.actif ? 'active' : 'pending']">
                        {{ g.utilisateur?.actif ? 'Actif' : 'En attente' }}
                      </span>
                    </td>
                    <td>
                      <div class="action-btns">
                        <button @click="openEdit('guide', g)" class="act-btn edit" title="Modifier">✏️</button>
                        <button @click="confirmDelete('guide', g)" class="act-btn del" title="Supprimer">🗑</button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- ── GROUPES ────────────────────────────────────────── -->
          <div v-if="currentView === 'groupes'" class="view-section">
            <div class="section-topbar">
              <input v-model="searchGr" class="search-input" placeholder="Rechercher un groupe..." />
              <button @click="openModal('createGroupe')" class="btn-primary">+ Nouveau groupe</button>
            </div>
            <div class="groups-grid">
              <div v-if="filteredGroupes.length === 0" class="empty-state">Aucun groupe trouvé</div>
              <div v-for="gr in filteredGroupes" :key="gr.id" class="group-card">
                <div class="group-card-header">
                  <div class="group-type-badge" :class="gr.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
                    {{ gr.typeVoyage }}
                  </div>
                  <div class="group-actions">
                    <button @click="openEdit('groupe', gr)" class="act-btn edit">✏️</button>
                    <button @click="confirmDelete('groupe', gr)" class="act-btn del">🗑</button>
                  </div>
                </div>
                <div class="group-name">{{ gr.nom }}</div>
                <div class="group-meta">{{ gr.annee }} · {{ gr.description || 'Pas de description' }}</div>
                <div class="group-stats">
                  <div class="group-stat">
                    <span class="gs-val">{{ gr._count?.pelerins ?? 0 }}</span>
                    <span class="gs-lbl">Pèlerins</span>
                  </div>
                  <div class="group-stat">
                    <span class="gs-val">{{ gr.guide ? '✓' : '—' }}</span>
                    <span class="gs-lbl">Guide</span>
                  </div>
                </div>
                <div v-if="gr.guide" class="group-guide">
                  🧭 {{ gr.guide.utilisateur?.prenom }} {{ gr.guide.utilisateur?.nom }}
                </div>
                <button @click="openAssign(gr)" class="btn-assign">+ Affecter pèlerin</button>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- ── MODALS ──────────────────────────────────────────────── -->

    <!-- Create Pèlerin -->
    <div v-if="modal === 'createPelerin'" class="modal-overlay" @click.self="modal = null">
      <div class="modal">
        <h3 class="modal-title">Nouveau Pèlerin</h3>
        <div class="form-grid">
          <div class="form-field"><label>Prénom *</label><input v-model="form.prenom" placeholder="Prénom" /></div>
          <div class="form-field"><label>Nom *</label><input v-model="form.nom" placeholder="Nom" /></div>
          <div class="form-field"><label>Email *</label><input v-model="form.email" type="email" placeholder="email@exemple.com" /></div>
          <div class="form-field"><label>Téléphone</label><input v-model="form.telephone" placeholder="+213..." /></div>
          <div class="form-field"><label>Date de naissance</label><input v-model="form.dateNaissance" type="date" /></div>
          <div class="form-field"><label>N° Passeport</label><input v-model="form.numeroPasseport" placeholder="AB123456" /></div>
          <div class="form-field full"><label>Nationalité</label><input v-model="form.nationalite" placeholder="Algérienne" /></div>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="modal = null" class="btn-secondary">Annuler</button>
          <button @click="doCreatePelerin" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Création...' : 'Créer & envoyer email' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Create Guide -->
    <div v-if="modal === 'createGuide'" class="modal-overlay" @click.self="modal = null">
      <div class="modal">
        <h3 class="modal-title">Nouveau Guide</h3>
        <div class="form-grid">
          <div class="form-field"><label>Prénom *</label><input v-model="form.prenom" placeholder="Prénom" /></div>
          <div class="form-field"><label>Nom *</label><input v-model="form.nom" placeholder="Nom" /></div>
          <div class="form-field"><label>Email *</label><input v-model="form.email" type="email" placeholder="email@exemple.com" /></div>
          <div class="form-field"><label>Téléphone</label><input v-model="form.telephone" placeholder="+213..." /></div>
          <div class="form-field full"><label>Spécialité</label><input v-model="form.specialite" placeholder="Hajj, Umrah..." /></div>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="modal = null" class="btn-secondary">Annuler</button>
          <button @click="doCreateGuide" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Création...' : 'Créer & envoyer email' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Create Groupe -->
    <div v-if="modal === 'createGroupe'" class="modal-overlay" @click.self="modal = null">
      <div class="modal">
        <h3 class="modal-title">Nouveau Groupe</h3>
        <div class="form-grid">
          <div class="form-field full"><label>Nom *</label><input v-model="form.nom" placeholder="Groupe Hajj 2025" /></div>
          <div class="form-field"><label>Année *</label><input v-model="form.annee" type="number" placeholder="2025" /></div>
          <div class="form-field">
            <label>Type *</label>
            <select v-model="form.typeVoyage">
              <option value="HAJJ">Hajj</option>
              <option value="UMRAH">Umrah</option>
            </select>
          </div>
          <div class="form-field full"><label>Description</label><input v-model="form.description" placeholder="Description optionnelle" /></div>
          <div class="form-field full">
            <label>Guide (optionnel)</label>
            <select v-model="form.guideId">
              <option value="">— Sans guide —</option>
              <option v-for="g in guides" :key="g.id" :value="g.id">
                {{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}
              </option>
            </select>
          </div>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="modal = null" class="btn-secondary">Annuler</button>
          <button @click="doCreateGroupe" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Création...' : 'Créer le groupe' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Edit modal (shared) -->
    <div v-if="modal === 'edit'" class="modal-overlay" @click.self="modal = null">
      <div class="modal">
        <h3 class="modal-title">Modifier {{ editType === 'pelerin' ? 'le pèlerin' : editType === 'guide' ? 'le guide' : 'le groupe' }}</h3>
        <div class="form-grid">
          <template v-if="editType !== 'groupe'">
            <div class="form-field"><label>Prénom</label><input v-model="form.prenom" /></div>
            <div class="form-field"><label>Nom</label><input v-model="form.nom" /></div>
            <div class="form-field full"><label>Téléphone</label><input v-model="form.telephone" /></div>
          </template>
          <template v-if="editType === 'pelerin'">
            <div class="form-field"><label>Nationalité</label><input v-model="form.nationalite" /></div>
            <div class="form-field"><label>N° Passeport</label><input v-model="form.numeroPasseport" /></div>
          </template>
          <template v-if="editType === 'guide'">
            <div class="form-field full"><label>Spécialité</label><input v-model="form.specialite" /></div>
          </template>
          <template v-if="editType === 'groupe'">
            <div class="form-field full"><label>Nom</label><input v-model="form.nom" /></div>
            <div class="form-field"><label>Année</label><input v-model="form.annee" type="number" /></div>
            <div class="form-field">
              <label>Type</label>
              <select v-model="form.typeVoyage"><option value="HAJJ">Hajj</option><option value="UMRAH">Umrah</option></select>
            </div>
            <div class="form-field full"><label>Description</label><input v-model="form.description" /></div>
            <div class="form-field full">
              <label>Guide</label>
              <select v-model="form.guideId">
                <option value="">— Sans guide —</option>
                <option v-for="g in guides" :key="g.id" :value="g.id">{{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}</option>
              </select>
            </div>
          </template>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="modal = null" class="btn-secondary">Annuler</button>
          <button @click="doEdit" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Sauvegarde...' : 'Sauvegarder' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Assign Pèlerin to Groupe -->
    <div v-if="modal === 'assign'" class="modal-overlay" @click.self="modal = null">
      <div class="modal">
        <h3 class="modal-title">Affecter un pèlerin — {{ selectedGroupe?.nom }}</h3>
        <div class="form-field">
          <label>Choisir un pèlerin</label>
          <select v-model="form.pelerinId">
            <option value="">— Sélectionner —</option>
            <option v-for="p in unassignedPelerins" :key="p.id" :value="p.id">
              {{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}
            </option>
          </select>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="modal = null" class="btn-secondary">Annuler</button>
          <button @click="doAssign" :disabled="actionLoading || !form.pelerinId" class="btn-primary">
            {{ actionLoading ? 'Affectation...' : 'Affecter' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete confirm -->
    <div v-if="modal === 'delete'" class="modal-overlay" @click.self="modal = null">
      <div class="modal modal-sm">
        <h3 class="modal-title danger">Confirmer la suppression</h3>
        <p class="modal-desc">Supprimer <strong>{{ deleteTarget?.utilisateur?.prenom ?? deleteTarget?.nom }} {{ deleteTarget?.utilisateur?.nom ?? '' }}</strong> ? Cette action est irréversible.</p>
        <div class="modal-actions">
          <button @click="modal = null" class="btn-secondary">Annuler</button>
          <button @click="doDelete" :disabled="actionLoading" class="btn-danger">
            {{ actionLoading ? 'Suppression...' : 'Supprimer' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Toast -->
    <div v-if="toast.show" :class="['toast', toast.type]">
      {{ toast.message }}
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const BASE = 'http://localhost:3000'
const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const token = localStorage.getItem('accessToken')
const isDark = ref(true)

const currentView = ref('dashboard')
const loading = ref(true)
const fetchError = ref('')
const actionLoading = ref(false)
const modal = ref(null)
const modalError = ref('')
const editType = ref('')
const editTarget = ref(null)
const deleteTarget = ref(null)
const deleteType = ref('')
const selectedGroupe = ref(null)
const searchP = ref('')
const searchG = ref('')
const searchGr = ref('')

const pelerins = ref([])
const guides = ref([])
const groupes = ref([])

const form = ref({})

const navItems = [
  { view: 'dashboard', label: 'Vue d\'ensemble', badge: null,
    icon: '<svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>' },
  { view: 'pelerins', label: 'Pèlerins', badge: 'pelerins',
    icon: '<svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>' },
  { view: 'guides', label: 'Guides', badge: null,
    icon: '<svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>' },
  { view: 'groupes', label: 'Groupes', badge: 'groupes',
    icon: '<svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>' },
]

const viewTitle = computed(() => ({
  dashboard: 'Vue d\'ensemble', pelerins: 'Pèlerins', guides: 'Guides', groupes: 'Groupes'
}[currentView.value]))

const userInitials = computed(() => {
  return ((user.value?.prenom?.[0] ?? '') + (user.value?.nom?.[0] ?? '')).toUpperCase() || 'AG'
})

const filteredPelerins = computed(() =>
  pelerins.value.filter(p => {
    const q = searchP.value.toLowerCase()
    return !q || `${p.utilisateur?.prenom} ${p.utilisateur?.nom} ${p.utilisateur?.email}`.toLowerCase().includes(q)
  })
)

const filteredGuides = computed(() =>
  guides.value.filter(g => {
    const q = searchG.value.toLowerCase()
    return !q || `${g.utilisateur?.prenom} ${g.utilisateur?.nom} ${g.utilisateur?.email}`.toLowerCase().includes(q)
  })
)

const filteredGroupes = computed(() =>
  groupes.value.filter(gr => {
    const q = searchGr.value.toLowerCase()
    return !q || gr.nom.toLowerCase().includes(q)
  })
)

const unassignedPelerins = computed(() =>
  pelerins.value.filter(p => !p.groupeId || p.groupeId !== selectedGroupe.value?.id)
)

function getBadge(type) {
  if (type === 'pelerins') return pelerins.value.filter(p => !p.utilisateur?.actif).length
  if (type === 'groupes') return groupes.value.length
  return 0
}

function initials(prenom, nom) {
  return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
}

const headers = () => ({
  'Content-Type': 'application/json',
  Authorization: `Bearer ${token}`,
})

async function loadAll() {
  loading.value = true
  fetchError.value = ''
  try {
    const [rP, rGr] = await Promise.all([
      fetch(`${BASE}/agence/pelerins`, { headers: headers() }),
      fetch(`${BASE}/agence/groupes`, { headers: headers() }),
    ])
    if (!rP.ok || !rGr.ok) throw new Error('Erreur serveur')
    pelerins.value = await rP.json()
    guides.value = [] // à compléter quand ton ami finit les guides
    groupes.value = await rGr.json()
  } catch (e) {
    fetchError.value = 'Impossible de charger les données. Vérifiez que le serveur est démarré.'
  } finally {
    loading.value = false
  }
}

async function handleLogout() {
  try {
    await fetch(`${BASE}/auth/logout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: localStorage.getItem('refreshToken') }),
    })
  } finally {
    localStorage.clear()
    router.push('/')
  }
}

// ── Modal helpers ─────────────────────────────────────────────
function openModal(type) {
  form.value = { typeVoyage: 'HAJJ', annee: new Date().getFullYear() }
  modalError.value = ''
  modal.value = type
}

function openEdit(type, target) {
  editType.value = type
  editTarget.value = target
  modalError.value = ''
  if (type === 'pelerin') {
    form.value = {
      prenom: target.utilisateur?.prenom,
      nom: target.utilisateur?.nom,
      telephone: target.utilisateur?.telephone,
      nationalite: target.nationalite,
      numeroPasseport: target.numeroPasseport,
    }
  } else if (type === 'guide') {
    form.value = {
      prenom: target.utilisateur?.prenom,
      nom: target.utilisateur?.nom,
      telephone: target.utilisateur?.telephone,
      specialite: target.specialite,
    }
  } else if (type === 'groupe') {
    form.value = {
      nom: target.nom,
      annee: target.annee,
      typeVoyage: target.typeVoyage,
      description: target.description,
      guideId: target.guideId ?? '',
    }
  }
  modal.value = 'edit'
}

function openAssign(groupe) {
  selectedGroupe.value = groupe
  form.value = { pelerinId: '' }
  modalError.value = ''
  modal.value = 'assign'
}

function confirmDelete(type, target) {
  deleteType.value = type
  deleteTarget.value = target
  modal.value = 'delete'
}

// ── CRUD ─────────────────────────────────────────────────────
async function doCreatePelerin() {
  if (!form.value.nom || !form.value.prenom || !form.value.email) {
    modalError.value = 'Nom, prénom et email sont requis'
    return
  }
  actionLoading.value = true
  modalError.value = ''
  try {
    const res = await fetch(`${BASE}/agence/pelerins`, {
      method: 'POST', headers: headers(), body: JSON.stringify(form.value)
    })
    const data = await res.json()
    if (!res.ok) throw new Error(data.message)
    modal.value = null
    showToast('Pèlerin créé — email d\'activation envoyé', 'success')
    await loadAll()
  } catch (e) { modalError.value = e.message }
  finally { actionLoading.value = false }
}

async function doCreateGuide() {
  if (!form.value.nom || !form.value.prenom || !form.value.email) {
    modalError.value = 'Nom, prénom et email sont requis'
    return
  }
  actionLoading.value = true
  modalError.value = ''
  try {
    const res = await fetch(`${BASE}/agence/guides`, {
      method: 'POST', headers: headers(), body: JSON.stringify(form.value)
    })
    const data = await res.json()
    if (!res.ok) throw new Error(data.message)
    modal.value = null
    showToast('Guide créé — email d\'activation envoyé', 'success')
    await loadAll()
  } catch (e) { modalError.value = e.message }
  finally { actionLoading.value = false }
}

async function doCreateGroupe() {
  if (!form.value.nom || !form.value.annee || !form.value.typeVoyage) {
    modalError.value = 'Nom, année et type sont requis'
    return
  }
  actionLoading.value = true
  modalError.value = ''
  try {
    const body = { ...form.value, guideId: form.value.guideId || undefined }
    const res = await fetch(`${BASE}/agence/groupes`, {
      method: 'POST', headers: headers(), body: JSON.stringify(body)
    })
    const data = await res.json()
    if (!res.ok) throw new Error(data.message)
    modal.value = null
    showToast('Groupe créé avec succès', 'success')
    await loadAll()
  } catch (e) { modalError.value = e.message }
  finally { actionLoading.value = false }
}

async function doEdit() {
  actionLoading.value = true
  modalError.value = ''
  const urlMap = { pelerin: 'pelerins', guide: 'guides', groupe: 'groupes' }
  try {
    const res = await fetch(`${BASE}/agence/${urlMap[editType.value]}/${editTarget.value.id}`, {
      method: 'PATCH', headers: headers(), body: JSON.stringify(form.value)
    })
    const data = await res.json()
    if (!res.ok) throw new Error(data.message)
    modal.value = null
    showToast('Modifié avec succès', 'success')
    await loadAll()
  } catch (e) { modalError.value = e.message }
  finally { actionLoading.value = false }
}

async function doAssign() {
  actionLoading.value = true
  modalError.value = ''
  try {
    const res = await fetch(`${BASE}/agence/groupes/${selectedGroupe.value.id}/pelerins`, {
      method: 'POST', headers: headers(), body: JSON.stringify({ pelerinId: form.value.pelerinId })
    })
    const data = await res.json()
    if (!res.ok) throw new Error(data.message)
    modal.value = null
    showToast('Pèlerin affecté au groupe', 'success')
    await loadAll()
  } catch (e) { modalError.value = e.message }
  finally { actionLoading.value = false }
}

async function doDelete() {
  actionLoading.value = true
  const urlMap = { pelerin: 'pelerins', guide: 'guides', groupe: 'groupes' }
  try {
    const res = await fetch(`${BASE}/agence/${urlMap[deleteType.value]}/${deleteTarget.value.id}`, {
      method: 'DELETE', headers: headers()
    })
    if (!res.ok) { const d = await res.json(); throw new Error(d.message) }
    modal.value = null
    showToast('Supprimé avec succès', 'success')
    await loadAll()
  } catch (e) { showToast(e.message, 'error') }
  finally { actionLoading.value = false }
}

const toast = ref({ show: false, message: '', type: 'success' })
function showToast(message, type = 'success') {
  toast.value = { show: true, message, type }
  setTimeout(() => { toast.value.show = false }, 3500)
}

onMounted(loadAll)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap');

/* ── Tokens ─────────────────────────────────────────────────── */
.dashboard {
  --gold: #C9A84C;
  --gold-dim: #8a6e2f;
  --gold-glow: rgba(201,168,76,0.15);
  --bg: #f4f3ef;
  --bg2: #ffffff;
  --bg3: #eeece8;
  --sidebar-bg: #0f0e0b;
  --text: #1a1814;
  --text2: #6b6560;
  --border: rgba(0,0,0,0.08);
  --shadow: 0 2px 12px rgba(0,0,0,0.07);
  font-family: 'DM Sans', sans-serif;
  display: flex;
  height: 100vh;
  overflow: hidden;
  background: var(--bg);
  color: var(--text);
}

.dashboard.dark {
  --bg: #0d0c09;
  --bg2: #151410;
  --bg3: #1c1a15;
  --text: #f0ede6;
  --text2: #8a8070;
  --border: rgba(255,255,255,0.06);
  --shadow: 0 2px 16px rgba(0,0,0,0.4);
}

/* ── Sidebar ─────────────────────────────────────────────────── */
.sidebar {
  width: 240px;
  min-width: 240px;
  background: var(--sidebar-bg);
  display: flex;
  flex-direction: column;
  border-right: 1px solid rgba(201,168,76,0.12);
}

.sidebar-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 24px 20px 20px;
  border-bottom: 1px solid rgba(201,168,76,0.1);
}

.logo-icon { font-size: 26px; }
.logo-name { font-family: 'Syne', sans-serif; font-weight: 800; color: var(--gold); font-size: 15px; letter-spacing: 0.5px; }
.logo-sub { color: #5a5040; font-size: 11px; margin-top: 1px; }

.sidebar-nav { flex: 1; padding: 16px 12px; overflow-y: auto; }
.nav-section-label { color: #3a3428; font-size: 10px; font-weight: 600; letter-spacing: 1.2px; text-transform: uppercase; padding: 0 8px; margin-bottom: 8px; }

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 10px;
  color: #7a6e5e;
  cursor: pointer;
  font-size: 13.5px;
  font-weight: 500;
  transition: all 0.15s;
  margin-bottom: 2px;
  text-decoration: none;
}
.nav-item:hover { background: rgba(201,168,76,0.08); color: #c9a84c; }
.nav-item.active { background: rgba(201,168,76,0.15); color: var(--gold); }
.nav-icon { opacity: 0.8; display: flex; }
.nav-badge { margin-left: auto; background: var(--gold); color: #0d0c09; font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 20px; }

.sidebar-footer {
  padding: 16px 12px;
  border-top: 1px solid rgba(201,168,76,0.1);
  display: flex;
  align-items: center;
  gap: 10px;
}
.user-card { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
.user-avatar { width: 34px; height: 34px; border-radius: 10px; background: var(--gold-glow); border: 1px solid var(--gold-dim); color: var(--gold); font-family: 'Syne', sans-serif; font-weight: 700; font-size: 13px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.user-name { color: #c0b090; font-size: 13px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.user-role { color: #4a4030; font-size: 11px; }
.user-info { min-width: 0; }
.logout-btn { background: none; border: none; color: #4a4030; cursor: pointer; padding: 6px; border-radius: 8px; transition: all 0.15s; flex-shrink: 0; }
.logout-btn:hover { color: #e05555; background: rgba(224,85,85,0.1); }

/* ── Main ────────────────────────────────────────────────────── */
.main-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; }

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 28px;
  height: 58px;
  background: var(--bg2);
  border-bottom: 1px solid var(--border);
  flex-shrink: 0;
}
.breadcrumb { display: flex; align-items: center; gap: 8px; }
.breadcrumb-root { color: var(--text2); font-size: 13px; }
.breadcrumb-sep { color: var(--text2); }
.breadcrumb-current { font-family: 'Syne', sans-serif; font-weight: 700; font-size: 14px; color: var(--text); }
.topbar-right { display: flex; gap: 8px; }
.topbar-btn { background: var(--bg3); border: 1px solid var(--border); color: var(--text2); width: 34px; height: 34px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.topbar-btn:hover { border-color: var(--gold); color: var(--gold); }

.content { flex: 1; overflow-y: auto; padding: 24px 28px; }

/* ── State ───────────────────────────────────────────────────── */
.state-center { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 300px; gap: 16px; color: var(--text2); }
.spinner { width: 36px; height: 36px; border: 3px solid var(--border); border-top-color: var(--gold); border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.error-text { color: #e05555; }

/* ── Dashboard ───────────────────────────────────────────────── */
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 24px; }

.stat-card {
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 20px;
  position: relative;
  overflow: hidden;
  box-shadow: var(--shadow);
}
.stat-card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; }
.stat-card.gold::before { background: linear-gradient(90deg, var(--gold), #e8c060); }
.stat-card.blue::before { background: linear-gradient(90deg, #4a9eff, #7bb8ff); }
.stat-card.green::before { background: linear-gradient(90deg, #4ade80, #86efac); }
.stat-card.orange::before { background: linear-gradient(90deg, #fb923c, #fdba74); }

.stat-icon { font-size: 28px; margin-bottom: 12px; }
.stat-body { display: flex; align-items: baseline; gap: 8px; margin-bottom: 4px; }
.stat-value { font-family: 'Syne', sans-serif; font-size: 32px; font-weight: 800; color: var(--text); }
.stat-label { color: var(--text2); font-size: 13px; }
.stat-sub { color: var(--text2); font-size: 12px; }

.recent-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

/* ── Card ────────────────────────────────────────────────────── */
.card { background: var(--bg2); border: 1px solid var(--border); border-radius: 16px; padding: 20px; box-shadow: var(--shadow); }
.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.card-header h3 { font-family: 'Syne', sans-serif; font-weight: 700; font-size: 15px; color: var(--text); }
.card-link { color: var(--gold); font-size: 12px; font-weight: 500; background: none; border: none; cursor: pointer; }
.card-link:hover { text-decoration: underline; }

.mini-table { display: flex; flex-direction: column; gap: 4px; }
.empty-row { text-align: center; color: var(--text2); font-size: 13px; padding: 24px; }
.mini-row { display: flex; align-items: center; gap: 12px; padding: 10px 8px; border-radius: 10px; transition: background 0.1s; }
.mini-row:hover { background: var(--bg3); }
.mini-avatar { width: 36px; height: 36px; border-radius: 10px; background: rgba(74,158,255,0.1); color: #4a9eff; font-family: 'Syne', sans-serif; font-weight: 700; font-size: 13px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.gold-av { background: var(--gold-glow); color: var(--gold); }
.mini-info { flex: 1; min-width: 0; }
.mini-name { font-size: 13.5px; font-weight: 500; color: var(--text); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.mini-sub { font-size: 11.5px; color: var(--text2); }

/* ── Status pills ────────────────────────────────────────────── */
.status-pill { font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 20px; }
.status-pill.active { background: rgba(74,222,128,0.12); color: #4ade80; }
.status-pill.pending { background: rgba(251,146,60,0.12); color: #fb923c; }
.type-pill { font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 20px; background: var(--gold-glow); color: var(--gold); }

/* ── Section views ───────────────────────────────────────────── */
.view-section { display: flex; flex-direction: column; gap: 16px; }
.section-topbar { display: flex; align-items: center; gap: 12px; }
.search-input { flex: 1; max-width: 320px; padding: 9px 14px; background: var(--bg2); border: 1px solid var(--border); border-radius: 10px; color: var(--text); font-size: 13.5px; font-family: 'DM Sans', sans-serif; outline: none; transition: border-color 0.15s; }
.search-input:focus { border-color: var(--gold); }
.search-input::placeholder { color: var(--text2); }

/* ── Table ───────────────────────────────────────────────────── */
.data-table { width: 100%; border-collapse: collapse; }
.data-table th { text-align: left; padding: 10px 14px; font-size: 11.5px; font-weight: 600; letter-spacing: 0.5px; text-transform: uppercase; color: var(--text2); border-bottom: 1px solid var(--border); }
.data-table td { padding: 13px 14px; border-bottom: 1px solid var(--border); font-size: 13.5px; }
.data-table tr:last-child td { border-bottom: none; }
.data-table tbody tr:hover td { background: var(--bg3); }
.cell-user { display: flex; align-items: center; gap: 10px; }
.cell-avatar { width: 34px; height: 34px; border-radius: 10px; background: rgba(74,158,255,0.1); color: #4a9eff; font-family: 'Syne', sans-serif; font-weight: 700; font-size: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.green-av { background: rgba(74,222,128,0.1); color: #4ade80; }
.cell-name { font-size: 13.5px; font-weight: 500; color: var(--text); }
.cell-sub { font-size: 12px; color: var(--text2); }
.group-tag { background: var(--gold-glow); color: var(--gold); font-size: 11.5px; font-weight: 500; padding: 3px 10px; border-radius: 20px; }
.action-btns { display: flex; gap: 6px; }
.act-btn { background: var(--bg3); border: 1px solid var(--border); border-radius: 8px; width: 30px; height: 30px; cursor: pointer; font-size: 13px; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.act-btn:hover { border-color: var(--gold); transform: scale(1.05); }
.empty-state { text-align: center; color: var(--text2); font-size: 14px; padding: 48px; }

/* ── Groups grid ─────────────────────────────────────────────── */
.groups-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.group-card { background: var(--bg2); border: 1px solid var(--border); border-radius: 16px; padding: 20px; box-shadow: var(--shadow); display: flex; flex-direction: column; gap: 10px; }
.group-card-header { display: flex; align-items: center; justify-content: space-between; }
.group-type-badge { font-size: 11px; font-weight: 700; letter-spacing: 0.8px; padding: 4px 12px; border-radius: 20px; }
.group-type-badge.hajj { background: var(--gold-glow); color: var(--gold); border: 1px solid rgba(201,168,76,0.2); }
.group-type-badge.umrah { background: rgba(74,158,255,0.1); color: #4a9eff; border: 1px solid rgba(74,158,255,0.2); }
.group-name { font-family: 'Syne', sans-serif; font-weight: 700; font-size: 16px; color: var(--text); }
.group-meta { font-size: 12.5px; color: var(--text2); }
.group-stats { display: flex; gap: 20px; padding: 12px 0; border-top: 1px solid var(--border); border-bottom: 1px solid var(--border); }
.group-stat { display: flex; flex-direction: column; gap: 2px; }
.gs-val { font-family: 'Syne', sans-serif; font-weight: 700; font-size: 20px; color: var(--text); }
.gs-lbl { font-size: 11px; color: var(--text2); text-transform: uppercase; letter-spacing: 0.5px; }
.group-guide { font-size: 12.5px; color: var(--text2); }
.btn-assign { background: var(--gold-glow); border: 1px solid rgba(201,168,76,0.25); color: var(--gold); padding: 8px 14px; border-radius: 10px; font-size: 12.5px; font-weight: 600; cursor: pointer; transition: all 0.15s; margin-top: 4px; }
.btn-assign:hover { background: rgba(201,168,76,0.2); }

/* ── Buttons ─────────────────────────────────────────────────── */
.btn-primary { background: var(--gold); color: #0d0c09; border: none; padding: 9px 18px; border-radius: 10px; font-size: 13.5px; font-weight: 700; font-family: 'DM Sans', sans-serif; cursor: pointer; transition: all 0.15s; white-space: nowrap; }
.btn-primary:hover { background: #e0bb5a; }
.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }
.btn-secondary { background: var(--bg3); border: 1px solid var(--border); color: var(--text); padding: 9px 18px; border-radius: 10px; font-size: 13.5px; font-weight: 500; font-family: 'DM Sans', sans-serif; cursor: pointer; transition: all 0.15s; }
.btn-secondary:hover { border-color: var(--gold); }
.btn-danger { background: #e05555; border: none; color: white; padding: 9px 18px; border-radius: 10px; font-size: 13.5px; font-weight: 600; font-family: 'DM Sans', sans-serif; cursor: pointer; transition: all 0.15s; }
.btn-danger:hover { background: #c44; }
.btn-danger:disabled { opacity: 0.5; }

/* ── Modals ──────────────────────────────────────────────────── */
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(6px); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 20px; }
.modal { background: var(--bg2); border: 1px solid var(--border); border-radius: 20px; padding: 28px; width: 100%; max-width: 500px; box-shadow: 0 20px 60px rgba(0,0,0,0.4); }
.modal-sm { max-width: 380px; }
.modal-title { font-family: 'Syne', sans-serif; font-weight: 800; font-size: 18px; color: var(--text); margin-bottom: 20px; }
.modal-title.danger { color: #e05555; }
.modal-desc { color: var(--text2); font-size: 14px; margin-bottom: 20px; line-height: 1.5; }
.modal-error { color: #e05555; font-size: 13px; margin-bottom: 12px; }
.modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }

.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-field { display: flex; flex-direction: column; gap: 6px; }
.form-field.full { grid-column: 1 / -1; }
.form-field label { font-size: 12px; font-weight: 600; color: var(--text2); letter-spacing: 0.3px; }
.form-field input, .form-field select {
  padding: 9px 12px;
  background: var(--bg3);
  border: 1px solid var(--border);
  border-radius: 10px;
  color: var(--text);
  font-size: 13.5px;
  font-family: 'DM Sans', sans-serif;
  outline: none;
  transition: border-color 0.15s;
}
.form-field input:focus, .form-field select:focus { border-color: var(--gold); }
.form-field select option { background: var(--bg2); }

/* ── Toast ───────────────────────────────────────────────────── */
.toast { position: fixed; bottom: 28px; right: 28px; padding: 14px 20px; border-radius: 12px; font-size: 13.5px; font-weight: 500; z-index: 200; box-shadow: 0 8px 24px rgba(0,0,0,0.3); animation: slideUp 0.25s ease; }
.toast.success { background: #1a2e1a; color: #4ade80; border: 1px solid rgba(74,222,128,0.2); }
.toast.error { background: #2e1a1a; color: #f87171; border: 1px solid rgba(248,113,113,0.2); }
@keyframes slideUp { from { transform: translateY(12px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
</style>