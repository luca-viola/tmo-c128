
# C/128 & DRIVE1541 LANCIAMOLI A TUTTO GAS!

## A grande richiesta, una indispensabile routine che manderà in visibilio gli smanettoni dotati di C128 & drive 1541.

**di Luca Viola**

Chi possiede un C/128, dotato di un semplice drive 1541, spesso si rode il fegato durante gli estenuanti caricamenti a cui viene sottoposto, pensando con una punta di invidia ai più fortunati(?) possessori dei drive 1570/71 (per non dire 1581!). E pensare che per il solito modo 64 esistono decine di acceleratori software! Proprio non si può fare nulla per il nostro potente computer? Certo che si può! Da un punto di vista strettamente tecnico, infatti, il modo di gestire i drive 1541 nelle due modalità è identico, eccezion fatta per la disposizione dei dati in memoria. Nel C/128, infatti, si deve necessariamente tener conto dei fatto che si hanno due banchi di Ram da 64K Tenendo conto di questa peculiarità, dovrebbe essere relativamente facile(!) scrivere un acceleratore software. Ed in effetti e così.

## LE CARATTERISTICHE

Il "turbo" che vedete in queste pagine è ricavato in misura diretta da quello pubblicato sul fascicolo Commodore Speciale Drive pubblicato dalla Systems Editoriale. In tale fascicolo, infatti, vi è il disassembiato commentato di un eccellente turbodisk. Operando una conversione diretta dalle routine kernal dei C/64 al C/128 e convertendo alcune locazioni del S.O. del C/64 alle analoghe del C/128 ci si avvicina alla soluzione dei problema. I dolori nascono nel momento in cui si usano le routine di sistema per depositare in tutta la memoria disponibile i dati provenienti dal drive: tali routine, infatti, sono abbastanza lente, per cui la velocità globale, pur se soddisfacente, non sarebbe paragonabile a quella ottenibile con prodotti analoghi. Si è dunque reso necessario riscrivere le suddette routine sostituendole con altre, più veloci ed efficienti, e il risultato finale si commenta da solo: per usare un termine di paragone comune tra i sessantaquattristi, lo Speedisk 128 - questo è il suo nome - riesce a caricare, riferendosi a programmi registrati con un interleave pari a 10, 202 blocchi in soli 24 secondi! E per chi era abituato a mangiar panini(!) durante le lungh(issime) pause di caricamento, è venuto il momento di mettersi a dieta... Ma tralasciamo le facezie e passiamo ad analizzare più in dettaglio il programma.

## COME SI USA

Innanzitutto lubrificatevi i polpastrelli per digitare i circa 1200 Data che costituiscono il programma caricatore in Basic. Per facilitare le cose il programma è diviso in blocchi, in modo da meglio individuare un eventuale errore. Una volta digitato il listato, salvatelo e verificatelo prima di dare run. A questo punto, se non avrete commesso errori, basterà premere il tasto Return per attivare il turbo quando il computer ve lo richiederà; diversamente apparirà una segnalazione di errore relativa al blocco di data che presenta problemi. Una volta attivato il turbo, potete registrarlo direttamente su disco come file Lm, digitando:

`Bsave "Speedisk 128+ ", P 4864 To P 6076`

... e attivato con:

`Sys 5918`

... se si vuole che il turbo sia immune al restore, oppure:

`Sys 5888`

