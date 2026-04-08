<template>
  <div class="ad-modal-overlay" @click.self="$emit('close')">
    <div class="ad-modal-box ad-modal-box--profile" style="position: relative">
      <button class="ad-modal-close-top" @click="$emit('close')">
        <AppIcon name="x" :size="14" :stroke-width="2.5" />
      </button>

      <div class="admin-profile-head">
        <div class="admin-profile-avatar">{{ initials }}</div>
        <div class="admin-profile-head-copy">
          <p class="admin-profile-title">Mon profil</p>
          <p class="admin-profile-sub">Gerez vos informations de compte administrateur.</p>
        </div>
      </div>

      <div v-if="error" class="state-error admin-profile-error">
        <p>{{ error }}</p>
      </div>

      <div class="admin-profile-meta">
        <div class="admin-profile-chip">
          <span class="admin-profile-chip-label">Role</span>
          <span class="admin-profile-chip-value">{{ roleLabel }}</span>
        </div>
        <div class="admin-profile-chip">
          <span class="admin-profile-chip-label">Compte</span>
          <span class="admin-profile-chip-value">{{ accountStatus }}</span>
        </div>
      </div>

      <div class="detail-section-title">Informations personnelles</div>
      <div class="detail-grid detail-grid--compact">
        <div class="detail-field">
          <label class="detail-label">Prenom</label>
          <input v-model="form.prenom" class="admin-profile-input" placeholder="Prenom" />
        </div>
        <div class="detail-field">
          <label class="detail-label">Nom</label>
          <input v-model="form.nom" class="admin-profile-input" placeholder="Nom" />
        </div>
        <div class="detail-field">
          <label class="detail-label">Email</label>
          <input v-model="form.email" class="admin-profile-input" type="email" placeholder="email@domaine.com" />
        </div>
        <div class="detail-field">
          <label class="detail-label">Telephone</label>
          <input v-model="form.telephone" class="admin-profile-input" placeholder="+216..." />
        </div>
      </div>

      <div class="ad-modal-actions">
        <button class="ad-btn ad-btn--cancel" @click="$emit('close')">Annuler</button>
        <button class="ad-btn ad-btn--green" :disabled="loading" @click="$emit('submit')">
          {{ loading ? 'Sauvegarde...' : 'Sauvegarder' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import AppIcon from '@/components/AppIcon.vue'

const props = defineProps({
  form: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
  user: {
    type: Object,
    default: () => ({}),
  },
  roleLabel: {
    type: String,
    default: 'Super Admin',
  },
})

defineEmits(['close', 'submit'])

const initials = computed(() =>
  `${props.form?.prenom?.[0] ?? props.user?.prenom?.[0] ?? ''}${props.form?.nom?.[0] ?? props.user?.nom?.[0] ?? ''}`.toUpperCase() || 'SA'
)

const accountStatus = computed(() => (props.user?.actif ? 'Actif' : 'Inactif'))
</script>
