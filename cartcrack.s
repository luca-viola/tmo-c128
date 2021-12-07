.segment "code"
        lda #$00    ;repara i puntatori a $2000 in ram 1 per
        sta $fa     ;trasferirvi il codice di go-64,e mette
        lda #$20    ;
        sta $fb     ;
        lda #$fa    ;in $2b9 il puntatore $fa
        sta $02b9   ;
        ldy #$00    ;azzera offset
loop1:  lda $132e,y ;preleva da ram 0 il codice di go-64
        ldx #$01    ;selezione del bank 1
        jsr $ff77   ;routine di store to another bank
        iny         ;continua finche' trasferisce tutto il codice
        cpy #$27    ;
        bne loop1   ;
        jsr $e224   ;resetta la stringa  di system-reset
        lda #$01    ;
        ldy #$20    ;
        ldx #$00    ;
        sta $02     ;in $02 numero banco
        sty $03     ;in $03/$04 indirizzo di salto in forma hi-low
        stx $04     ;
        jmp $ff71   ;jmp to another bank
        lda #$7e    ;esegue go-64:setta ram 1 + / 
        sta $ff00   ;
        lda #$c7    ;punta il vettore di system-reset all'ingresso
        sta $fff8   ;della nostra routine locata a $ 13c7
        lda #$13    ;
        sta $fff9   ;
        lda #$e3    ;resetta le porte di / dell'8502
        sta $01     ;
        lda #$2f    ;
        sta $00     ;
        lda #$48    ;abilita il - a leggere la grafica in ram 1
        sta $d506   ;e pone la ram comune nell'alto della memoria
        lda #$f7    ;abilita le  del 64
        sta $d505   ;
        jmp $fce2   ;e salta alla routine di reset del c/64
        ldx #$00    ;subroutine 1:salva nelle locazioni $1800-$1bff
loop2:  lda $d800,x ;i codici della memoria colore presenti in modo
        sta $1800,x ;64 al momento del reset
        lda $d900,x ;
        sta $1900,x ;
        lda $da00,x ;
        sta $1a00,x ;
        lda $db00,x ;
        sta $1b00,x ;
        inx         ;
        bne loop2   ;
        rts         ;e ritorna
        lda $17f3   ;subroutine 2:setta i puntatori alla bit-map e alla
        and #$03    ;memoria colore tenendo conto del banco video il cui
        sta $fa     ;valore e' contenuto in $ 17f3
        lda #$03    ;bank video=3-(peek(56576)and 3)
        sec         ;pone il risultato della precedente operazione
        sbc $fa     ;in $fa
        sta $fa     ;
        ldx #$00    ;e lo moltiplica per 16384 determinando cosi'
