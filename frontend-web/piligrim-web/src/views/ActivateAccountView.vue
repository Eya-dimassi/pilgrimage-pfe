<template>
  <div class="min-h-screen bg-gradient-to-br from-[#0d0f1a] to-[#1b1e2e] flex items-center justify-center p-6">
    <div class="max-w-md w-full">
      <!-- Logo -->
      <div class="text-center mb-8">
        <div class="text-5xl mb-4">🕌</div>
        <h1 class="text-3xl font-bold text-white">SmartHajj</h1>
        <p class="text-gray-400 mt-2">Activation de votre compte Guide</p>
      </div>

      <!-- Card -->
      <div class="bg-[#1b1e2e] rounded-2xl p-8 border border-gray-800">
        <!-- Loading -->
        <div v-if="loading" class="text-center py-12">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-green-500 mx-auto mb-4"></div>
          <p class="text-gray-400">Vérification du lien d'activation...</p>
        </div>

        <!-- Erreur Token -->
        <div v-else-if="tokenError" class="text-center py-8">
          <div class="text-6xl mb-4">❌</div>
          <h2 class="text-2xl font-bold text-red-400 mb-4">Lien invalide ou expiré</h2>
          <p class="text-gray-400 mb-6">{{ tokenError }}</p>
          <router-link 
            to="/login" 
            class="inline-block px-6 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium transition"
          >
            Retour à la connexion
          </router-link>
        </div>

        <!-- Formulaire Activation -->
        <div v-else-if="!success">
          <div class="text-center mb-6">
            <div class="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <h2 class="text-2xl font-bold text-white">Bienvenue {{ guideName }} !</h2>
            <p class="text-gray-400 mt-2">Définissez votre mot de passe pour activer votre compte</p>
          </div>

          <form @submit.prevent="handleSubmit" class="space-y-6">
            <!-- Email (lecture seule) -->
            <div>
              <label class="block text-sm font-semibold text-gray-300 mb-2">Email</label>
              <div class="px-4 py-3 rounded-lg bg-gray-800 border border-gray-700 text-gray-400">
                {{ guideEmail }}
              </div>
            </div>

            <!-- Mot de passe -->
            <div>
              <label class="block text-sm font-semibold text-gray-300 mb-2">Mot de passe *</label>
              <div class="relative">
                <input 
                  v-model="formData.password" 
                  :type="showPassword ? 'text' : 'password'"
                  required
                  minlength="8"
                  class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-green-500 pr-12"
                  placeholder="Minimum 8 caractères"
                  :class="{ 'border-red-500': errors.password }"
                >
                <button 
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white transition"
                >
                  <svg v-if="!showPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                  </svg>
                  <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"></path>
                  </svg>
                </button>
              </div>
              <p v-if="errors.password" class="mt-1 text-sm text-red-400">{{ errors.password }}</p>
              
              <!-- Password strength -->
              <div v-if="formData.password" class="mt-2">
                <div class="flex gap-1 mb-1">
                  <div class="h-1 flex-1 rounded" :class="passwordStrength >= 1 ? 'bg-red-500' : 'bg-gray-700'"></div>
                  <div class="h-1 flex-1 rounded" :class="passwordStrength >= 2 ? 'bg-orange-500' : 'bg-gray-700'"></div>
                  <div class="h-1 flex-1 rounded" :class="passwordStrength >= 3 ? 'bg-yellow-500' : 'bg-gray-700'"></div>
                  <div class="h-1 flex-1 rounded" :class="passwordStrength >= 4 ? 'bg-green-500' : 'bg-gray-700'"></div>
                </div>
                <p class="text-xs" :class="{
                  'text-red-400': passwordStrength < 2,
                  'text-orange-400': passwordStrength === 2,
                  'text-yellow-400': passwordStrength === 3,
                  'text-green-400': passwordStrength >= 4
                }">
                  {{ passwordStrengthText }}
                </p>
              </div>
            </div>

            <!-- Confirmation mot de passe -->
            <div>
              <label class="block text-sm font-semibold text-gray-300 mb-2">Confirmer le mot de passe *</label>
              <div class="relative">
                <input 
                  v-model="formData.confirmPassword" 
                  :type="showConfirmPassword ? 'text' : 'password'"
                  required
                  class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-green-500 pr-12"
                  placeholder="Confirmez votre mot de passe"
                  :class="{ 'border-red-500': errors.confirmPassword }"
                >
                <button 
                  type="button"
                  @click="showConfirmPassword = !showConfirmPassword"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white transition"
                >
                  <svg v-if="!showConfirmPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                  </svg>
                  <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"></path>
                  </svg>
                </button>
              </div>
              <p v-if="errors.confirmPassword" class="mt-1 text-sm text-red-400">{{ errors.confirmPassword }}</p>
            </div>

            <!-- Exigences -->
            <div class="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4">
              <p class="text-sm font-semibold text-blue-400 mb-2">Exigences du mot de passe :</p>
              <ul class="text-sm text-gray-300 space-y-1">
                <li class="flex items-center gap-2">
                  <svg class="w-4 h-4" :class="formData.password.length >= 8 ? 'text-green-400' : 'text-gray-500'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Au moins 8 caractères
                </li>
                <li class="flex items-center gap-2">
                  <svg class="w-4 h-4" :class="/[A-Z]/.test(formData.password) ? 'text-green-400' : 'text-gray-500'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Une lettre majuscule
                </li>
                <li class="flex items-center gap-2">
                  <svg class="w-4 h-4" :class="/[0-9]/.test(formData.password) ? 'text-green-400' : 'text-gray-500'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Un chiffre
                </li>
              </ul>
            </div>

            <!-- Erreur générale -->
            <div v-if="error" class="bg-red-500/10 border border-red-500/30 rounded-lg p-4">
              <p class="text-sm text-red-400">{{ error }}</p>
            </div>

            <!-- Bouton Submit -->
            <button 
              type="submit"
              :disabled="submitting || !isFormValid"
              class="w-full px-6 py-4 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white rounded-lg font-semibold transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <svg v-if="submitting" class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span v-if="submitting">Activation en cours...</span>
              <span v-else>Activer mon compte</span>
            </button>
          </form>
        </div>

        <!-- Succès -->
        <div v-else class="text-center py-8">
          <div class="text-6xl mb-4">✅</div>
          <h2 class="text-2xl font-bold text-green-400 mb-4">Compte activé avec succès !</h2>
          <p class="text-gray-400 mb-6">Vous pouvez maintenant vous connecter avec vos identifiants.</p>
          <router-link 
            to="/login" 
            class="inline-block px-6 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium transition"
          >
            Se connecter
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import axios from 'axios';

