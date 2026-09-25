<template>
  <div class="user">

    <h1>Gestion des utilisateurs</h1>

    <!-- ================================================== -->
    <!-- MESSAGES -->
    <!-- ================================================== -->

    <div
      v-if="loading"
      class="message loading"
    >
      Chargement...
    </div>

    <div
      v-if="error"
      class="message error"
    >
      <strong>Erreur :</strong>

      <ul v-if="Array.isArray(error)">
        <li
          v-for="(message, index) in error"
          :key="index"
        >
          {{ message }}
        </li>
      </ul>

      <p v-else>
        {{ error }}
      </p>
    </div>

    <div
      v-if="success"
      class="message success"
    >
      {{ success }}
    </div>


    <!-- ================================================== -->
    <!-- UTILISATEUR ACTUEL -->
    <!-- ================================================== -->

    <div
      v-if="user && !loading"
      class="user-info"
    >

      <h2>Utilisateur actuel</h2>

      <div class="info-row">
        <strong>ID :</strong>
        <span>{{ user.id }}</span>
      </div>

      <div class="info-row">
        <strong>Username :</strong>
        <span>{{ user.username }}</span>
      </div>

      <div class="info-row">
        <strong>Email :</strong>
        <span>{{ user.email }}</span>
      </div>

    </div>


    <hr />


    <!-- ================================================== -->
    <!-- CREER UN UTILISATEUR -->
    <!-- ================================================== -->

    <div class="section">

      <h2>Créer un utilisateur</h2>

      <form
        @submit.prevent="createUser"
      >

        <div class="form-group">

          <label for="new-username">
            Username
          </label>

          <input
            id="new-username"
            v-model.trim="newUsername"
            type="text"
            placeholder="Entrez le username"
            required
            minlength="1"
          />

        </div>


        <div class="form-group">

          <label for="new-email">
            Email
          </label>

          <input
            id="new-email"
            v-model.trim="newEmail"
            type="email"
            placeholder="exemple@email.com"
            required
          />

        </div>


        <button
          type="submit"
          :disabled="loading"
        >
          {{ loading ? 'Création...' : 'Créer' }}
        </button>

      </form>

    </div>


    <!-- ================================================== -->
    <!-- MODIFIER UN UTILISATEUR -->
    <!-- ================================================== -->

    <div
      v-if="user"
      class="section"
    >

      <hr />

      <h2>Modifier l'utilisateur</h2>

      <form
        @submit.prevent="updateUser"
      >

        <div class="form-group">

          <label for="update-username">
            Username
          </label>

          <input
            id="update-username"
            v-model.trim="editUsername"
            type="text"
            required
            minlength="1"
          />

        </div>


        <div class="form-group">

          <label for="update-email">
            Email
          </label>

          <input
            id="update-email"
            v-model.trim="editEmail"
            type="email"
            required
          />

        </div>


        <button
          type="submit"
          :disabled="loading"
        >
          {{ loading ? 'Modification...' : 'Modifier' }}
        </button>

      </form>

    </div>


    <!-- ================================================== -->
    <!-- SUPPRIMER UN UTILISATEUR -->
    <!-- ================================================== -->

    <div
      v-if="user"
      class="section"
    >

      <hr />

      <h2>Supprimer l'utilisateur</h2>

      <button
        type="button"
        class="delete-button"
        :disabled="loading"
        @click="deleteUser"
      >
        {{ loading ? 'Suppression...' : 'Supprimer' }}
      </button>

    </div>

  </div>
</template>


<script setup>

import {
  ref,
  onMounted
} from 'vue'

import axios from 'axios'


/*
 * ==================================================
 * API
 * ==================================================
 */

const API_URL =
  'http://localhost:4000/api/users'


/*
 * ==================================================
 * ETAT DE L'APPLICATION
 * ==================================================
 */

const user = ref(null)

const userId = ref(1)

const loading = ref(false)

const error = ref(null)

const success = ref(null)


/*
 * ==================================================
 * FORMULAIRE CREATE
 * ==================================================
 */

const newUsername = ref('')

