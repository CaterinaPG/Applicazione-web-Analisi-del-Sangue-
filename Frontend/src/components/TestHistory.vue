<template>
  <div class="page">
    <div class="container">
      <div class="header">
        <h1>Storico Risultati Esami</h1>
        <div class="user-info" v-if="currentUser">
          <p><strong>Paziente:</strong> {{ currentUser.nome }} {{ currentUser.cognome }}</p>
          <p>
            <strong>Genere:</strong> {{ currentUser.sesso === 'M' ? 'Maschio' : 'Femmina' }} |
            <strong>Età:</strong> {{ calculateAge(currentUser.data_nascita) }} anni
          </p>
        </div>
      </div>

      <div v-if="error" class="error-message">{{ error }}</div>

      <!-- Filtri -->
      <div class="filters">
        <div class="filter-group">
          <label for="filter-biomarker">Filtra per Biomarker:</label>
          <select v-model="selectedBiomarker" id="filter-biomarker">
            <option value="">Tutti i biomarker</option>
            <option v-for="biomarker in biomarkers" :key="biomarker.biomarker_id" :value="biomarker.biomarker_id">
              {{ biomarker.nome }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label for="filter-date">Data da:</label>
          <input v-model="filterFromDate" type="date" id="filter-date" />
        </div>
        <div class="filter-group">
          <label for="filter-date-to">Data a:</label>
          <input v-model="filterToDate" type="date" id="filter-date-to" />
        </div>
        <button class="btn-filter" @click="resetFilters">Azzera Filtri</button>
      </div>

      <!-- Storico Risultati Raggruppati per Data -->
      <div v-if="filteredAndGroupedResults.length > 0" class="history-section">
        <div v-for="group in filteredAndGroupedResults" :key="group.date" class="date-group">
          <h3 class="date-header">{{ formatDate(group.date) }}</h3>

          <table class="results-table">
            <thead>
              <tr>
                <th>Biomarker</th>
                <th>Valore Misurato</th>
                <th>Unità</th>
                <th>Range Normale</th>
                <th>Esito</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="result in group.results"
                :key="result.result_id"
                :class="`status-${result.esito.toLowerCase()}`"
              >
                <td class="exam-name">{{ getBiomarkerName(result.biomarker_id) }}</td>
                <td class="valore">{{ result.valore_misurato }}</td>
                <td class="unita">{{ getBiomarkerUnit(result.biomarker_id) }}</td>
                <td class="range">{{ getBiomarkerRange(result) }}</td>
                <td class="esito">
                  <span :class="`badge badge-${result.esito.toLowerCase()}`">
                    {{ result.esito }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Nessun Risultato -->
      <div v-else class="no-results">
        <p>Nessun storico disponibile con i filtri selezionati.</p>
      </div>

      <!-- Azioni -->
      <div class="actions">
        <button class="btn-primary" @click="goToDashboard">Torna al Dashboard</button>
        <button class="btn-secondary" @click="logout">Logout</button>
      </div>
    </div>
  </div>
</template>

<script setup name="TestHistory">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
const router = useRouter()
const currentUser = ref(null)
const biomarkers = ref([])
const testHistoryData = ref([])
const selectedBiomarker = ref('')
const filterFromDate = ref('')
const filterToDate = ref('')
const error = ref('')

// Rimuove il token e le informazioni utente dallo storage locale
const clearAuthData = () => {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('auth_user')
}

// Helper fetch che aggiunge il token Authorization alle richieste
const fetchWithAuth = async (path, options = {}) => {
  const token = localStorage.getItem('auth_token')
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
    ...options,
  })
  const body = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new Error(body.error || body.message || 'Errore di rete')
  }
  return body
}

function calculateAge(dataNascita) {
  const oggi = new Date()
  const dataNascitaObj = new Date(dataNascita)
  let age = oggi.getFullYear() - dataNascitaObj.getFullYear()
  const mese = oggi.getMonth() - dataNascitaObj.getMonth()
  if (mese < 0 || (mese === 0 && oggi.getDate() < dataNascitaObj.getDate())) {
    age--
  }
  return age
}

function getBiomarkerName(biomarkerId) {
  const biomarker = biomarkers.value.find((item) => item.biomarker_id === biomarkerId)
  return biomarker ? biomarker.nome : 'Sconosciuto'
}

function getBiomarkerUnit(biomarkerId) {
  const biomarker = biomarkers.value.find((item) => item.biomarker_id === biomarkerId)
  return biomarker ? biomarker.unita_misura : ''
}

function getBiomarkerRange(result) {
  if (result.valore_min === null || result.valore_max === null) {
    return 'N/A'
  }
  return `${result.valore_min} - ${result.valore_max}`
}

function formatDate(dateString) {
  const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
  return new Date(dateString).toLocaleDateString('it-IT', options)
}

const filteredAndGroupedResults = computed(() => {
  const grouped = {}
  const filtered = testHistoryData.value
    .filter((result) => {
      if (selectedBiomarker.value && result.biomarker_id !== parseInt(selectedBiomarker.value)) {
        return false
      }
      if (filterFromDate.value && new Date(result.data_test) < new Date(filterFromDate.value)) {
        return false
      }
      if (filterToDate.value && new Date(result.data_test) > new Date(filterToDate.value)) {
        return false
      }
      return true
    })
    .sort((a, b) => new Date(b.data_test) - new Date(a.data_test))

  filtered.forEach((result) => {
    if (!grouped[result.data_test]) {
      grouped[result.data_test] = []
    }
    grouped[result.data_test].push(result)
  })

  return Object.entries(grouped).map(([date, results]) => ({ date, results }))
})

