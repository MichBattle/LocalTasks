📱 LocalTasks
=============

**LocalTasks** è un'app mobile sviluppata in **Swift** che permette alle persone di pubblicare e trovare piccoli lavori locali (es. traslochi, babysitting, aiuti vari) basati sulla posizione geografica.

L'obiettivo è creare una piattaforma semplice e veloce per connettere chi ha bisogno di aiuto con chi è disponibile a svolgere task nelle vicinanze.

* * * * *

🚀 Features
-----------

### 👤 Gestione utenti

-   Registrazione:
    -   Email & Password
    -   Google Sign-In
    -   Apple Sign-In
-   Login / Logout
-   Recupero credenziali
-   Profilo utente:
    -   Username
    -   Foto profilo
    -   Bio
    -   Zona geografica

* * * * *

### 📌 Gestione Task

-   Creazione task con:
    -   Titolo
    -   Descrizione
    -   Categoria (es. traslochi, babysitting, ecc.)
    -   Data e ora
    -   Posizione geografica (mappa o indirizzo)
    -   Compenso (opzionale)
-   Modifica task
-   Eliminazione task

* * * * *

### 🔍 Visualizzazione & Ricerca

-   Feed stile social (tipo Instagram)
-   Visualizzazione su mappa
-   Filtri:
    -   Distanza
    -   Categoria
    -   Data
-   Ricerca testuale (titolo/descrizione)

* * * * *

### 📍 Geolocalizzazione

-   Rilevamento posizione utente
-   Mostra task nelle vicinanze
-   Aggiornamento dinamico dei risultati

* * * * *

### 🤝 Interazione tra utenti

-   Candidatura per una task
-   Accettazione / rifiuto candidati
-   Stato task:
    -   Da svolgere
    -   In corso
    -   Completata

* * * * *

### 🔔 Sistema notifiche

-   Push notifications
-   Notifiche in-app

Trigger:

-   Nuova candidatura
-   Accettazione / rifiuto
-   Cambio stato task
-   Nuove task vicine

* * * * *

### 💬 Comunicazione (opzionale)

-   Chat privata tra creatore task e helper

* * * * *

### ⭐ Sistema recensioni (opzionale)

-   Rating 1--5 stelle
-   Feedback testuale
-   Visibile nel profilo utente

* * * * *

### 📚 Storico

-   Task create
-   Task completate
-   Attività utente

* * * * *

### 🛡️ Moderazione (Admin Mode)

-   Segnalazione utenti
-   Segnalazione task
-   Blocco utenti
-   Motivazioni:
    -   Lavoro svolto male
    -   Truffa
    -   Altro (campo libero)

* * * * *

🏗️ Tech Stack (proposto)
-------------------------

-   **Frontend:** Swift / SwiftUI
-   **Backend:** (da definire)
    -   Firebase / Node.js / Django
-   **Database:**
    -   Firestore / PostgreSQL
-   **Autenticazione:**
    -   Firebase Auth / OAuth
-   **Mappe & Geolocalizzazione:**
    -   Apple Maps / MapKit / Google Maps SDK
-   **Notifiche:**
    -   Firebase Cloud Messaging (FCM) / APNs