const route = useRoute();
const router = useRouter();

// État
const loading = ref(true);
const tokenError = ref('');
const submitting = ref(false);
const success = ref(false);
const error = ref('');
const guideName = ref('');
const guideEmail = ref('');
const showPassword = ref(false);
const showConfirmPassword = ref(false);

const formData = ref({
  password: '',
  confirmPassword: ''
});

const errors = ref({
  password: '',
  confirmPassword: ''
});

// Calculer la force du mot de passe
const passwordStrength = computed(() => {
  const password = formData.value.password;
  let strength = 0;
  
  if (password.length >= 8) strength++;
  if (password.length >= 12) strength++;
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) strength++;
  if (/[0-9]/.test(password)) strength++;
  if (/[^A-Za-z0-9]/.test(password)) strength++;
  
  return Math.min(strength, 4);
});

const passwordStrengthText = computed(() => {
  const strength = passwordStrength.value;
  if (strength === 0) return 'Très faible';
  if (strength === 1) return 'Faible';
  if (strength === 2) return 'Moyen';
  if (strength === 3) return 'Fort';
  return 'Très fort';
});

// Validation du formulaire
const isFormValid = computed(() => {
  return formData.value.password.length >= 8 && 
         formData.value.password === formData.value.confirmPassword &&
         /[A-Z]/.test(formData.value.password) &&
         /[0-9]/.test(formData.value.password);
});

// Vérifier le token au chargement
onMounted(async () => {
  const token = route.query.token;
  
  if (!token) {
    tokenError.value = 'Aucun token d\'activation fourni.';
    loading.value = false;
    return;
  }
  
  try {
    // Vérifier la validité du token
    const response = await axios.post(
      `${import.meta.env.VITE_API_URL || 'http://localhost:3000'}/auth/verify-activation-token`,
      { token }
    );
    console.log('✅ Réponse reçue:', response.data);
    guideName.value = response.data.nom;
    guideEmail.value = response.data.email;
    loading.value = false;
  } catch (err) {
    console.error('Erreur vérification token:', err.response?.data);
    tokenError.value = err.response?.data?.message || 'Le lien d\'activation est invalide ou a expiré.';
    loading.value = false;
  }
});

// Validation en temps réel
const validatePassword = () => {
  errors.value.password = '';
  
  if (formData.value.password.length > 0 && formData.value.password.length < 8) {
    errors.value.password = 'Le mot de passe doit contenir au moins 8 caractères';
  } else if (formData.value.password.length >= 8) {
    if (!/[A-Z]/.test(formData.value.password)) {
      errors.value.password = 'Le mot de passe doit contenir au moins une majuscule';
    } else if (!/[0-9]/.test(formData.value.password)) {
      errors.value.password = 'Le mot de passe doit contenir au moins un chiffre';
    }
  }
};

const validateConfirmPassword = () => {
  errors.value.confirmPassword = '';
  
  if (formData.value.confirmPassword && formData.value.password !== formData.value.confirmPassword) {
    errors.value.confirmPassword = 'Les mots de passe ne correspondent pas';
  }
};

// Soumettre le formulaire
const handleSubmit = async () => {
  // Valider
  validatePassword();
  validateConfirmPassword();
  
  if (errors.value.password || errors.value.confirmPassword) {
    return;
  }
  
  submitting.value = true;
  error.value = '';
  
  try {
    const token = route.query.token;
    
    await axios.post(
      `${import.meta.env.VITE_API_URL|| 'http://localhost:3000'}/auth/set-password`,
      {
        token,
        newPassword: formData.value.password
      }
    );
    
    success.value = true;
  } catch (err) {
    console.error('Erreur activation:', err);
    error.value = err.response?.data?.message || 'Une erreur est survenue lors de l\'activation du compte.';
  } finally {
    submitting.value = false;
  }
};
</script>