const newEmail = ref('')


/*
 * ==================================================
 * FORMULAIRE UPDATE
 * ==================================================
 */

const editUsername = ref('')

const editEmail = ref('')


/*
 * ==================================================
 * NETTOYER LES MESSAGES
 * ==================================================
 */

function clearMessages() {

  error.value = null

  success.value = null

}


/*
 * ==================================================
 * NOM DES CHAMPS
 * ==================================================
 */

function formatFieldName(field) {

  const names = {

    username: 'Username',

    email: 'Email',

    user_id: 'Utilisateur',

    id: 'ID'

  }

  return names[field] || field

}


/*
 * ==================================================
 * GESTION CENTRALE DES ERREURS API
 * ==================================================
 */

function getApiErrors(err) {

  /*
   * ================================================
   * PAS DE REPONSE DU SERVEUR
   * ================================================
   *
   * Exemple :
   *
   * Phoenix est arrêté
   * problème réseau
   * problème CORS
   * serveur inaccessible
   */

  if (!err.response) {

    return "Impossible de contacter le serveur. Vérifiez que l'API Phoenix est démarrée."

  }


  /*
   * ================================================
   * CODE HTTP
   * ================================================
   */

  const status =
    err.response.status


  /*
   * ================================================
   * 400
   * ================================================
   */

  if (status === 400) {

    return "La requête envoyée est invalide."

  }


  /*
   * ================================================
   * 401
   * ================================================
   */

  if (status === 401) {

    return "Vous devez être authentifié pour effectuer cette action."

  }


  /*
   * ================================================
   * 403
   * ================================================
   */

  if (status === 403) {

    return "Vous n'avez pas l'autorisation d'effectuer cette action."

  }


  /*
   * ================================================
   * 404
   * ================================================
   */

  if (status === 404) {

    return "Utilisateur introuvable."

  }


  /*
   * ================================================
   * 409
   * ================================================
   */

  if (status === 409) {

    return "Cette opération provoque un conflit avec les données existantes."

  }


  /*
   * ================================================
   * 422
   * ================================================
   *
   * Erreurs de validation Phoenix
   */

  if (status === 422) {

    const errors =
      err.response?.data?.errors

    /*
     * Aucun détail fourni
     */

    if (!errors) {

      return "Les informations fournies sont invalides."

    }


    const messages = []


    /*
     * Exemple :
     *
     * {
     *   errors: {
     *     username: ["can't be blank"],
     *     email: ["has invalid format"]
     *   }
     * }
     */

    Object.entries(errors).forEach(
      ([field, fieldErrors]) => {

        /*
         * Plusieurs erreurs pour
         * le même champ.
         */

        if (Array.isArray(fieldErrors)) {

          fieldErrors.forEach(
            (message) => {

              messages.push(
                `${formatFieldName(field)} : ${message}`
              )

            }
          )

        } else {

          messages.push(
            `${formatFieldName(field)} : ${fieldErrors}`
          )

        }

      }
    )


    /*
     * Si aucun message n'a été
     * trouvé.
     */

    if (messages.length === 0) {

      return "Les informations fournies sont invalides."

    }


    return messages

  }


  /*
   * ================================================
   * 429
   * ================================================
   */

  if (status === 429) {

    return "Trop de requêtes. Veuillez patienter quelques instants."

  }


  /*
   * ================================================
   * ERREURS SERVEUR
   * ================================================
   *
   * 500
   * 501
   * 502
   * 503
   * etc.
   */

  if (status >= 500) {

    return "Une erreur est survenue sur le serveur. Veuillez réessayer plus tard."

  }


  /*
   * ================================================
   * AUTRE ERREUR HTTP
   * ================================================
   */

  return `Une erreur est survenue (HTTP ${status}).`

}


/*
 * ==================================================
 * VERIFIER LA REPONSE API
 * ==================================================
 */

function getUserFromResponse(response) {

  /*
   * Vérifier que la réponse
   * contient bien data.data
   */

  if (!response?.data?.data) {

    throw new Error(
      "Réponse invalide reçue du serveur."
    )

  }

  return response.data.data

}


