<template>
  <div class="country-autocomplete">
    <input
      :id="id"
      :value="modelValue"
      :list="resolvedListId"
      type="text"
      :placeholder="placeholder"
      :autocomplete="autocomplete"
      @input="$emit('update:modelValue', $event.target.value)"
    />
    <datalist :id="resolvedListId">
      <option v-for="country in countryNames" :key="country" :value="country" />
    </datalist>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { countryNames } from '@/content/countries'

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  id: {
    type: String,
    default: undefined,
  },
  listId: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: 'Rechercher un pays',
  },
  autocomplete: {
    type: String,
    default: 'country-name',
  },
})

defineEmits(['update:modelValue'])

const resolvedListId = computed(() => props.listId || `country-list-${props.id || 'default'}`)
</script>

<style scoped>
.country-autocomplete {
  width: 100%;
}

.country-autocomplete input {
  width: 100%;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.04);
  color: inherit;
  font: inherit;
  padding: 0.82rem 0.95rem;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.country-autocomplete input:focus {
  outline: none;
  border-color: rgba(201, 168, 76, 0.75);
  box-shadow: 0 0 0 4px rgba(201, 168, 76, 0.12);
}
</style>
