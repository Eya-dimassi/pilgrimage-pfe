<template>
  <div class="phone-field">
    <select :id="selectId" v-model="selectedDialCode" class="phone-select">
      <option v-for="country in countries" :key="`${country.code}-${country.dialCode}`" :value="country.dialCode">
        {{ country.name }} ({{ country.dialCode }})
      </option>
    </select>

    <input
      :id="id"
      v-model="localNumber"
      class="phone-input"
      type="tel"
      :placeholder="placeholder"
      :autocomplete="autocomplete"
      inputmode="tel"
    />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { countries } from '@/content/countries'

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  id: {
    type: String,
    default: undefined,
  },
  selectId: {
    type: String,
    default: undefined,
  },
  placeholder: {
    type: String,
    default: '20 123 456',
  },
  autocomplete: {
    type: String,
    default: 'tel-national',
  },
  defaultDialCode: {
    type: String,
    default: '+216',
  },
})

const emit = defineEmits(['update:modelValue'])

const selectedDialCode = ref(props.defaultDialCode)
const localNumber = ref('')

function splitPhoneNumber(value) {
  const normalized = String(value || '').trim().replace(/\s+/g, ' ')

  if (!normalized) {
    return {
      dialCode: props.defaultDialCode,
      local: '',
    }
  }

  const matchedCountry = [...countries]
    .sort((left, right) => right.dialCode.length - left.dialCode.length)
    .find((country) => normalized.startsWith(country.dialCode))

  if (!matchedCountry) {
    return {
      dialCode: props.defaultDialCode,
      local: normalized,
    }
  }

  return {
    dialCode: matchedCountry.dialCode,
    local: normalized.slice(matchedCountry.dialCode.length).trim().replace(/^[-\s]+/, ''),
  }
}

function emitCombinedValue() {
  const normalizedLocalNumber = localNumber.value.trim().replace(/\s+/g, ' ')

  emit(
    'update:modelValue',
    normalizedLocalNumber ? `${selectedDialCode.value} ${normalizedLocalNumber}` : '',
  )
}

watch(
  () => props.modelValue,
  (nextValue) => {
    const parsed = splitPhoneNumber(nextValue)

    selectedDialCode.value = parsed.dialCode
    localNumber.value = parsed.local
  },
  { immediate: true },
)

watch([selectedDialCode, localNumber], emitCombinedValue)
</script>

<style scoped>
.phone-field {
  display: grid;
  grid-template-columns: minmax(150px, 0.95fr) minmax(0, 1.35fr);
  gap: 0.75rem;
  align-items: stretch;
}

.phone-select,
.phone-input {
  width: 100%;
  min-height: 56px;
  border: 1px solid rgba(201, 168, 76, 0.2);
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.03);
  color: inherit;
  font: inherit;
  padding: 0.82rem 0.95rem;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.phone-select:focus,
.phone-input:focus {
  outline: none;
  border-color: rgba(201, 168, 76, 0.68);
  box-shadow: 0 0 0 3px rgba(201, 168, 76, 0.1);
}

.phone-select {
  appearance: none;
}

.phone-select:hover,
.phone-input:hover {
  border-color: rgba(201, 168, 76, 0.3);
}

@media (max-width: 640px) {
  .phone-field {
    grid-template-columns: 1fr;
  }
}
</style>