/*
 * ==================================================
 * GET USER
 * ==================================================
 */

async function getUser() {

  /*
   * Si aucun ID n'est disponible,
   * ne pas appeler /null
   */

  if (!userId.value) {

    user.value = null

    return

  }


  loading.value = true

  clearMessages()


  try {

    const response =
      await axios.get(
        `${API_URL}/${userId.value}`
      )


    /*
     * Vérifier la réponse.
     */

    const fetchedUser =
      getUserFromResponse(response)


    /*
     * Stocker l'utilisateur.
     */

    user.value =
      fetchedUser


    /*
     * Initialiser le formulaire
     * UPDATE.
     */

    editUsername.value =
      user.value.username

    editEmail.value =
      user.value.email


  } catch (err) {

    console.error(
      'GET USER ERROR:',
      err
    )


    user.value = null


    /*
     * Transformer l'erreur
     * en message utilisateur.
     */

    if (err instanceof Error &&
        !err.response) {

      error.value =
        "La réponse du serveur est invalide."

    } else {

      error.value =
        getApiErrors(err)

    }


  } finally {

    loading.value = false

  }

}


/*
 * ==================================================
 * CREATE USER
 * ==================================================
 */

async function createUser() {

  loading.value = true

  clearMessages()


  /*
   * Validation supplémentaire
   * côté JavaScript.
   */

  if (!newUsername.value) {

    error.value =
      "Le username est obligatoire."

    loading.value = false

    return

  }


  if (!newEmail.value) {

    error.value =
      "L'email est obligatoire."

    loading.value = false

    return

  }


  try {

    const response =
      await axios.post(
        API_URL,
        {
          user: {
            username:
              newUsername.value,

            email:
              newEmail.value
          }
        }
      )


    /*
     * Vérifier la réponse.
     */

    const createdUser =
      getUserFromResponse(response)


    /*
     * Stocker l'utilisateur créé.
     */

    user.value =
      createdUser


    /*
     * Le nouvel utilisateur
     * devient l'utilisateur actuel.
     */

    userId.value =
      createdUser.id


    /*
     * Synchroniser UPDATE.
     */

    editUsername.value =
      createdUser.username

    editEmail.value =
      createdUser.email


    /*
     * Nettoyer CREATE.
     */

    newUsername.value = ''

    newEmail.value = ''


    /*
     * Message de succès.
     */

    success.value =
      "Utilisateur créé avec succès."


    console.log(
      'Utilisateur créé :',
      createdUser
    )


  } catch (err) {

    console.error(
      'CREATE USER ERROR:',
      err
    )


    /*
     * Afficher l'erreur.
     */

    if (err instanceof Error &&
        !err.response) {

      error.value =
        "La réponse du serveur est invalide."

    } else {

      error.value =
        getApiErrors(err)

    }


  } finally {

    loading.value = false

  }

}


/*
 * ==================================================
 * UPDATE USER
 * ==================================================
 */

async function updateUser() {

  /*
   * Aucun utilisateur.
   */

  if (!user.value ||
      !userId.value) {

    error.value =
      "Aucun utilisateur à modifier."

    return

  }


  loading.value = true

  clearMessages()


  /*
   * Validation supplémentaire.
   */

  if (!editUsername.value) {

    error.value =
      "Le username est obligatoire."

    loading.value = false

    return

  }


  if (!editEmail.value) {

    error.value =
      "L'email est obligatoire."

    loading.value = false

    return

  }


  try {

    const response =
      await axios.put(
        `${API_URL}/${userId.value}`,
        {
          user: {
            username:
              editUsername.value,

            email:
              editEmail.value
          }
        }
      )


    /*
     * Vérifier la réponse.
     */

    const updatedUser =
      getUserFromResponse(response)


    /*
     * Mettre à jour l'utilisateur.
     */

    user.value =
      updatedUser


    /*
     * Synchroniser les champs.
     */

    editUsername.value =
      updatedUser.username

    editEmail.value =
      updatedUser.email


    success.value =
      "Utilisateur modifié avec succès."


    console.log(
      'Utilisateur modifié :',
      updatedUser
    )


  } catch (err) {

    console.error(
      'UPDATE USER ERROR:',
      err
    )


    /*
     * Afficher l'erreur.
     */

    if (err instanceof Error &&
        !err.response) {

      error.value =
        "La réponse du serveur est invalide."

    } else {

      error.value =
        getApiErrors(err)

    }


  } finally {

    loading.value = false

  }

}


