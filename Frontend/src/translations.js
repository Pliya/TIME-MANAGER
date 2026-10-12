import { addMessages } from './i18n'

// Français -> anglais. Clé = texte français exact utilisé dans les composants.
addMessages({
  // Accessibilité & langue
  'Accessibilité': 'Accessibility',
  'Contraste élevé': 'High contrast',
  'Texte A+': 'Text A+',
  'Lecture vocale': 'Voice reading',
  'Lecture vocale activée': 'Voice reading on',
  'Lecture vocale désactivée': 'Voice reading off',
  'Langue': 'Language',

  // Rôles (sections du menu)
  'Employé': 'Employee',
  'Manager': 'Manager',
  'Administrateur / RH': 'Administrator / HR',

  // Menu & navigation
  'Dashboard': 'Dashboard',
  'Pointage': 'Clock',
  'Mes temps': 'My times',
  'Planning': 'Schedule',
  'Absences': 'Leave',
  'Statistiques': 'Statistics',
  'Équipe': 'Team',
  'Alertes': 'Alerts',
  'Validation': 'Validation',
  'Utilisateurs': 'Users',
  'Règles': 'Rules',
  'Paie': 'Payroll',
  'Se déconnecter': 'Sign out',

  // Titres de pages (route.meta.title)
  'Connexion': 'Sign in',
  'Nouveau temps de travail': 'New working time',
  'Modifier un temps de travail': 'Edit working time',

  // Connexion
  'Ton temps de travail, simplement.': 'Your working time, made simple.',
  'Pointer en un geste, suivre tes heures, demander une correction. Tes chiffres restent à toi.':
    'Clock in one tap, track your hours, request a correction. Your numbers stay yours.',
  'Un seul bouton, sur ton téléphone ou à la borne': 'One button, on your phone or at the terminal',
  'Fonctionne sans réseau, envoi au retour de la connexion': 'Works offline, sent when the connection is back',
  'Aucune comparaison entre collègues': 'No comparison between colleagues',
  'Mairie de Gotham · Ressources humaines': 'Gotham City Hall · Human Resources',
  'Connexion · Espace agent': 'Sign in · Staff area',
  'Email professionnel': 'Work email',
  'Mot de passe': 'Password',
  'Mot de passe oublié ?': 'Forgot password?',
  'Contacte ton administrateur ou le service RH : ils réinitialisent ton mot de passe.':
    'Contact your administrator or HR: they reset your password.',
  'Connexion...': 'Signing in...',
  'Se connecter': 'Sign in',
  'Première connexion ? Suivre le tutoriel': 'First time? Follow the tutorial',
  'Masquer le mot de passe': 'Hide password',
  'Afficher le mot de passe': 'Show password',
  'Précédent': 'Previous',
  'Suivant': 'Next',
  "C'est parti": "Let's go",
  'Fermer le tutoriel': 'Close the tutorial',

  // Statuts communs
  'En attente': 'Pending',
  'Validé': 'Approved',
  'Refusé': 'Rejected',
  'Déclaré': 'Declared',
  'Justificatif reçu': 'Document received',
  'En cours': 'In progress',
  'Pointé': 'Clocked in',
  'Sorti': 'Clocked out',
  'Congé': 'Leave',
  'Arrêt maladie': 'Sick leave',
  'Récupération': 'Time off in lieu',

  // Boutons & actions communs
  'Valider': 'Approve',
  'Refuser': 'Reject',
  'Accepter': 'Accept',
  'Corriger': 'Fix',
  'Modifier': 'Edit',
  'Supprimer': 'Delete',
  'Annuler': 'Cancel',
  'Enregistrer': 'Save',
  'Envoyer': 'Send',
  'Retour': 'Back',
  'Temps': 'Times',
  'Voir le détail': 'View details',
  'Aujourd\'hui': 'Today',
  'Cette semaine': 'This week',
  'Ce mois-ci': 'This month',
  'Depuis le début': 'All time',

  // Tutoriel de connexion
  'Pointer': 'Clock in',
  'Sans réseau ou sans téléphone': 'No network or no phone',
  'Une erreur ?': 'A mistake?',
  "Utilise l'email et le mot de passe donnés par ton administrateur. Il n'y a pas d'inscription : c'est lui qui crée ton compte.":
    'Use the email and password given by your administrator. There is no sign-up: they create your account.',
  "En arrivant, appuie sur « Pointer l'arrivée ». En partant, sur « Pointer la sortie ». Un seul bouton, rien à saisir.":
    'When you arrive, tap "Clock in". When you leave, "Clock out". One button, nothing to type.',
  "Le pointage est gardé sur l'appareil sans réseau. Sans téléphone, utilise la borne : « Journée conforme au planning » en un clic.":
    'Clock-ins are kept on the device when offline. With no phone, use the terminal: "Day matches the schedule" in one tap.',
  "Dans « Mes temps », demande une correction. Ton manager répond sous 48 h, et un refus est toujours motivé.":
    'In "My times", request a correction. Your manager answers within 48 h, and a rejection is always explained.',

  // Messages d'erreur de connexion
  'Email ou mot de passe incorrect.': 'Incorrect email or password.',
  'Trop de tentatives. Réessayez dans une minute.': 'Too many attempts. Try again in a minute.',
  "Impossible de contacter l'API.": 'Cannot reach the API.',
})
