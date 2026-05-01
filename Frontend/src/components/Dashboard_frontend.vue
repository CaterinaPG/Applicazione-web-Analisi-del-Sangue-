<script setup>
import { reactive, watch, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
const router = useRouter()

const currentUser = ref(JSON.parse(localStorage.getItem('auth_user') || 'null'))
const error = ref('')
const success = ref('')
const loading = ref(false)

const clearAuthData = () => {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('auth_user')
}

// Funzione helper per eseguire fetch autenticati verso il backend
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

// Stato reattivo per tutti i campi del form del dashboard
const bloodData = reactive({
  rbc: '',
  hb: '',
  ht: '',
  mcv: '',
  mch: '',
  mchc: '',
  rdw: '',
  wbc: '',
  neutrophils: '',
  lymphocytes: '',
  monocytes: '',
  eosinophils: '',
  basophils: '',
  neutrophils_abs: '',
  lymphocytes_abs: '',
  monocytes_abs: '',
  eosinophils_abs: '',
  basophils_abs: '',
  plt: '',
  glucose: '',
  hba1c: '',
  totalCholesterol: '',
  ldlCholesterol: '',
  hdlCholesterol: '',
  triglycerides: '',
  pcr: '',
  sideremia: '',
  ferritin: '',
})

// Mappa dei campi del form ai corrispondenti biomarker_id del database
const biomarkerMap = {
  rbc: 1,
  hb: 2,
  ht: 3,
  mcv: 4,
  mch: 5,
  mchc: 6,
  rdw: 7,
  wbc: 8,
  neutrophils: 9,
  lymphocytes: 11,
  monocytes: 13,
  eosinophils: 15,
  basophils: 17,
  neutrophils_abs: 10,
  lymphocytes_abs: 12,
  monocytes_abs: 14,
  eosinophils_abs: 16,
  basophils_abs: 18,
  plt: 19,
  glucose: 20,
  hba1c: 21,
  totalCholesterol: 22,
  ldlCholesterol: 23,
  hdlCholesterol: 24,
  triglycerides: 25,
  pcr: 26,
  sideremia: 27,
  ferritin: 28,
}

const calculatedCholesterol = ref(null)
const userChangedField = ref(null)

// Calcola automaticamente uno dei valori del profilo lipidico, se sono inseriti almeno 3 parametri
const calculateCholesterol = () => {
  const total = parseFloat(bloodData.totalCholesterol) || 0
  const ldl = parseFloat(bloodData.ldlCholesterol) || 0
  const hdl = parseFloat(bloodData.hdlCholesterol) || 0
  const tg = parseFloat(bloodData.triglycerides) || 0

  const filledCount = [total, ldl, hdl, tg].filter((v) => v > 0).length

  if (filledCount >= 3) {
    if (total === 0 && ldl > 0 && hdl > 0 && tg > 0) {
      bloodData.totalCholesterol = (ldl + hdl + tg / 5).toFixed(2)
      calculatedCholesterol.value = 'total'
    } else if (ldl === 0 && total > 0 && hdl > 0 && tg > 0) {
      bloodData.ldlCholesterol = (total - hdl - tg / 5).toFixed(2)
      calculatedCholesterol.value = 'ldl'
    } else if (hdl === 0 && total > 0 && ldl > 0 && tg > 0) {
      bloodData.hdlCholesterol = (total - ldl - tg / 5).toFixed(2)
      calculatedCholesterol.value = 'hdl'
    } else if (tg === 0 && total > 0 && ldl > 0 && hdl > 0) {
      bloodData.triglycerides = ((total - ldl - hdl) * 5).toFixed(2)
      calculatedCholesterol.value = 'tg'
    }
  } else {
    calculatedCholesterol.value = null
  }
}

watch(
  () => bloodData.totalCholesterol,
  () => {
    userChangedField.value = 'total'
    calculateCholesterol()
  },
)

watch(
  () => bloodData.ldlCholesterol,
  () => {
    userChangedField.value = 'ldl'
    calculateCholesterol()
  },
)

watch(
  () => bloodData.hdlCholesterol,
  () => {
    userChangedField.value = 'hdl'
    calculateCholesterol()
  },
)

watch(
  () => bloodData.triglycerides,
  () => {
    userChangedField.value = 'tg'
    calculateCholesterol()
  },
)

const submitForm = async () => {
  error.value = ''
  success.value = ''

  const results = Object.entries(biomarkerMap)
    .map(([field, biomarker_id]) => {
      const value = bloodData[field]
      const parsed = parseFloat(value)
      return !Number.isNaN(parsed) && value !== '' ? { biomarker_id, valore_misurato: parsed } : null
    })
    .filter(Boolean)

  if (results.length === 0) {
    error.value = 'Inserisci almeno un valore numerico prima di inviare.'
    return
  }

  try {
    loading.value = true
    await fetchWithAuth('/api/test-results', {
      method: 'POST',
      body: JSON.stringify({ results, testDate: new Date().toISOString().split('T')[0] }),
    })
    success.value = 'Risultati inviati con successo.'
    setTimeout(() => router.push('/results'), 800)
  } catch (err) {
    if (err.message === 'Access token required' || err.message === 'Invalid token') {
      clearAuthData()
      router.push('/login')
    } else {
      error.value = err.message || "Errore durante l'invio dei risultati."
    }
  } finally {
    loading.value = false
  }
}

// Reset del form e dei messaggi di stato
const resetForm = () => {
  Object.keys(bloodData).forEach((key) => {
    bloodData[key] = ''
  })
  calculatedCholesterol.value = null
  userChangedField.value = null
  error.value = ''
  success.value = ''
}

// Controlla che l'utente sia autenticato e recupera il profilo dal backend
const ensureAuthenticated = async () => {
  if (!currentUser.value) {
    try {
      currentUser.value = await fetchWithAuth('/api/profile')
      localStorage.setItem('auth_user', JSON.stringify(currentUser.value))
    } catch {
      clearAuthData()
      router.push('/login')
    }
  }
}

onMounted(ensureAuthenticated)
</script>

<template>
  <div class="blood-input-container">
    <div class="header">
      <h1>Dashboard Analisi del Sangue</h1>
      <p class="subtitle">Inserisci i tuoi parametri ematici per valutare il tuo stato di salute</p>
    </div>

    <form @submit.prevent="submitForm" class="blood-form">
      <!-- SEZIONE 1: EMOCROMO -->
      <section class="form-section">
        <h2 class="section-title">1. Emocromo (Esame Citometrico)</h2>

        <!-- SOTTOSEZIONE: GLOBULI ROSSI -->
        <div class="subsection">
          <h3 class="subsection-title">Globuli Rossi</h3>
          <div class="parameters-grid">
            <!-- Globuli Rossi -->
            <div class="param-group">
              <label for="rbc">Globuli Rossi (RBC)</label>
              <input
                id="rbc"
                v-model="bloodData.rbc"
                type="number"
                placeholder="es. 4.5"
                step="0.01"
              />
              <span class="unit">10⁶/µL</span>
            </div>

            <!-- Piastrine -->
            <div class="param-group">
              <label for="plt">Piastrine (PLT)</label>
              <input
                id="plt"
                v-model="bloodData.plt"
                type="number"
                placeholder="es. 250"
                step="1"
              />
              <span class="unit">10³/µL</span>
            </div>
          </div>
        </div>

        <!-- SOTTOSEZIONE: GLOBULI BIANCHI -->
        <div class="subsection">
          <h3 class="subsection-title">Globuli Bianchi</h3>
          <div class="parameters-grid">
            <!-- Globuli Bianchi Totali -->
            <div class="param-group">
              <label for="wbc">Globuli Bianchi Totali (WBC)</label>
              <input
                id="wbc"
                v-model="bloodData.wbc"
                type="number"
                placeholder="es. 7.2"
                step="0.1"
              />
              <span class="unit">10³/µL</span>
            </div>

            <!-- Neutrofili -->
            <div class="param-group">
              <label for="neutrophils">Neutrofili</label>
              <input
                id="neutrophils"
                v-model="bloodData.neutrophils"
                type="number"
                placeholder="es. 60"
                step="0.1"
              />
              <span class="unit">%</span>
            </div>

            <!-- Linfociti -->
            <div class="param-group">
              <label for="lymphocytes">Linfociti</label>
              <input
                id="lymphocytes"
                v-model="bloodData.lymphocytes"
                type="number"
                placeholder="es. 25"
                step="0.1"
              />
              <span class="unit">%</span>
            </div>

            <!-- Monociti -->
            <div class="param-group">
              <label for="monocytes">Monociti</label>
              <input
                id="monocytes"
                v-model="bloodData.monocytes"
                type="number"
                placeholder="es. 8"
                step="0.1"
              />
              <span class="unit">%</span>
            </div>

            <!-- Eosinofili -->
            <div class="param-group">
              <label for="eosinophils">Eosinofili</label>
              <input
                id="eosinophils"
                v-model="bloodData.eosinophils"
                type="number"
                placeholder="es. 3"
                step="0.1"
              />
              <span class="unit">%</span>
            </div>

            <!-- Basofili -->
            <div class="param-group">
              <label for="basophils">Basofili</label>
              <input
                id="basophils"
                v-model="bloodData.basophils"
                type="number"
                placeholder="es. 0.5"
                step="0.1"
              />
              <span class="unit">%</span>
            </div>

            <!-- Neutrofili Assoluti -->
            <div class="param-group">
              <label for="neutrophils_abs">Neutrofili Assoluti</label>
              <input
                id="neutrophils_abs"
                v-model="bloodData.neutrophils_abs"
                type="number"
                placeholder="es. 4.0"
                step="0.1"
              />
              <span class="unit">10³/µL</span>
            </div>

            <!-- Linfociti Assoluti -->
            <div class="param-group">
              <label for="lymphocytes_abs">Linfociti Assoluti</label>
              <input
                id="lymphocytes_abs"
                v-model="bloodData.lymphocytes_abs"
                type="number"
                placeholder="es. 1.8"
                step="0.1"
              />
              <span class="unit">10³/µL</span>
            </div>

            <!-- Monociti Assoluti -->
            <div class="param-group">
              <label for="monocytes_abs">Monociti Assoluti</label>
              <input
                id="monocytes_abs"
                v-model="bloodData.monocytes_abs"
                type="number"
                placeholder="es. 0.6"
                step="0.1"
              />
              <span class="unit">10³/µL</span>
            </div>

            <!-- Eosinofili Assoluti -->
            <div class="param-group">
              <label for="eosinophils_abs">Eosinofili Assoluti</label>
              <input
                id="eosinophils_abs"
                v-model="bloodData.eosinophils_abs"
                type="number"
                placeholder="es. 0.2"
                step="0.1"
              />
              <span class="unit">10³/µL</span>
            </div>

            <!-- Basofili Assoluti -->
            <div class="param-group">
              <label for="basophils_abs">Basofili Assoluti</label>
              <input
                id="basophils_abs"
                v-model="bloodData.basophils_abs"
                type="number"
                placeholder="es. 0.04"
                step="0.01"
              />
              <span class="unit">10³/µL</span>
            </div>
          </div>
        </div>

        <!-- SOTTOSEZIONE: EMOGLOBINA E PARAMETRI CORRELATI -->
        <div class="subsection">
          <h3 class="subsection-title">Emoglobina e Parametri Correlati</h3>
          <div class="parameters-grid">
            <!-- Emoglobina -->
            <div class="param-group">
              <label for="hb">Emoglobina (Hb)</label>
              <input
                id="hb"
                v-model="bloodData.hb"
                type="number"
                placeholder="es. 14.5"
                step="0.1"
              />
              <span class="unit">g/dL</span>
            </div>

            <!-- Ematocrito -->
            <div class="param-group">
              <label for="ht">Ematocrito (Ht)</label>
              <input id="ht" v-model="bloodData.ht" type="number" placeholder="es. 43" step="0.1" />
              <span class="unit">%</span>
            </div>

            <!-- Volume Corpuscolare Medio -->
            <div class="param-group">
              <label for="mcv">Volume Corpuscolare Medio (MCV)</label>
              <input
                id="mcv"
                v-model="bloodData.mcv"
                type="number"
                placeholder="es. 87"
                step="0.1"
              />
              <span class="unit">fL</span>
            </div>

            <!-- Contenuto Medio di Hb -->
            <div class="param-group">
              <label for="mch">Contenuto Medio di Hb (MCH)</label>
              <input
                id="mch"
                v-model="bloodData.mch"
                type="number"
                placeholder="es. 29"
                step="0.1"
              />
              <span class="unit">pg</span>
            </div>

            <!-- Concentrazione Media di Hb -->
            <div class="param-group">
              <label for="mchc">Conc. Media di Hb (MCHC)</label>
              <input
                id="mchc"
                v-model="bloodData.mchc"
                type="number"
                placeholder="es. 33.5"
                step="0.1"
              />
              <span class="unit">g/dL</span>
            </div>

            <!-- RDW -->
            <div class="param-group">
              <label for="rdw">Ampiezza Distribuzione (RDW)</label>
              <input
                id="rdw"
                v-model="bloodData.rdw"
                type="number"
                placeholder="es. 12.5"
                step="0.1"
              />
              <span class="unit">%</span>
            </div>
          </div>
        </div>
      </section>

      <!-- SEZIONE 2: ASSETTO METABOLICO E GLICEMICO -->
      <section class="form-section">
        <h2 class="section-title">2. Assetto Metabolico e Glicemico</h2>

        <!-- SOTTOSEZIONE: GLICEMIA -->
        <div class="subsection">
          <h3 class="subsection-title">Glicemia</h3>
          <div class="parameters-grid">
            <!-- Glicemia -->
            <div class="param-group">
              <label for="glucose">Glicemia</label>
              <input
                id="glucose"
                v-model="bloodData.glucose"
                type="number"
                placeholder="es. 95"
                step="0.1"
              />
              <span class="unit">mg/dL</span>
            </div>

            <!-- Emoglobina Glicata -->
            <div class="param-group">
              <label for="hba1c">Emoglobina Glicata (HbA1c)</label>
              <input
                id="hba1c"
                v-model="bloodData.hba1c"
                type="number"
                placeholder="es. 35"
                step="1"
              />
              <span class="unit">mmol/mol</span>
            </div>
          </div>
        </div>

        <!-- SOTTOSEZIONE: COLESTEROLO -->
        <div class="subsection">
          <h3 class="subsection-title">Colesterolo e Lipidi</h3>
          <p class="subsection-info">
            💡 Inserisci 3 parametri e il quarto sarà calcolato automaticamente
          </p>
          <div class="parameters-grid">
            <!-- Colesterolo Totale -->
            <div
              class="param-group"
              :class="{ 'is-calculated': calculatedCholesterol === 'total' }"
            >
              <label for="totalCholesterol">
                Colesterolo Totale
                <span v-if="calculatedCholesterol === 'total'" class="calculated-badge"
                  >📊 Calcolato</span
                >
              </label>
              <input
                id="totalCholesterol"
                v-model="bloodData.totalCholesterol"
                type="number"
                placeholder="es. 200"
                step="0.1"
                :readonly="calculatedCholesterol === 'total'"
              />
              <span class="unit">mg/dL</span>
            </div>

            <!-- Colesterolo LDL -->
            <div class="param-group" :class="{ 'is-calculated': calculatedCholesterol === 'ldl' }">
              <label for="ldlCholesterol">
                Colesterolo LDL ("Cattivo")
                <span v-if="calculatedCholesterol === 'ldl'" class="calculated-badge"
                  >📊 Calcolato</span
                >
              </label>
              <input
                id="ldlCholesterol"
                v-model="bloodData.ldlCholesterol"
                type="number"
                placeholder="es. 130"
                step="0.1"
                :readonly="calculatedCholesterol === 'ldl'"
              />
              <span class="unit">mg/dL</span>
            </div>

            <!-- Colesterolo HDL -->
            <div class="param-group" :class="{ 'is-calculated': calculatedCholesterol === 'hdl' }">
              <label for="hdlCholesterol">
                Colesterolo HDL ("Buono")
                <span v-if="calculatedCholesterol === 'hdl'" class="calculated-badge"
                  >📊 Calcolato</span
                >
              </label>
              <input
                id="hdlCholesterol"
                v-model="bloodData.hdlCholesterol"
                type="number"
                placeholder="es. 50"
                step="0.1"
                :readonly="calculatedCholesterol === 'hdl'"
              />
              <span class="unit">mg/dL</span>
            </div>

            <!-- Trigliceridi -->
            <div class="param-group" :class="{ 'is-calculated': calculatedCholesterol === 'tg' }">
              <label for="triglycerides">
                Trigliceridi
                <span v-if="calculatedCholesterol === 'tg'" class="calculated-badge"
                  >📊 Calcolato</span
                >
              </label>
              <input
                id="triglycerides"
                v-model="bloodData.triglycerides"
                type="number"
                placeholder="es. 100"
                step="0.1"
                :readonly="calculatedCholesterol === 'tg'"
              />
              <span class="unit">mg/dL</span>
            </div>
          </div>
        </div>
      </section>

      <!-- SEZIONE 3: INFIAMMAZIONE E METABOLISMO DEL FERRO -->
      <section class="form-section">
        <h2 class="section-title">3. Infiammazione e Metabolismo del Ferro</h2>
        <div class="parameters-grid">
          <!-- PCR -->
          <div class="param-group">
            <label for="pcr">PCR (Proteina C Reattiva)</label>
            <input
              id="pcr"
              v-model="bloodData.pcr"
              type="number"
              placeholder="es. 0.5"
              step="0.01"
            />
            <span class="unit">mg/L</span>
          </div>

          <!-- Sideremia -->
          <div class="param-group">
            <label for="sideremia">Sideremia (Ferro)</label>
            <input
              id="sideremia"
              v-model="bloodData.sideremia"
              type="number"
              placeholder="es. 100"
              step="0.1"
            />
            <span class="unit">µg/dL</span>
          </div>

          <!-- Ferritina -->
          <div class="param-group">
            <label for="ferritin">Ferritina</label>
            <input
              id="ferritin"
              v-model="bloodData.ferritin"
              type="number"
              placeholder="es. 120"
              step="0.1"
            />
            <span class="unit">ng/mL</span>
          </div>
        </div>
      </section>

      <!-- BOTTONI AZIONI -->
      <div class="status-messages">
        <p v-if="error" class="error-message">{{ error }}</p>
        <p v-if="success" class="success-message">{{ success }}</p>
      </div>
      <div class="action-buttons">
        <button type="submit" class="btn btn-primary" :disabled="loading">
          {{ loading ? 'Invio in corso...' : 'Analizza Risultati' }}
        </button>
        <button type="button" class="btn btn-secondary" @click="resetForm" :disabled="loading">
          Cancella Campi
        </button>
      </div>
    </form>
  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
}