/*
 * ==================================================
 * DELETE USER
 * ==================================================
 */

async function deleteUser() {

  /*
   * Aucun utilisateur.
   */

  if (!user.value ||
      !userId.value) {

    error.value =
      "Aucun utilisateur à supprimer."

    return

  }


  /*
   * Confirmation.
   */

  const confirmed =
    window.confirm(
      `Voulez-vous vraiment supprimer l'utilisateur "${user.value.username}" ?`
    )


  /*
   * L'utilisateur annule.
   */

  if (!confirmed) {

    return

  }


  loading.value = true

  clearMessages()


  try {

    await axios.delete(
      `${API_URL}/${userId.value}`
    )


    /*
     * La suppression a réussi.
     */

    user.value = null


    /*
     * Ne pas laisser un ID
     * qui pourrait provoquer
     * /users/null.
     */

    userId.value = null


    /*
     * Nettoyer UPDATE.
     */

    editUsername.value = ''

    editEmail.value = ''


    /*
     * Message de succès.
     */

    success.value =
      "Utilisateur supprimé avec succès."


    console.log(
      'Utilisateur supprimé'
    )


  } catch (err) {

    console.error(
      'DELETE USER ERROR:',
      err
    )


    /*
     * Afficher l'erreur.
     */

    error.value =
      getApiErrors(err)


  } finally {

    loading.value = false

  }

}


/*
 * ==================================================
 * INITIALISATION
 * ==================================================
 */

onMounted(() => {

  getUser()

})

</script>


<style scoped>

.user {

  max-width: 600px;

  margin: 40px auto;

  padding: 20px;

  font-family:
    Arial,
    sans-serif;

}


h1 {

  margin-bottom: 30px;

}


h2 {

  margin-bottom: 20px;

}


/* ==================================================
   UTILISATEUR
   ================================================== */

.user-info {

  padding: 20px;

  border: 1px solid #ddd;

  border-radius: 8px;

  margin-bottom: 20px;

}


.info-row {

  display: flex;

  gap: 10px;

  margin-bottom: 10px;

}


/* ==================================================
   SECTIONS
   ================================================== */

.section {

  margin: 25px 0;

}


/* ==================================================
   FORMULAIRES
   ================================================== */

form {

  display: flex;

  flex-direction: column;

  gap: 15px;

}


.form-group {

  display: flex;

  flex-direction: column;

  gap: 5px;

}


label {

  font-weight: bold;

}


input {

  width: 100%;

  padding: 10px;

  box-sizing: border-box;

  border: 1px solid #ccc;

  border-radius: 5px;

  font-size: 14px;

}


input:focus {

  outline: none;

  border-color: #555;

}


/* ==================================================
   BOUTONS
   ================================================== */

button {

  width: fit-content;

  padding: 10px 18px;

  border: none;

  border-radius: 5px;

  cursor: pointer;

  font-size: 14px;

}


button:disabled {

  opacity: 0.6;

  cursor: not-allowed;

}


.delete-button {

  background: #d32f2f;

  color: white;

}


/* ==================================================
   MESSAGES
   ================================================== */

.message {

  padding: 12px;

  margin-bottom: 20px;

  border-radius: 5px;

}


.loading {

  background: #eee;

}


.error {

  background: #ffe5e5;

  color: #b00020;

}


.success {

  background: #e5f7e5;

  color: #176b17;

}


.error ul {

  margin-top: 10px;

  margin-bottom: 0;

}


/* ==================================================
   SEPARATION
   ================================================== */

hr {

  margin: 30px 0;

  border: none;

  border-top: 1px solid #ddd;

}

</style>