# LocalTask

LocalTask è un'applicazione iOS sviluppata in SwiftUI che permette agli utenti di creare, gestire e cercare task geolocalizzate nella propria zona.

L'obiettivo principale dell'applicazione è mettere in contatto persone che hanno bisogno di un aiuto rapido per attività quotidiane con utenti vicini disponibili a svolgerle in cambio di un possibile compenso monetario.

Esempi di task possono essere piccoli lavori domestici, traslochi, babysitting, commissioni, assistenza last-minute e altre attività locali.

---

## Panoramica

LocalTask è pensata come un marketplace locale basato sulla prossimità geografica e sull'interazione in tempo reale tra utenti.

L'applicazione si concentra su tre obiettivi principali:

* **Reattività**: permettere agli utenti di pubblicare una task e trovare rapidamente un helper nelle vicinanze.
* **Economia di quartiere**: offrire agli utenti la possibilità di monetizzare il proprio tempo libero svolgendo piccole attività nella propria zona.
* **Affidabilità**: aumentare la fiducia tra gli utenti tramite candidature, recensioni, rating e comunicazione in-app.

La piattaforma si basa su due principali tipologie di utenti:

* **Requester**: l'utente che crea una task e cerca aiuto.
* **Helper**: l'utente che si candida per svolgere una task.

---

## Funzionalità principali

### Gestione utenti

* Registrazione e login degli utenti
* Logout
* Gestione del profilo personale
* Modifica di informazioni come nome utente, foto profilo, bio e zona geografica

### Gestione delle task

Gli utenti possono creare, modificare ed eliminare task specificando:

* Titolo
* Descrizione
* Categoria
* Data e ora
* Posizione geografica
* Possibile compenso monetario

### Visualizzazione e ricerca delle task

Le task possono essere visualizzate in due modalità principali:

* Lista in stile feed
* Mappa con marker geolocalizzati

L'applicazione permette inoltre di cercare e filtrare le task in base a:

* Categoria
* Distanza
* Data
* Ricerca testuale su titolo e descrizione

### Geolocalizzazione

LocalTask utilizza la posizione dell'utente per mostrare le task vicine e aggiornare i risultati in base all'area geografica corrente.

L'app integra i servizi Apple per la gestione della posizione, degli indirizzi e della visualizzazione delle task su mappa.

### Candidature alle task

Gli utenti possono candidarsi per svolgere le task disponibili.

Il creatore della task può:

* Visualizzare la lista dei candidati
* Accettare o rifiutare le candidature
* Valutare i candidati anche tramite rating e recensioni presenti nel profilo pubblico

### Stato delle task

Ogni task può assumere uno stato che rappresenta il suo avanzamento:

* Da svolgere
* In corso
* Completata

### Notifiche in-app

L'applicazione include un sistema di notifiche in-app per informare gli utenti riguardo a eventi rilevanti, come:

* Nuova candidatura a una task
* Accettazione o rifiuto di una candidatura
* Cambio di stato di una task
* Ricezione di un nuovo messaggio

### Chat privata

Quando un candidato viene accettato per una task, viene creata una chat privata tra il requester e l'helper selezionato.

In questo modo i due utenti possono comunicare direttamente e definire i dettagli dell'attività da svolgere.

### Recensioni e rating

Dopo il completamento di una task, gli utenti possono lasciare una recensione.

Una recensione comprende:

* Valutazione da 1 a 5 stelle
* Commento testuale sull'esperienza e sul lavoro svolto

Il rating contribuisce al profilo pubblico dell'utente e aiuta i requester a scegliere helper più affidabili.

### Storico

L'applicazione consente di consultare lo storico delle attività dell'utente, tra cui:

* Task create
* Task completate
* Attività legate alle interazioni dell'utente

---

## Architettura

L'applicazione segue una struttura vicina al pattern architetturale **Model-View-ViewModel**.

Il progetto è diviso in diversi livelli:

* **View**: schermate SwiftUI responsabili dell'interfaccia utente.
* **ViewModel**: componenti che gestiscono lo stato delle schermate e la logica di presentazione.
* **Repository**: componenti che si occupano della lettura e scrittura dei dati su Firebase.
* **Servizi esterni**: Firebase, Firestore, MapKit e CoreLocation.

Questa struttura permette di separare l'interfaccia utente dalla logica di accesso ai dati, rendendo il progetto più ordinato, modulare e facilmente estendibile.

---

## Tecnologie utilizzate

* Swift
* SwiftUI
* Firebase Authentication
* Cloud Firestore
* Firebase Realtime Listeners
* MapKit
* CoreLocation

---

## Struttura Firebase

L'applicazione utilizza Firebase come backend.

Le principali collection Firestore sono:

| Collection            | Descrizione                                                       |
| --------------------- | ----------------------------------------------------------------- |
| `users`               | Profili degli utenti registrati                                   |
| `tasks`               | Task pubbliche visibili nella Home e nella Mappa                  |
| `tasks_private`       | Informazioni sensibili delle task non visibili a tutti gli utenti |
| `applications`        | Candidature inviate dagli utenti per specifiche task              |
| `chats`               | Conversazioni private tra utenti                                  |
| `notifications`       | Notifiche in-app generate dalle interazioni                       |
| `reviews`             | Recensioni lasciate dopo il completamento di una task             |
| `review_requirements` | Obblighi di recensione ancora pendenti                            |

---

## Esempio di flusso utente

Un possibile flusso di utilizzo dell'applicazione è il seguente:

1. L'utente effettua il login o crea un nuovo account.
2. L'utente visualizza le task vicine nella Home o sulla Mappa.
3. L'utente filtra le task per categoria, distanza, data o testo.
4. Un requester crea una nuova task inserendo titolo, descrizione, posizione, data e compenso.
5. Un helper si candida per svolgere la task.
6. Il requester riceve una notifica e accetta o rifiuta la candidatura.
7. Se la candidatura viene accettata, viene creata una chat privata tra i due utenti.
8. La task viene svolta e completata.
9. Gli utenti possono lasciare una recensione.
10. Il rating pubblico dell'utente recensito viene aggiornato.

---

### Moderazione

L'applicazione introduce il concetto di affidabilità tramite recensioni e rating.

Una versione futura potrebbe includere un sistema di moderazione più completo, con:

* Segnalazione degli utenti
* Segnalazione delle task
* Blocco degli utenti
* Motivazione delle segnalazioni
* Badge di affidabilità
* Storico pubblico più dettagliato

---

## Possibili sviluppi futuri

Alcuni possibili miglioramenti futuri includono:

* Integrazione delle notifiche push
* Sistema di pagamento sicuro in-app
* Strumenti di moderazione più avanzati
* Regole Firestore più sicure e restrittive
* Profili utente più dettagliati
* Validazione più robusta delle recensioni
* Badge pubblici per utenti affidabili
* Ricerca e filtri più avanzati
* Miglioramenti all'interfaccia e all'esperienza utente

---

## Disclaimer

Questo progetto è stato realizzato per il corso di **Laboratorio di Programmazione per Sistemi Mobili e Tablet** presso l'**Università degli Studi di Trento (UniTN)**.

Voto finale conseguito: **30L**.