... se si vuole caricare e attivare il turbo dall'interno di un proprio programma. Una volta attivato, comunque, potrete caricare ciò che volete seguendo la solita sintassi del basic 7.0 per i comandi di caricamento (e cioè Load, Dioad e Bload), mantenendo inalterata, cioè, la procedura di caricamento dei programmi sfruttando le routine standard dei kernal. Ciò significa che, se il turbo è attivato, una JSR $FFD5 eseguirà un Load Veloce: naturalmente sarà necessario chiamare, nel modo consueto, le routine di Setfile ($Ffba), Setname ($Ffbd) e Setbank ($Ff68, richiede in Acc. il numero di banco in cui caricare) prima di saltare a $$Ffd5. E' importante ricordare che la verifica sarà eseguita a velocità normale: si è scelta questa via per ottimizzare al meglio l'algoritmo di storaggio dati, tenendo anche conto del fatto che i programmi in genere vengono verificati una volta sola dopo il loro salvataggio, e quindi non si rende realmente necessaria l'operazione di verifica ad alta velocità (e poi, dite la verità, quante volte avete usato Verify o Dverify col drive?). Se inoltre (caso raro) userete il comando Load "$", 8 per caricare la directory, essa verrà caricata dalle routines standard dei dos, perchè i turbodisk, in genere, maltrattano i dati provenienti dalla directory, non essendo questa un comune file programma. In ogni caso, per non sbagliare, potete continuare ad usare il comodo comando Directory (o Catalog). Caricando un programma, sullo schermo a 40 colonne apparirà un contabiocchi in tempo reale nell'angolo in alto a destra, che vi informerà sul numero di blocchi (=gruppi di 255 bytes) che vengono deposti in memoria, mentre tale comoda(?) opzione non sarà visualizzata in 80 colonne. Sia in 40 che 80 colonne, invece, verranno visualizzati gli indirizzi di caricamento iniziale e finale dei file trattato, ma solo se siete in modo diretto. In modo programma, invece, l'informazione non verrà visualizzata per evitare di cancellare dati eventualmente presenti sul video, mentre il contablocchi sarà sempre visualizzato, quindi tenetene conto nei vostri programmi. Ricordate, infine, per evitare spiacevoli sorprese, di non invadere l'area compresa tra +4864 a +6106 (nel banco 0) e da $3e4 a $3fO (comune a tutte le configurazioni di banco) perchè è qui che risiedono i dati vitali dei turbo: in particolare, a partire da $3e4 si trova la miniroutine di storaggio dati in ram. Il programma 2 è un demo che mostra visivamente l'incremento di velocità ottenuto: esso dapprima disegna una pagina grafica, quindi la registra su disco ricaricandola in seguito a velocità normale e, subito dopo, in turbo - e la differenza si nota!

Passiamo ora ad una breve descrizione delle varie sezioni dei turbo (per il disassembiato si rimanda al fascicolo Speciale Drive, dal momento che i due programmi sono più o meno simili (le differenze più rilevanti risiedono, appunto, nella gestione della memoria, fondamentalmente diversa tra il C/64 e il C/128). I salti utilizzati, comunque, sono quelli standard dei Kernal Cbm, e che quindi potrete facilmente individuare. Le routine non comprese nella tabella di salto dei kernal sono:

**$F50F** (stampa Searching For...)  
**$F533** (stampa Loading)  
**$F685** (stampa File Not Found)  
**$FOD5** (routine di Bopen: effettua una Open veloce saltando alcuni controlli)  
**$F59E** (routine di Bclose: effettua una Close veloce  
**$Ff77** (carica il valore puntato dalla locazione di pagina zero posta in accumulatore + un offset posto in Y nel numero di banco posto nel registro X)  

Vediamo ora in dettaglio le sezioni del programma:

**$1300-$13ff**: questo programma va trasferito alla memoria dei drive  
**$1400-$14Bd**: procedura di apertura del file $14c0-$1551: lettura e storaggio dati  
**$1552-$1700**: chiusura del file o errore  
**$1700- ....**: da qui in poi è presente il codice di inizializzazione che modifica il vettore di load, stampa il messaggio iniziale, modifica il vettore di Restore, pone in $3e4 la routine di storaggio veloce, ecc.  

In ogni caso, se conoscete il L.M., non dovreste aver problemi a comprendere, almeno nelle sue linee essenziali, il programma. L'importante è che la schiavitù dei caricamenti lunghi e' finita!!  

## INTERLEAVE E DINTORNI

Per Interleave si intende il numero di settori dopo cui il Dos dei drive scriverà, in fase di registrazione, il settore successivo. Per esempio, con un ínterleave 10, se un programma viene registrato su una certa traccia a partire dal settore zero, il Dos sceglierebbe, come settore da utilizzare successivamente per la registrazione, il decimo. Almeno intuitivamente, più tale valore è piccolo, più veloce è il caricamento di un file, perchè vengono eliminati i tempi morti per lo spostamento della testina. Ma ciò, nella pratica, non si verifica in quanto ogni velocizzatore ha un suo interleave ideale, al di sotto o al di sopra dei quale rallenta vistosamente (e questo si verifica soprattutto su dischetti troppo pieni o sottoposti a vari comandi di tipo Scratch & save, perchè non sempre il Dos riesce a trovare il giusto numero di settori liberi per le sue esigenze). L'interleave ideale per il nostro velocizzatore è pari a 9 o 10, ed é possibile stabilire, purchè si abbia un dischetto sufficientemente libero, l'interleave con cui salvare i programmi. Se quindi, prima di registrare il vostro file, digitate: Open 1, 8, 15, 'UW" + Chr$(105) + Chr$(0) + Chr$(1) + Chr$(in): Ciose 1: Dsave "Nome" (dove in rappresenta l'interleave e può avere valore 9 o 10) otterrete il massimo rendimento dal turbodisk. Per un maggiore approfondimento su questo argomento si rimanda comunque al n. 69 di CCC pag. 27).