// Carica il profilo utente, la lista biomarker e lo storico dei risultati
async function loadPageData() {
  error.value = ''
  try {
    currentUser.value = await fetchWithAuth('/api/profile')
    biomarkers.value = await fetchWithAuth('/api/biomarkers')
    await loadHistory()
  } catch (err) {
    if (err.message === 'Access token required' || err.message === 'Invalid token') {
      clearAuthData()
      router.push('/login')
    } else {
      error.value = err.message || 'Errore durante il caricamento dello storico.'
    }
  }
}

async function loadHistory() {
  error.value = ''
  try {
    const query = []
    if (selectedBiomarker.value) query.push(`biomarker_id=${encodeURIComponent(selectedBiomarker.value)}`)
    if (filterFromDate.value) query.push(`from_date=${encodeURIComponent(filterFromDate.value)}`)
    if (filterToDate.value) query.push(`to_date=${encodeURIComponent(filterToDate.value)}`)
    const queryString = query.length ? `?${query.join('&')}` : ''
    testHistoryData.value = await fetchWithAuth(`/api/test-history${queryString}`)
  } catch (err) {
    if (err.message === 'Access token required' || err.message === 'Invalid token') {
      clearAuthData()
      router.push('/login')
    } else {
      error.value = err.message || 'Errore durante il caricamento dello storico.'
    }
  }
}

function resetFilters() {
  selectedBiomarker.value = ''
  filterFromDate.value = ''
  filterToDate.value = ''
  loadHistory()
}

function goToDashboard() {
  router.push('/dashboard')
}

function logout() {
  clearAuthData()
  router.push('/login')
}

onMounted(loadPageData)
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: linear-gradient(180deg, #fff 0%, #f9f9f9 100%);
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  padding: 30px;
}

.header {
  margin-bottom: 30px;
  border-bottom: 2px solid #e0e0e0;
  padding-bottom: 20px;
}

.header h1 {
  margin: 0 0 15px 0;
  color: #b00020;
  font-size: 2rem;
  font-weight: 700;
}

  .error-message {
    margin: 20px 0 0;
    padding: 14px 18px;
    border-radius: 10px;
    color: #b00020;
    background: #ffe7e9;
    border: 1px solid #f5c2c7;
  }
.user-info p {
  margin: 5px 0;
}

/* Filtri */
.filters {
  background: #f5f5f5;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 25px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 15px;
  align-items: end;
}

.filter-group {
  display: flex;
  flex-direction: column;
}

.filter-group label {
  font-weight: 600;
  margin-bottom: 5px;
  color: #333;
  font-size: 0.9rem;
}

.filter-group input,
.filter-group select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
  font-family: inherit;
}

.filter-group input:focus,
.filter-group select:focus {
  outline: none;
  border-color: #b00020;
  box-shadow: 0 0 0 2px rgba(176, 0, 32, 0.1);
}

.btn-filter {
  padding: 8px 16px;
  background: #b00020;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.9rem;
  transition: background 0.3s;
}

.btn-filter:hover {
  background: #8a0018;
}

/* Storico Risultati */
.history-section {
  margin-bottom: 30px;
}

.date-group {
  margin-bottom: 25px;
}

.date-header {
  color: #b00020;
  font-size: 1.1rem;
  margin: 20px 0 10px 0;
  padding-bottom: 10px;
  border-bottom: 2px solid #e0e0e0;
}

.results-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 15px;
  font-size: 0.95rem;
}

.results-table thead {
  background: #f5f5f5;
}

.results-table th {
  padding: 12px;
  text-align: left;
  font-weight: 600;
  color: #333;
  border-bottom: 2px solid #e0e0e0;
}

.results-table td {
  padding: 12px;
  border-bottom: 1px solid #f0f0f0;
}

.results-table tbody tr:hover {
  background: #f9f9f9;
}

.exam-name {
  font-weight: 600;
  color: #333;
}

.valore {
  font-weight: 600;
  color: #b00020;
}

.unita {
  color: #666;
  font-size: 0.9rem;
}

.range {
  color: #999;
  font-size: 0.85rem;
}

.esito {
  text-align: center;
}

/* Badge per gli esiti */
.badge {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: uppercase;
}

.badge-basso {
  background: #ffe0e0;
  color: #b00020;
}

.badge-normale {
  background: #e0f7e0;
  color: #2e7d32;
}

.badge-alto {
  background: #fff3e0;
  color: #e65100;
}

/* No Results */
.no-results {
  text-align: center;
  padding: 40px 20px;
  color: #999;
  font-size: 1.1rem;
}

/* Azioni */
.actions {
  display: flex;
  gap: 10px;
  justify-content: center;
  margin-top: 30px;
  flex-wrap: wrap;
}

.btn-primary,
.btn-secondary {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-primary {
  background: #b00020;
  color: white;
}

.btn-primary:hover {
  background: #8a0018;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(176, 0, 32, 0.3);
}

.btn-secondary {
  background: #f0f0f0;
  color: #333;
  border: 1px solid #ddd;
}

.btn-secondary:hover {
  background: #e0e0e0;
}

/* Responsive */
@media (max-width: 768px) {
  .container {
    padding: 20px;
  }

  .header h1 {
    font-size: 1.5rem;
  }

  .filters {
    grid-template-columns: 1fr;
  }

  .results-table {
    font-size: 0.85rem;
  }

  .results-table th,
  .results-table td {
    padding: 8px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }
}
</style>