loop3:  asl $fa     ;la locazione iniziale dell'attuale bank video
        rol $fb     ;
        inx         ;
        cpx #$0e    ;
        bne loop3   ;
        lda $fa     ;trasferisce i puntatori alla locazione iniziale del bank
        sta $fc     ;video nei puntatori alla bit-map
        lda $fb     ;
        sta $fd     ;
        lda $17f0   ;prende il valore di $d018 per testarne il bit 3:
        and #$08    ;
        beq $13a6   ;se non e' settato,va oltre,
        lda #$00    ;altrimenti la bit-map inizia 8192 bytes dopo la locazione
        clc         ;iniziale dell' attuale bank video,
        adc $fa     ;e addiziona 8192 al puntatore bit-map
        sta $fc     ;
        lda #$20    ;
        clc         ;
        adc $fb     ;
        sta $fd     ;
        lda $17f0   ;determina la locazione iniziale della memoria degli
        and #$f0    ;attributi colore 1 e 2 secondo la formula
        sta $fe     ;lc=(peek(53272)and240)*64
        ldx #$00    ;
        asl $fe     ;
        rol $ff     ;
        inx         ;
        cpx #$06    ;
        bne $13af   ;
        lda $fe     ;addiziona ai puntatori alla memoria colore la locazione
        clc         ;iniziale del bank video
        adc $fa     ;
        sta $fe     ;
        lda $ff     ;
        clc         ;
        adc $fb     ;
        sta $ff     ;
        rts         ;e ritorna
        lda $d018   ;routine eseguita al momento del reset:preleva i valori di
        sta $17f0   ;$d018,$d020,$d021 e li salva in appositi
        lda $d020   ;registri-ombra
        sta $17f1   ;
        lda $d021   ;
        sta $17f2   ;
        lda #$00    ;setta il bank video numero 3
        sta $17f3   ;
        jsr $1352   ;salva la memoria colore
        jsr $1370   ;calcola i puntatori bit-map e colori 1 e 2 relativi
        ldx #$00    ;al bank video 3 e salva i puntatori da $fa a $ff in
        lda $fa,x   ;locazioni di comodo per far si' che il loro valore non
        sta $17f5,x ;venga distrutto dalla routine di reset
        inx         ;
        cpx #$06    ;
        bne $13e6   ;
        jmp $e224   ;resetta la stringa  e prosegue il reset
        lda #$ff    ;subroutine 4:fa apparire la pagina grafica
        sta $d8     ;presente al momento del reset.
        lda #$70    ;sclude l'editor grafico a interrupt del c128
        sta $01     ;e seleziona la 2a memoria colore posta in $d800-$dbe7
        ldx #$00    ;
        lda $1800,x ;e vi trasferisce gli attributi del colore 3
        sta $d800,x ;
        lda $1900,x ;
        sta $d900,x ;
        lda $1a00,x ;
        sta $da00,x ;
        lda $1b00,x ;
        sta $db00,x ;
        inx         ;
        bne $13fd   ;
        lda #$a0    ;esegue graphic 3
        sta $d8     ;
        lda $17f0   ;prende il valore di $ d018 prima salvato e lo
        sta $0a2d   ;pone nel registro-ombra dell' editor grafico del c-128
        lda $17f1   ;imposta i colori di bordo e sfondo presenti al
        sta $d020   ;momento del reset
        lda $17f2   ;
        sta $d021   ;
        lda #$44    ;abilita il   a leggere la grafica in ram 1
        sta $d506   ;
        rts         ;e ritorna
        lda #$00    ;main routine : setta il colore nero per sfondo e bordo
        sta $d020   ;
        sta $d021   ;
        lda #$05    ;mette il colore verde per le scritte
        sta $f1     ;
        lda #$93    ;pulisce lo schermo
        jsr $ffd2   ;
        ldy #$00    ;punta il cursore a (0;7)
        ldx #$07    ;
        clc         ;
        jsr $fff0   ;routine plot del kernal
        jsr $ff7d   ;stampa il messaggio che segue
        .byte "premi spazio per entrare in pagina"
        .byte $20,$20,$20,$20,$0d,$0d
        .byte "grafica e per cambiare banco video"
        .byte $0d,$0d,$0d
        .byte "<return> per confermare"
        .byte 00     ;finche' incontra un byte=0
        lda $d4     ;attende la pressione di spazio
        cmp #$3c    ;
        bne $14b5   ;
        ldx #$00    ;prende i valori prima salvati dei puntatori
        lda $17f5,x ;
        sta $fa,x   ;e li rimette in $fa
        inx         ;
        cpx #$06    ;
        bne $14bd   ;
        jsr $13f3   ;visualizza la pagina grafica
        ldy #$00    ;
        lda $d4     ;esamina il tasto premuto:
        cmp #$01    ;e' return?
        beq $1509   ;si',va a routine di transfer & save
        cmp #$58    ;vi sono tasti premuti?
        beq $14f5   ;no,va oltre e azzera il flag di tasto premuto
        ldx $17fe   ;si':controlla il flag e,se e' gia' impostato,
        cpx #$ff    ;significa che un tasto e' stato premuto e non
        beq $14cc   ;ancora rilasciato,e quindi ricomincia daccapo
        lda #$ff    ;se c'e' un tasto premuto e il flag e' azzerato,
        sta $17fe   ;imposta il flag,
        iny         ;incrementa il numero del bank video
        cpy #$04    ;riportandolo a zero quando e' >= a 4
        bmi $14e9   ;
        ldy #$00    ;
        sty $dd00   ;imposta il nuovo bank video e ne pone il valore
        sty $17f3   ;nella locazione usata per calcolare i puntatori
        jsr $1370   ;calcola i puntatori relativi all' attuale bank video
        jmp $14cc   ;e ricomincia il ciclo daccapo
        lda #$00    ;azzera flag di tasto premuto
        sta $17fe   ;
        jmp $14cc   ;e ricomincia daccapo
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;
        brk         ;routine di transfer & save:
        lda #$04    ;riabilita il vic  a leggere la grafica in ram 0
        sta $d506   ;
        lda #$00    ;setta i puntatori a $4000
        sta $fa     ;
        lda #$40    ;
        sta $fb     ;
        lda #$fa    ;prepara puntatore per routine di 
        sta $02b9   ;
        ldy #$00    ;azzera offset
        ldx #$01    ;seleziona bank 1
        lda #$fc    ;puntatore alla bit-map
        jsr $ff74   ;prende un byte dalla bit-map
        ldx #$00    ;seleziona ram 0
        jsr $ff77   ;deposita il byte prelevato nella locazione puntata da
        iny         ;$fa/$fb,
        bne $151d   ;
        inc $fb     ;ripete per 8192 bytes
        inc $fd     ;
        lda $fb     ;
        cmp #$60    ;
        bne $151b   ;
        lda #$40    ;rispettando il formato koala,trasferisce la memoria de-
        sta $fa     ;gli attributi colore 1 e 2 puntata da $fe/$ff
        lda #$5f    ;dal bank 1 al bank 0 nelle locazioni $5f40/$6327
        sta $fb     ;
        lda #$fa    ;
        sta $02b9   ;
        ldy #$00    ;
        ldx #$01    ;
        lda #$fe    ;
        jsr $ff74   ;
        ldx #$00    ;
        jsr $ff77   ;
        iny         ;
        bne $1545   ;
        inc $fb     ;
        inc $ff     ;
        lda $fb     ;
        cmp #$64    ;
        bne $1543   ;
        ldx #$00    ;sempre secondo il formato koala,trasferisce
        lda $1800,x ;gli attributi del colore 3 nelle locazioni
        sta $6328,x ;$6328-$670f
        lda $1900,x ;
        sta $6428,x ;
        lda $1a00,x ;
        sta $6528,x ;
        lda $1b00,x ;
        sta $6628,x ;
        inx         ;
        bne $1560   ;
        lda $17f2   ;prende il colore di fondo e lo pone in coda
        sta $6710   ;ai dati prima trasferiti
        jsr $ff84   ;resetta l' /
        jsr $c000   ;e l' editor di schermo
        ldx #$00    ;trasferisce in zona di lavoro il nome del file
        lda $167a,x ;costituito ancora da spazi
        sta $17d0,x ;
        inx         ;
        cpx #$10    ;
        bne $1589   ;
        lda #$00    ;pone sfondo e bordo in nero
        sta $d020   ;
        sta $d021   ;
        lda #$0c    ;colore grigio scuro per le frasi da stampare
        sta $f1     ;
        ldy #$00    ;punta il cursore in posizione home
        ldx #$00    ;
        clc         ;
        jsr $fff0   ;routine  del kernal
        jsr $ff7d   ;stampa il messaggio che segue
        .asciiz "koala id (a-z):"
        jsr $ffe4   ;prende un carattere  dalla tastiera,
        cmp #$0d    ;e se e' return ne prende un altro
        beq $15bb   ;
        cmp #$41    ;idem se il codice e' piu' piccolo di "a"
        bmi $15bb   ;
        cmp #$5b    ;o se e'
        bpl $15bb   ;
        sta $17d5   ;mette l'identificatore koala nel nome
        jsr $ffd2   ;del file e lo stampa su video
        ldx #$00    ;stampa tre carriage return
        lda #$0d    ;
        jsr $ffd2   ;
        inx         ;
        cpx #$03    ;
        bne $15d4   ;
        jsr $ff7d   ;stampa il messaggio che segue
        .asciiz "insert name (8 char max.):"
        ldx #$1a    ;setta il bordo superiore sinistro di una finestra
        lda #$03    ;alle coordinate (26;3)
        clc         ;
        jsr $c02d   ;
        ldx #$21    ;e setta il bordo inferiore destro alle coordinate
        lda #$03    ;(33;3)
        sec         ;
        jsr $c02d   ;
        lda #$1b    ;esegue esc+"m" (disabilita lo scroll verticale)
        jsr $ffd2   ;
        lda #$4d    ;
        jsr $ffd2   ;
        lda #$13    ;attiva la finestra
        jsr $ffd2   ;
        ldy #$00    ;prende il nome del file
        jsr $ffcf   ;
        cmp #$0d    ;fino alla pressione del tasto return
        beq $162a   ;
        sta $17d7,y ;mette il nome del file in area di lavoro
        iny         ;
        cpy #$0a    ;per un massimo di 8 caratteri
        bmi $161b   ;
        lda #$13    ;resetta la finestra stampando 2 volte [home]
        jsr $ffd2   ;
        lda #$13    ;
        jsr $ffd2   ;
        lda #$1b    ;esegue esc+"l"
        jsr $ffd2   ;
        lda #$4c    ;
        jsr $ffd2   ;
        lda #$93    ;pulisce lo schermo
        jsr $ffd2   ;
        ldx #$00    ;stampa 10 carriages return
        lda #$0d    ;
        jsr $ffd2   ;
        inx         ;
        cpx #$0a    ;
        bne $1645   ;
        lda #$0f    ;lunghezza del nome : 15 caratteri
        ldx #$d0    ;indirizzo file name : $17d0
        ldy #$17    ;
        jsr $ffbd   ;set up file name
        lda #$00    ;banco in cui si trova il nome file=0
        ldx #$00    ;banco da cui registrare il file=0
        jsr $ff68   ;setbank
        lda #$00    ;canale 0
        ldx #$08    ;periferica 8
        ldy #$00    ;canale secondario 0
        jsr $ffba   ;set files
        lda #$00    ;prepara i puntatoria $4000 per operazione di save
        sta $fa     ;
        lda #$40    ;
        sta $fb     ;
        lda #$fa    ;in a puntatore alla locazione iniziale del file da salvare
        ldx #$11    ;locazione finale del file da salvare + 1 = 
        ldy #$67    ;                                                             01676 jsr $ffd8   ;esegue 
        rts         ;ed esce
        .byte $81    ;
        .byte "pic a"
        .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20        