.blood-input-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
  background: white;
  min-height: 100vh;
}

.header {
  text-align: center;
  color: #b00020;
  margin-bottom: 40px;
  text-shadow: none;
}

.header h1 {
  font-size: 2.5rem;
  margin: 0 0 10px 0;
  font-weight: 700;
}

.subtitle {
  font-size: 1.1rem;
  margin: 0;
  opacity: 1;
  color: #666;
}

.blood-form {
  background: white;
  border-radius: 15px;
  padding: 40px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.form-section {
  margin-bottom: 50px;
}

.form-section:last-of-type {
  margin-bottom: 30px;
}

.section-title {
  font-size: 1.5rem;
  color: #e85b5b;
  margin: 0 0 25px 0;
  padding-bottom: 15px;
  border-bottom: 3px solid #e85b5b;
  font-weight: 600;
}

.subsection {
  margin-bottom: 35px;
  padding: 20px;
  background: #fef8f8;
  border-radius: 10px;
  border-left: 4px solid #e85b5b;
}

.subsection-title {
  font-size: 1.1rem;
  color: #c85a54;
  margin: 0 0 18px 0;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.parameters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 25px;
}

.param-group {
  display: flex;
  flex-direction: column;
}

.param-group label {
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 8px;
  font-size: 0.95rem;
}

.param-group input {
  padding: 12px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.3s ease;
  background: #f8f9ff;
}

.param-group input:focus {
  outline: none;
  border-color: #e85b5b;
  background: white;
  box-shadow: 0 0 0 3px rgba(232, 91, 91, 0.15);
}

.unit {
  font-size: 0.85rem;
  color: #999;
  margin-top: 6px;
  font-style: italic;
}

.action-buttons {
  display: flex;
  gap: 15px;
  justify-content: center;
  margin-top: 40px;
  padding-top: 30px;
  border-top: 2px solid #f0f0f0;
}

.btn {
  padding: 14px 40px;
  font-size: 1rem;
  font-weight: 600;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.btn-primary {
  background: linear-gradient(135deg, #e85b5b 0%, #c85a54 100%);
  color: white;
  box-shadow: 0 5px 20px rgba(232, 91, 91, 0.4);
}

.btn-primary:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 30px rgba(232, 91, 91, 0.6);
}

.btn-primary:active {
  transform: translateY(-1px);
}

.btn-secondary {
  background: #f0f0f0;
  color: #333;
  border: 2px solid #ddd;
}

.btn-secondary:hover {
  background: #e8e8e8;
  border-color: #bbb;
}

.subsection-info {
  font-size: 0.9rem;
  color: #666;
  margin: -10px 0 15px 0;
  font-style: italic;
}

.param-group.is-calculated {
  background: linear-gradient(135deg, #fefbfb 0%, #fef8f8 100%);
  padding: 12px;
  border-radius: 8px;
  border: 2px solid #c85a54;
}

.param-group.is-calculated input {
  background: #fff9e6;
  border-color: #ffc107;
  cursor: not-allowed;
  opacity: 0.9;
}

.param-group.is-calculated input:focus {
  border-color: #ffc107;
  box-shadow: 0 0 0 3px rgba(255, 193, 7, 0.2);
}

  .error-message,
  .success-message {
    margin: 20px 0 0;
    border-radius: 8px;
    padding: 14px 18px;
    font-weight: 600;
  }

  .error-message {
    background: #ffe7e9;
    color: #b00020;
    border: 1px solid #f5c2c7;
  }

  .success-message {
    background: #ecf8ed;
    color: #1d7f00;
    border: 1px solid #c5e1c5;
    letter-spacing: 0.3px;
}

@media (max-width: 768px) {
  .blood-input-container {
    padding: 20px 15px;
  }

  .header h1 {
    font-size: 1.8rem;
  }

  .blood-form {
    padding: 25px;
  }

  .parameters-grid {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .action-buttons {
    flex-direction: column;
  }

  .btn {
    width: 100%;
  }
}
</style>
