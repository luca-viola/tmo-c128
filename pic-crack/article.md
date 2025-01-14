
# IL C-128 COME L'OMA
## TRASFORMIAMO IL C/128 IN UNA CARTUCCIA SPROTETTRICE IN GRADO DI ESTRARRE QUALSIASI SCHERMATA GRAFICA DAI PROGRAMMI PER C64

**DI LUCA VIOLA**

Molti di voi, di fronte alle talvolta splendide schermate grafiche presenti nei programmi per c64 (vedi *Defender of the Crown*), avranno espresso il desiderio di poterle estrarre per usarle nei propri programmi. Esistono in commercio diverse cartucce sprotettrici in grado di togliere le schermate grafiche e registrarle su disco, ma non tutti sono disposti a comprarle, vuoi per questioni morali (!), vuoi per mancanza cronica di danaro (!!). Quale che sia il vostro problema, non crucciatevi oltre: il programma presentato in queste pagine, infatti, consente, con un C128, di estrarre qualsiasi schermata grafica dai programmi per il modo 64 (naturalmente anche se protetti), e di salvarla su disco in formato Koala. E scusateci se è poco!

## IL MIO REGNO PER UN BANCO DI RAM

Come molti sapranno, al momento del passaggio dal modo 64 al modo 128 (e viceversa) vi sono vaste zone di ram che rimangono inalterate. Una qualsiasi pagina grafica è formata da una serie di byte che rappresentano il disegno e i suoi colori: da questa semplice considerazione si deduce che al momento del reset i dati costituenti il disegno sono presenti da qualche parte in memoria; dunque dovrebbe essere possibile recuperarli. Alcune zone vengono tuttavia modificate: l'area video (`$0400-$07eb`), la zona che va da `$a00` a `$aff`, l'area di installazione dei tasti funzione (che parte da `$1000`) e ancora altre. Inoltre i dati della memoria colore (locazioni `$d800-$dbe7`) vengono cancellate irrimediabilmente, perdendo così gli attributi del colore 3 di una eventuale schermata multicolor. Questi ostacoli sono gravi e divengono pressoché insormontabili se si pensa che alcuni programmi pongono gli attributi colore 1 e 2 nella memoria video (da `$0400` a `$07eb`).

Un modo per aggirarli però esiste (altrimenti non staremmo qui a scriverlo): le zone di ram alterata riguardano soltanto la ram 0, mentre la ram 1 rimane assolutamente inalterata al momento del reset. È però impossibile sfruttare il banco di ram 1 direttamente dal modo 64, perché eseguendo un `go64` i registri adibiti al controllo della memoria (la Memory Management Unit) scompaiono dalla mappa di memoria. Sfruttando però i registri della MMU è possibile eseguire un passaggio in modo 64 attivando la ram 1 invece della ram 0: la routine di sistema di `go64`, quando viene attivata, parte infatti dal bank 15. Se la ricopiamo integralmente in bank 1 e selezioniamo la ram 1 + l'I/O prima di eseguirla, si avrà un passaggio al modo 64 mantenendo attiva la ram 1. Sorge però un problema: il chip video (8564) legge le informazioni grafiche dalla ram 0. Eseguendo la procedura descritta prima, quindi, non sarà possibile vedere nulla. Il problema si risolve settando a 1 il bit 7 del registro `$d506` (+54534): tale bit abilita infatti l'8564 a leggere la grafica in ram 1. Vedere la **figura 1** per un confronto fra la normale routine di `go64` e quella modificata.

```assembly
fff4d lda #$e3    ;resetta le porte         12000 lda #$7e  ;abilita ram1
      sta $01     :di I/O                         sta $ff00 ;+ I/O
      lda #$2f    ;dell'8502                      lda #$44  ;abilita l'8564
      sta $00     ;                               sta $d506 ;a leggere la
      lda #$f7    ;abilita le                     lda #$e3  ;grafica in ram1
      sta $d505   ;rom del c64                    sta $01   ;e continua
      jmp $(fffc) ;va a reset                     lda #$2f  ;come prima
                                                  sta $00   ;
                                                  lda #$f7  ;
```

**(FIG.1)**

Una volta passati in modo 64, sarà possibile caricare e lanciare qualsiasi programma, e operare normalmente, solo che la ram attiva sarà la ram 1: questo significa che ritornando in modo 128, l'area da `$0400` in poi nel bank1 resterà esattamente come era in modo 64. L'area da `$0000` a `$03ff` verrà comunque persa, ma per i nostri scopi non ci interessa, in quanto in quella zona non è possibile porre né attributi colore né una bit-map, perché ciò significherebbe rinunciare alla pagina zero, vitale per qualsiasi programma. Resta ancora da risolvere il problema della memoria colore: essa, infatti, si trova nel blocco dell'I/O alle locazioni `$d800-$dbe7`, e poiché l'I/O è "comune" sia alla ram 0 che alla ram 1, quando si passa in modo 128 essa viene comunque cancellata, anche se il s.o. del C128, se abilmente sfruttato, può agire a nostro favore.

