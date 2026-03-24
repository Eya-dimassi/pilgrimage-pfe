import { computed, ref, unref } from 'vue'

export function useSearchFilter(options) {
  const search = ref('')
  const activeFilter = ref(options.defaultFilterKey ?? 'all')

  const filters = computed(() => {
    const items = unref(options.items) ?? []
    return (unref(options.filterConfigs) ?? []).map((filter) => ({
      key: filter.key,
      label: filter.label,
      count: items.filter((item) => filter.predicate(item)).length,
    }))
  })

  const filtered = computed(() => {
    const items = unref(options.items) ?? []
    const filterConfigs = unref(options.filterConfigs) ?? []
    const selectedFilter = filterConfigs.find((filter) => filter.key === activeFilter.value)
    const predicate = selectedFilter?.predicate ?? (() => true)
    const normalizedQuery = search.value.trim().toLowerCase()

    return items.filter((item) => {
      if (!predicate(item)) return false
      if (!normalizedQuery) return true
      return options.searchableText(item).toLowerCase().includes(normalizedQuery)
    })
  })

  function resetFilters() {
    activeFilter.value = options.defaultFilterKey ?? 'all'
    search.value = ''
  }

  return {
    search,
    activeFilter,
    filters,
    filtered,
    resetFilters,
  }
}
