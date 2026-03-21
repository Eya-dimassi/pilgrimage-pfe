<template>
  <div class="dashboard" :class="{ dark: isDark }">

    <!-- ── Sidebar ── -->
    <aside class="sidebar">
      <div class="sidebar-logo">
        <span class="logo-icon">🕌</span>
        <div>
          <div class="logo-name">SmartHajj</div>
          <div class="logo-sub">Espace Agence</div>
        </div>
      </div>

      <nav class="sidebar-nav">
        <p class="nav-section-label">Navigation</p>
        <a v-for="item in navItems" :key="item.view" href="#"
          :class="['nav-item', { active: currentView === item.view }]"
          @click.prevent="currentView = item.view">
          <span class="nav-icon" v-html="item.icon"></span>
          <span>{{ item.label }}</span>
          <span v-if="item.badge && getBadge(item.badge) > 0" class="nav-badge">
            {{ getBadge(item.badge) }}
          </span>
        </a>
      </nav>

      <div class="sidebar-footer">
        <div class="user-card" @click="openProfile" style="cursor:pointer" title="Modifier le profil">
          <div class="user-avatar">{{ userInitials }}</div>
          <div class="user-info">
            <div class="user-name">{{ user?.prenom }} {{ user?.nom }}</div>
            <div class="user-role">Agence</div>
          </div>
        </div>
        <button @click="handleLogout" class="logout-btn" title="Déconnecter">
          <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
        </button>
      </div>
    </aside>

    <!-- ── Main ── -->
    <div class="main-area">
      <header class="topbar">
        <div class="breadcrumb">
          <span class="breadcrumb-root">Agence</span>
          <span class="breadcrumb-sep">›</span>
          <span class="breadcrumb-current">{{ viewTitle }}</span>
        </div>
        <div class="topbar-right">
          <button @click="loadAll" class="topbar-btn" title="Actualiser">
            <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
              <polyline points="23 4 23 10 17 10"/>
              <polyline points="1 20 1 14 7 14"/>
              <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
            </svg>
          </button>
          <button @click="isDark = !isDark" class="topbar-btn">
            <svg v-if="isDark" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
              <circle cx="12" cy="12" r="5"/>
              <line x1="12" y1="1" x2="12" y2="3"/>
              <line x1="12" y1="21" x2="12" y2="23"/>
              <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
              <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
              <line x1="1" y1="12" x2="3" y2="12"/>
              <line x1="21" y1="12" x2="23" y2="12"/>
              <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
              <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
            </svg>
            <svg v-else width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
            </svg>
          </button>
        </div>
      </header>

      <div class="content">
        <div v-if="loading" class="state-center">
          <div class="spinner"></div>
          <p>Chargement...</p>
        </div>
        <div v-else-if="fetchError" class="state-center">
          <p class="error-text">{{ fetchError }}</p>
          <button @click="loadAll" class="btn-primary">Réessayer</button>
        </div>

        <template v-else>

          <!-- ── VUE D'ENSEMBLE ── -->
          <div v-if="currentView === 'dashboard'" class="view-dashboard">

            <!-- ── Primary stats ── -->
            <div class="stats-grid">
              <div class="stat-card gold" @click="currentView='groupes'" style="cursor:pointer">
                <div class="stat-icon-wrap gold-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="22" height="22">
                    <path d="M2 20h20"/><path d="M5 20V8l7-5 7 5v12"/><path d="M9 20v-6h6v6"/>
                  </svg>
                </div>
                <div class="stat-body">
                  <div class="stat-value">{{ groupes.length }}</div>
                  <div class="stat-label">Groupes</div>
                </div>
                <div class="stat-sub">
                  {{ groupes.filter(g=>g.typeVoyage==='HAJJ').length }} Hajj ·
                  {{ groupes.filter(g=>g.typeVoyage==='UMRAH').length }} Umrah
                </div>
              </div>

              <div class="stat-card blue" @click="currentView='pelerins'" style="cursor:pointer">
                <div class="stat-icon-wrap blue-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="22" height="22">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                  </svg>
                </div>
                <div class="stat-body">
                  <div class="stat-value">{{ pelerins.length }}</div>
                  <div class="stat-label">Pèlerins</div>
                </div>
                <div class="stat-sub">
                  {{ pelerins.filter(p=>p.utilisateur?.actif).length }} actifs ·
                  <span :class="pelerins.filter(p=>!p.groupeId).length > 0 ? 'stat-sub-warn' : ''">
                    {{ pelerins.filter(p=>!p.groupeId).length }} sans groupe
                  </span>
                </div>
              </div>

              <div class="stat-card green" @click="currentView='guides'" style="cursor:pointer">
                <div class="stat-icon-wrap green-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="22" height="22">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                    <circle cx="12" cy="7" r="4"/>
                  </svg>
                </div>
                <div class="stat-body">
                  <div class="stat-value">{{ guides.length }}</div>
                  <div class="stat-label">Guides</div>
                </div>
                <div class="stat-sub">
                  {{ guides.filter(g=>g.isActivated).length }} activés ·
                  <span :class="guides.filter(g=>!g.isActivated).length > 0 ? 'stat-sub-warn' : ''">
                    {{ guides.filter(g=>!g.isActivated).length }} en attente
                  </span>
                </div>
              </div>

              <div class="stat-card orange">
                <div class="stat-icon-wrap orange-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="22" height="22">
                    <circle cx="12" cy="12" r="10"/>
                    <polyline points="12 6 12 12 16 14"/>
                  </svg>
                </div>
                <div class="stat-body">
                  <div class="stat-value">
                    {{ pelerins.filter(p=>!p.utilisateur?.actif).length + guides.filter(g=>!g.isActivated).length }}
                  </div>
                  <div class="stat-label">En attente</div>
                </div>
                <div class="stat-sub">Activation email</div>
              </div>
            </div>

            <!-- ── Action needed banner ── -->
            <div v-if="actionsNeeded.length > 0" class="actions-banner">
              <div class="actions-banner-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="16" height="16">
                  <circle cx="12" cy="12" r="10"/>
                  <line x1="12" y1="8" x2="12" y2="12"/>
                  <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
              </div>
              <div class="actions-banner-items">
                <span v-for="action in actionsNeeded" :key="action.key"
                  class="action-chip" @click="currentView = action.view" style="cursor:pointer">
                  {{ action.label }}
                </span>
              </div>
            </div>

            <!-- ── Recent tables ── -->
            <div class="recent-grid">
              <div class="card">
                <div class="card-header">
                  <h3>Derniers Pèlerins</h3>
                  <button @click="currentView='pelerins'" class="card-link">Voir tout →</button>
                </div>
                <div class="mini-table">
                  <div v-if="pelerins.length === 0" class="empty-row">
                    <div style="display:flex;flex-direction:column;align-items:center;gap:8px;padding:16px">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="28" height="28" style="opacity:0.3">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>
                      </svg>
                      <span>Aucun pèlerin —</span>
                      <button @click="openModal('createPelerin')" class="card-link">+ Ajouter le premier</button>
                    </div>
                  </div>
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
                  <h3>Derniers Guides</h3>
                  <button @click="currentView='guides'" class="card-link">Voir tout →</button>
                </div>
                <div class="mini-table">
                  <div v-if="guides.length === 0" class="empty-row">
                    <div style="display:flex;flex-direction:column;align-items:center;gap:8px;padding:16px">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="28" height="28" style="opacity:0.3">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                      </svg>
                      <span>Aucun guide —</span>
                      <button @click="openModal('createGuide')" class="card-link">+ Ajouter le premier</button>
                    </div>
                  </div>
                  <div v-for="g in guides.slice(0,5)" :key="g.id" class="mini-row">
                    <div class="mini-avatar green-av">{{ initials(g.utilisateur?.prenom, g.utilisateur?.nom) }}</div>
                    <div class="mini-info">
                      <div class="mini-name">{{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}</div>
                      <div class="mini-sub">{{ g.specialite || 'Pas de spécialité' }}</div>
                    </div>
                    <span :class="['status-pill', guideStatusClass(g)]">{{ guideStatusLabel(g) }}</span>
                  </div>
                </div>
              </div>

              <div class="card">
                <div class="card-header">
                  <h3>Groupes</h3>
                  <button @click="currentView='groupes'" class="card-link">Voir tout →</button>
                </div>
                <div class="mini-table">
                  <div v-if="groupes.length === 0" class="empty-row">
                    <div style="display:flex;flex-direction:column;align-items:center;gap:8px;padding:16px">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="28" height="28" style="opacity:0.3">
                        <path d="M2 20h20"/><path d="M5 20V8l7-5 7 5v12"/><path d="M9 20v-6h6v6"/>
                      </svg>
                      <span>Aucun groupe —</span>
                      <button @click="openModal('createGroupe')" class="card-link">+ Créer le premier</button>
                    </div>
                  </div>
                  <div v-for="g in groupes.slice(0,5)" :key="g.id" class="mini-row">
                    <div class="mini-avatar gold-av">{{ g.typeVoyage === 'HAJJ' ? '🕌' : '🌙' }}</div>
                    <div class="mini-info">
                      <div class="mini-name">{{ g.nom }}</div>
                      <div class="mini-sub">
                        {{ g.annee }} · {{ g._count?.pelerins ?? 0 }} pèlerins
                        <span v-if="!g.guide" class="mini-warn">· sans guide</span>
                      </div>
                    </div>
                    <span class="type-pill">{{ g.typeVoyage }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- ── PÈLERINS ── -->
          <DashPelerins v-if="currentView === 'pelerins'"
            :pelerins="pelerins"
            :groupes="groupes"
            @create="openModal('createPelerin')"
            @edit="openEdit('pelerin', $event)"
            @delete="confirmDelete('pelerin', $event)"
            @assign="doAssignerPelerin($event)"
            @unassign="doRetirerPelerin($event)"
          />

          <!-- ── GUIDES ── -->
          <DashGuides v-if="currentView === 'guides'"
            :guides="guides"
            :resendingId="resendingId"
            @create="openModal('createGuide')"
            @edit="openEdit('guide', $event)"
            @delete="confirmDelete('guide', $event)"
            @resend="doResendActivation($event)"
          />

          <!-- ── GROUPES ── -->
          <DashGroupes v-if="currentView === 'groupes'"
            :groupes="groupes"
            @create="openModal('createGroupe')"
            @edit="openEdit('groupe', $event)"
            @delete="confirmDelete('groupe', $event)"
            @assign="openAssign($event)"
            @remove-pelerin="doRetirerPelerin($event)"
          />

        </template>
      </div>
    </div>

    <!-- ── MODALS ── -->

    <div v-if="modal === 'createPelerin'" class="modal-overlay" @click.self="closeModal">
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
          <button @click="closeModal" class="btn-secondary">Annuler</button>
          <button @click="doCreatePelerin" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Création...' : 'Créer & envoyer email' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'createGuide'" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <h3 class="modal-title">Nouveau Guide</h3>
        <div class="form-grid">
          <div class="form-field"><label>Prénom *</label><input v-model="form.prenom" placeholder="Prénom" /></div>
          <div class="form-field"><label>Nom *</label><input v-model="form.nom" placeholder="Nom" /></div>
          <div class="form-field"><label>Email *</label><input v-model="form.email" type="email" placeholder="email@exemple.com" /></div>
          <div class="form-field"><label>Téléphone</label><input v-model="form.telephone" placeholder="+213..." /></div>
          <div class="form-field full">
            <label>Spécialité</label>
            <select v-model="form.specialite">
              <option value="">Aucune spécialité</option>
              <option value="Hajj">Hajj</option>
              <option value="Umrah">Umrah</option>
              <option value="Bilingue">Bilingue (Arabe/Français)</option>
              <option value="Médical">Formation médicale</option>
              <option value="Senior">Guide senior (10+ ans)</option>
            </select>
          </div>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="closeModal" class="btn-secondary">Annuler</button>
          <button @click="doCreateGuide" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Création...' : 'Créer & envoyer email' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'createGroupe'" class="modal-overlay" @click.self="closeModal">
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
          <button @click="closeModal" class="btn-secondary">Annuler</button>
          <button @click="doCreateGroupe" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Création...' : 'Créer le groupe' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'edit'" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <h3 class="modal-title">
          Modifier {{ editType === 'pelerin' ? 'le pèlerin' : editType === 'guide' ? 'le guide' : 'le groupe' }}
        </h3>
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
            <div class="form-field full">
              <label>Spécialité</label>
              <select v-model="form.specialite">
                <option value="">Aucune spécialité</option>
                <option value="Hajj">Hajj</option>
                <option value="Umrah">Umrah</option>
                <option value="Bilingue">Bilingue (Arabe/Français)</option>
                <option value="Médical">Formation médicale</option>
                <option value="Senior">Guide senior (10+ ans)</option>
              </select>
            </div>
          </template>
          <template v-if="editType === 'groupe'">
            <div class="form-field full"><label>Nom</label><input v-model="form.nom" /></div>
            <div class="form-field"><label>Année</label><input v-model="form.annee" type="number" /></div>
            <div class="form-field">
              <label>Type</label>
              <select v-model="form.typeVoyage">
                <option value="HAJJ">Hajj</option>
                <option value="UMRAH">Umrah</option>
              </select>
            </div>
            <div class="form-field full"><label>Description</label><input v-model="form.description" /></div>
            <div class="form-field full">
              <label>Guide</label>
              <select v-model="form.guideId">
                <option value="">— Sans guide —</option>
                <option v-for="g in guides" :key="g.id" :value="g.id">
                  {{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}
                </option>
              </select>
            </div>
          </template>
        </div>
        <p v-if="modalError" class="modal-error">{{ modalError }}</p>
        <div class="modal-actions">
          <button @click="closeModal" class="btn-secondary">Annuler</button>
          <button @click="doEdit" :disabled="actionLoading" class="btn-primary">
            {{ actionLoading ? 'Sauvegarde...' : 'Sauvegarder' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'assign'" class="modal-overlay" @click.self="closeModal">
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
          <button @click="closeModal" class="btn-secondary">Annuler</button>
          <button @click="doAssign" :disabled="actionLoading || !form.pelerinId" class="btn-primary">
            {{ actionLoading ? 'Affectation...' : 'Affecter' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'delete'" class="modal-overlay" @click.self="closeModal">
      <div class="modal modal-sm">
        <h3 class="modal-title danger">Confirmer la suppression</h3>
        <p class="modal-desc">
          Supprimer <strong>
            {{ deleteTarget?.utilisateur?.prenom ?? deleteTarget?.nom }}
            {{ deleteTarget?.utilisateur?.nom ?? '' }}
          </strong> ? Cette action est irréversible.
        </p>
        <div class="modal-actions">
          <button @click="closeModal" class="btn-secondary">Annuler</button>
          <button @click="doDelete" :disabled="actionLoading" class="btn-danger">
            {{ actionLoading ? 'Suppression...' : 'Supprimer' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Profile modal -->
    <div v-if="showProfile" class="modal-overlay" @click.self="showProfile = false">
      <div class="modal">
        <h3 class="modal-title">Profil de l'agence</h3>
        <div class="form-grid">
          <div class="form-field full">
            <label>Nom de l'agence</label>
            <input v-model="profileForm.nomAgence" placeholder="Nom de l'agence" />
          </div>
          <div class="form-field full">
            <label>Adresse</label>
            <input v-model="profileForm.adresse" placeholder="Adresse" />
          </div>
          <div class="form-field">
            <label>Téléphone</label>
            <input v-model="profileForm.telephone" placeholder="+213..." />
          </div>
          <div class="form-field">
            <label>Site web</label>
            <input v-model="profileForm.siteWeb" placeholder="https://..." />
          </div>
        </div>
        <p v-if="profileError" class="modal-error">{{ profileError }}</p>
        <div class="modal-actions">
          <button @click="showProfile = false" class="btn-secondary">Annuler</button>
          <button @click="saveProfile" :disabled="profileLoading" class="btn-primary">
            {{ profileLoading ? 'Sauvegarde...' : 'Sauvegarder' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="toast.show" :class="['toast', toast.type]">{{ toast.message }}</div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAgenceData } from '@/composables/useAgenceData'
import { useModal } from '@/composables/useModal'
import DashPelerins from '@/views/agence/Dashpelerins.vue'
import DashGuides from '@/views/agence/Dashguides.vue'
import DashGroupes from '@/views/agence/Dashgroupes.vue'

import '@/assets/styles/dashboard.css'

// ── Data composable ───────────────────────────────────────────
const {
  user, handleLogout,
  pelerins, guides, groupes, loading, fetchError, loadAll,
  getBadge, initials,
  getProfile, updateProfile,
} = useAgenceData()

// ── Modal composable ──────────────────────────────────────────
const {
  modal, modalError, actionLoading, resendingId, form,
  editType, deleteTarget, selectedGroupe, toast,
  closeModal, openModal, openEdit, openAssign, confirmDelete, showToast,
  doCreatePelerin, doCreateGuide, doCreateGroupe,
  doEdit, doAssign, doDelete, doResendActivation,
  doAssignerPelerin, doRetirerPelerin,
} = useModal()

// ── Local UI state ────────────────────────────────────────────
const isDark = ref(true)
const currentView = ref('dashboard')

// ── Computed ──────────────────────────────────────────────────
const userInitials = computed(() =>
  ((user.value?.prenom?.[0] ?? '') + (user.value?.nom?.[0] ?? '')).toUpperCase() || 'AG'
)

const viewTitle = computed(() => ({
  dashboard: "Vue d'ensemble",
  pelerins: 'Pèlerins',
  guides: 'Guides',
  groupes: 'Groupes',
}[currentView.value]))

const unassignedPelerins = computed(() =>
  pelerins.value.filter(p => !p.groupeId || p.groupeId !== selectedGroupe.value?.id)
)

// ── Actions needed for banner ─────────────────────────────
const actionsNeeded = computed(() => {
  const actions = []
  const pSansGroupe = pelerins.value.filter(p => !p.groupeId).length
  const gNonActives = guides.value.filter(g => !g.isActivated).length
  const pNonActifs = pelerins.value.filter(p => !p.utilisateur?.actif).length
  const grSansGuide = groupes.value.filter(g => !g.guide).length
  if (pSansGroupe > 0) actions.push({ key: 'sg', label: `${pSansGroupe} pèlerin${pSansGroupe > 1 ? 's' : ''} sans groupe`, view: 'pelerins' })
  if (gNonActives > 0) actions.push({ key: 'gna', label: `${gNonActives} guide${gNonActives > 1 ? 's' : ''} non activé${gNonActives > 1 ? 's' : ''}`, view: 'guides' })
  if (pNonActifs > 0) actions.push({ key: 'pna', label: `${pNonActifs} pèlerin${pNonActifs > 1 ? 's' : ''} en attente`, view: 'pelerins' })
  if (grSansGuide > 0) actions.push({ key: 'gsg', label: `${grSansGuide} groupe${grSansGuide > 1 ? 's' : ''} sans guide`, view: 'groupes' })
  return actions
})

// ── Guide status ──────────────────────────────────────────────
function guideStatusClass(g) {
  if (!g.isActivated) return 'pending'
  if (!g.utilisateur?.actif) return 'suspended'
  return 'active'
}

function guideStatusLabel(g) {
  if (!g.isActivated) return 'En attente'
  if (!g.utilisateur?.actif) return 'Suspendu'
  return 'Actif'
}

// ── Nav ───────────────────────────────────────────────────────
const navItems = [
  { view: 'dashboard', label: "Vue d'ensemble", badge: null,
    icon: `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
      <rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>
      <rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>
    </svg>` },
  { view: 'pelerins', label: 'Pèlerins', badge: 'pelerins',
    icon: `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
      <circle cx="9" cy="7" r="4"/>
      <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
      <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
    </svg>` },
  { view: 'guides', label: 'Guides', badge: 'guides',
    icon: `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
      <circle cx="12" cy="7" r="4"/>
    </svg>` },
  { view: 'groupes', label: 'Groupes', badge: 'groupes',
    icon: `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
      <path d="M2 20h20"/><path d="M5 20V8l7-5 7 5v12"/>
      <path d="M9 20v-6h6v6"/>
    </svg>` },
]

// ── Profile modal ─────────────────────────────────────────────
const showProfile = ref(false)
const profileForm = ref({})
const profileLoading = ref(false)
const profileError = ref('')

async function openProfile() {
  profileError.value = ''
  try {
    const data = await getProfile()
    profileForm.value = {
      nomAgence: data.nomAgence,
      adresse: data.adresse || '',
      siteWeb: data.siteWeb || '',
      telephone: data.utilisateur?.telephone || '',
    }
    showProfile.value = true
  } catch (e) {
    showToast('Impossible de charger le profil', 'error')
  }
}

async function saveProfile() {
  profileLoading.value = true
  profileError.value = ''
  try {
    await updateProfile(profileForm.value)
    showProfile.value = false
    showToast('Profil mis à jour')
  } catch (e) {
    profileError.value = e.response?.data?.message || e.message
  } finally {
    profileLoading.value = false
  }
}

onMounted(loadAll)
</script>