## IL VETTORE DI SYSTEM-RESET

Quando si preme il tasto di reset, il microprocessore salta all'indirizzo puntato in bank 15 dal vettore `$fffc/$fffd`, e cioè a `$ff3d`. Da qui il computer salta ad eseguire le istruzioni presenti da `$e000` in poi. Viene quindi testata la presenza in ram1, agli indirizzi `$fff5-$fff7`, della stringa CBM, e, se presente, viene eseguita una `JSR` in bank 15 all'indirizzo puntato, sempre in ram1, da `$fff8-$fff9` (che normalmente contengono l'indirizzo della routine posta a `$e224`, la cui funzione è di resettare la stringa CBM e il vettore `$fff8-$fff9` ai valori di default), dopodiché viene proseguita la routine di reset. Modificando dunque il valore di `$fff8-$fff9`, possiamo far sì che al momento del reset (sia dal modo 64 che dal modo 128) il computer esegua, dopo qualche brevissima inizializzazione, una nostra routine posta in bank 15. Il salto a questa nostra routine avverrà addirittura prima di resettare i registri del VIC II e prima di cancellare la memoria colore. Come molti avranno intuito, la nostra routine inserita nel ciclo di reset dovrà prelevare i dati dalla memoria colore e depositarli in locazioni di comodo, per poi poterle riutilizzare in seguito. Il fatto inoltre che i registri del chip video non vengano alterati ci facilita di molto il compito: il solo registro `$d018` (+53272), infatti, fornisce importanti informazioni per poter subito rintracciare la posizione in memoria di una bit-map o degli attributi di colore 1 e 2. Resta da risolvere un ultimo problema: i pochissimi lettori che ci avranno seguito fin qui si staranno chiedendo, visto che i vettori di system reset si trovano in ram1, come sia possibile evitare che vengano cancellati caricando qualche programma una volta passati al modo 64 "speciale" (con attivazione della ram1 anziché ram0).

## IL REGISTRO DI CONFIGURAZIONE DELLA RAM

Il già citato registro `$d506` consente, oltre che di selezionare la lettura in ram1 della grafica per l'8564 (VIC II), di regolare la quantità e la posizione in memoria della ram comune. La ram comune si ottiene sovrapponendo fisicamente la ram 0 alla ram 1. La quantità di memoria comune tra i banchi varia da 1K, a 4K, a 8K, a 16K e la sua posizione può essere nell'alto della memoria, nel basso, ed in alto e basso contemporaneamente. Si veda la **fig.2** per la descrizione dei singoli bit di `$d506` e della loro funzione.

| bit | configurazione | funzione |
| --- | -------------- | -------- |
| 1-0 | 00 | 1K ram comune |
| "   | 01 | 4K ram comune |
| "   | 10 | 8K ram comune |
| "   | 11 | 16K ram comune |
| 3-2 | 00 | no ram comune |
| "   | 01 | ram comune in basso |
| "   | 10 | ram comune in alto |
| "   | 11 | ram comune in alto e basso |
| 5-4 | xx | nessuna funzione |
| 6   | 0  | legge la grafica in ram 0 |
|     | 1  | legge la grafica in ram 1 |
| 7   | x  | nessuna funzione |

**(fig.2)**

Se prima di passare in modo 64 selezioniamo 1K di ram comune nell'alto del banco, alla ram1 nella zona da `$fc00` a `$ffff` verrà sovrapposta la ram0: in questa area quindi le operazioni di lettura/scrittura riguarderanno solo la ram0. Di conseguenza i vettori di system reset non potranno essere alterati, perché verranno a trovarsi, appunto, "sotto" la ram0 (si veda **fig.3**).

![spazio per il grafico](#)

**(fig.3)**

A questo punto possiamo essere sicuri che, tornando dal modo 64 "speciale" al modo 128, il computer eseguirà sempre la nostra routine, il cui indirizzo, come già detto, dovrà essere posto in forma low/high nel vettore di system-reset. La nostra routine dovrà semplicemente (!) determinare l'indirizzo della bit-map e della memoria degli attributi colore 1 e 2, prelevare tali dati da ram1, disporli secondo il formato Koala, e registrare su disco il tutto. Per completare la esposizione teorica è necessario spendere dunque due parole sul formato Koala.

## L'ORSETTO PITTORE

I file prodotti da questo programma sono perfettamente compatibili col KoalaPainter: ciò significa che dopo aver estratto le schermate grafiche da un qualsiasi programma, sarà possibile caricarle col Koala e modificarle a nostro piacimento. Un qualsiasi file Koala parte sempre da `$4000`. Da `$4000` a `$5f3f` sono posti i dati della bit-map, da `$5f40` a `$6327` i dati degli attributi colore 1 e 2, da `$6328` a `$670f` i dati degli attributi colore 3, e infine in `$6710` viene posto il colore di sfondo (che la nostra routine, al momento del reset, preleverà direttamente da `$d020`). Anche il nome dei file Koala ha un formato particolare: esso deve essere lungo al massimo 15 caratteri; il primo di essi deve essere un "a" shiftata in reverse, a cui segue il prefisso "pic", uno spazio, una lettera da "a" a "z" usata come identificatore, un altro spazio, e il nome vero e proprio, per il quale restano solo 8 caratteri a disposizione.

## ISTRUZIONI PER L'USO

Innanzitutto digitate il programma in queste pagine, dopodiché salvatelo e verificate che non ci siano errori. Fatto questo, i dati verranno immessi in memoria, e, se non avrete commesso errori, vi verrà richiesta la pressione di un tasto: premendolo, passerete al modo 64, attivando però la ram1. Caricate normalmente il programma da cui volete estrarre la schermata, e, non appena questa apparirà, premete il tasto di reset. Tornati in modo 128, battete: `SYS 5172`. Apparirà un messaggio che vi inviterà a premere spazio per entrare in pagina grafica. Fatto questo, premete un qualsiasi tasto per visualizzare uno dei 4 banchi video da 16k attraverso cui può spaziare l'8564, finché vedrete riapparire la pagina grafica di poco prima! A questo punto, premete `RETURN` e il gioco è fatto. Lo schermo si resetterà e vi verrà chiesta la lettera identificatrice del file Koala: rispondete con una lettera compresa tra "a" e "z". Per ultimo vi verrà chiesto il nome del file: digitandolo (non sarà possibile inserire più di 8 caratteri) e premete `RETURN`. Sul disco verrà così salvato un file contenente la schermata in formato Koala. Per tornare in modo 64 riattivando il programma, digitate pure: `SYS 4864`. Non sarà infatti necessario ricaricare e lanciare il programma caricatore in basic dopo ogni "estrazione": la routine LM, infatti, resterà disponibile in ram0 finché non spegneremo il computer.

## IL TALLONE DI ACHILLE

Qualcuno starà già pensando che era troppo bello per essere vero: in effetti questo programma ha un unico punto debole, cioè le schermate grafiche allocate da `$e000` a `$ffff`. Quando una schermata è allocata in tale zona, la sua parte inferiore avrà le sembianze di un blocco di spazzatura. Ciò avviene perché, come abbiamo detto, da `$fc00` a `$ffff` la ram0 si sovrappone alla ram1. Infatti mentre i dati costituenti la bit-map in questa zona si trovano fisicamente in ram0, il chip video continua a leggerli da ram1: evidentemente il registro di configurazione della ram agisce solo sull'8502, ma non sull'8564. Non è però necessario preoccuparsi: anche se il chip video non può leggerli, i dati della bit-map nell'area `$fc00-$ffff` sono comunque presenti in memoria: sarà necessario, per recuperarli, entrare in monitor dopo aver resettato, quindi battere:

```
T FC00 FFFF 1FFFF
```

dopodiché si potrà dare la `SYS 5172` di attivazione della routine. Ora la situazione è nettamente migliorata, anche se in fondo alla schermata qualche dato è ancora confuso. Questa porzione è comunque così piccola (si tratta di 64 bytes) da non compromettere l'aspetto della schermata: basterà qualche lieve ritocco col Koala. Le schermate non allocate da `$e000`, invece, non presentano nessun problema: esse saranno registrate **INTATTE**.

## NOTE SUL PROGRAMMA L.M.

Passiamo ora ad una breve descrizione delle varie sezioni del programma:

- **$1300-$134f**: esegue `go-64` attivando la ram1. Dapprima trasferisce attraverso la routine di poke ad un altro banco il codice di `go-64` a `$2000` in bank 1, dopodiché salta a eseguirlo. Prima di passare in modo 64 setta il vettore di system-reset a `$13c7`.
- **$1352-$136f**: questa subroutine salva il contenuto della memoria colore al momento del reset, trasferendola da `$d800-$dbe7` a `$1800-$1be7`.
- **$1370-$13c6**: calcola l'indirizzo in ram1 della bit-map e degli attributi colore 1 e 2.
- **$13c7-$13f0**: questa è la routine principale eseguita al momento del reset. Essa salva i valori di `$d018`, `$d020` e `$d021` in appositi registri ombra, salva la memoria colore, e salta a `$e224`, resettando il vettore di system-reset e completando la routine di reset.
- **$13f3-$1433**: fa apparire la pagina grafica presente in ram1.
- **$1434-$168a**: questa è la routine che trasferisce i dati organizzandoli in formato Koala, richiede il Koala ID e il nome del file, registrando infine la schermata su disco.

Come potrete vedere dal disassemblato, il programma appare molto complesso, ma se avete una certa conoscenza del L.M. non faticherete molto a capirlo, soprattutto se la lettura dell'articolo è risultata chiara. Se qualcosa vi sfugge, rileggete l'articolo, dopodiché sarete pronti per nuove (e personali) applicazioni della tecnica descritta (come sarebbe bello poter estrarre quegli sprite stupendamente animati da quel certo gioco... O quel magnifico set di caratteri da quell'altro programma...). Nel frattempo, divertitevi pure a estrarre schermate grafiche e, magari, a scriverci il vostro nome: possiedo un dischetto pieno zeppo di schermate così trattate...
