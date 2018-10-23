.org $1300 ; start a 4864
.segment "CODE"

;------ definitions -----------------
        errvtt = $300 
        baspn  = $3d  
        errsys = $4d3f
        fast   = $e5c3
        open   = $ffc0
        setfil = $ffba
        setnam = $ffbd
        outfil = $ffc9
        bsout  = $ffd2
        clrchn = $ffcc
        close  = $ffc3
        bank15 = $a845
        len    = $fa
;------------------------------------
        lda #<rout   ; dirotta vettore
        ldx #>rout   ; routine di er-
        sta errvtt   ; rore a riga
        stx errvtt+1 ; rout e torna
        rts          ; al basic.
;------------------------------------
err23:  ldx #23      ; string too long.
err:    jmp errsys   ; esce ad errore.
;------------------------------------
rout:   cpx #11      ; syntax error?
        bne err      ; se no, errore.
        cmp #147     ; token d1 load?
        bne err      ; se no, errore.
        dec baspn    ; basic=basic-1.
;------------------------------------
        lda baspn    ; controlla se
        cmp #$ff     ; camblo d1 pagi-
        bne confr3   ; na, ed aggiorna
        dec baspn+1  ; puntatore alto.
;------------------------------------
confr3: jsr $3c9     ; testo corrente
        cmp #$53     ; uguale ad "s”?
        bne err      ; se no, errore.
        jsr $380     ; avanza d1 due
        jsr $380     ; byte nel testo.

        cmp #34      ; virgolette?
        bne err      ; se no, errore.
;-------------------------------------
        jsr $380     ; prossimo byte.
        ldx #0       ; legge carattere
loop1:  jsr $3c9     ; corrente.
        cmp #34      ; virgolette?
        beq cont1    ; se si', salta.
        sta nome,x   ; deposita byte.
        inx          ; controlla se
        cpx #17      ; len(nomefile) > 16.
        bcs err23    ; se si’, errore.
        inc baspn    ; Incrementa pun—
        bne loop1    ; tatori al testo
        inc baspn+1  ; e contlnua let-
        bne loop1    ; tura nomefile.
;------------------------------------
cont1:  stx len      ; salva len(nome).
        jsr bank15   ; passa 1n bank15.
;------------------------------------
        lda #15
        ldx #8
        tay
        jsr setfil   ; Open15.8,15.
        lda #0
        jsr setnam
        jsr open
;------------------------------------
        lda $a1c     ; azzera bit 6
        and #$bf     ; indicatore d1
        sta $a1c     ; fast serial.
        ldx #15      ; file 15 aperto
        jsr outfil   ; in output.
;------------------------------------
        lda len 
        adc #3       ; legge ed invia
        tay          ; sul canale di
        ldx #0       ; comando (15)
loop2:  lda comand,x ; "u0”, 159, ed
        jsr bsout    ; i caratteri
        inx          ; del nome del

        dey          ; file seq.
        bne loop2
;------------------------------
        jsr clrchn   ; segnale al drive
        bit $a1c     ; se bit 6 di fast
        bvs burst    ; serial=1, salta.
;------------------------------
        ldx #0
legge2: lda mesg,x
        jsr bsout    ; legge caratteri
        beq nofast   ; del messaggio
        inx          ; fino allo zero.
        bne legge2
;------------------------------
nofast: lda #15      ; chiude canale
        jsr close    ; di comando a
        ldx #255     ; ritorna al basic
        jmp errsys   ; senza errore (x)
;------------------------------
burst:  sei          ; disabilita irq.
        lda #$80     ; inserisce in
        ldy #00      ; due puntatori
        sty $fb      ; ind. di inizio
        sta $fc      ; del caricamento.
;------------------------------
        lda $dd00    ; azzera bit 4 del
        and #$ef     ; registro I/O
        sta $dd00    ; del cia 2.
        jsr fast     ; modo fast input.
        lda $dc0d    ; azzera reg. irq.
;------------------------------
inizio: jsr legbyt   ; legge stato.
        cmp #2       ; se <2 (tutto ok)
        bcc main     ; salta a routine.
        bne cont2    ; se <>2, salta.
;------------------------------
        lda #15      ; se =2 (file not
        jsr close    ; found), chiude
        ldx #4       ; canale 15, e
        cli          ; torna a1 basic
        jmp errsys   ; con errore 4.
;------------------------------
cont2:  cmp #31      ; se status <> 31,
        bne uscita   ; esce, altrimenti
        jsr legbyt   ; legge altro dato

        tax          ; bytes ultimo set-
        jsr entry2   ; tore), e salta.
uscita: cli          ; riabilita irq.
        lda #15      ; chiude canale
        jsr close    ; di comando.
        jsr $380     ; aggiorna testo, e
        jmp $af90    ;  salta a execute.
;---------------------------------
main:   lda $fc      ; raggiunto limite
        cmp #$f0     ; della memoria?
        bcc vai      ; se no, goto 143.
        lda #15      ; se si, chiude
        jsr close    ; canale comandi.
        ldx #16      ; ed esce con er-
        cli          ; rore 16 (out of
        jmp errsys   ; memory.
vai:    jsr legblk   ; legge un settore
        jmp inizio   ; e ricomxncia.
;------ s u b r o u t i n e s -------

legblk: ldx #254     ; bytes per blocco.
entry2: ldy #0       ; offset scrittura.
legge:  jsr legbyt   ; legge un byte.
        sta $ff01    ; passa in bank 0.
        sta ($fb),y  ; deposita byte.
        lda #0       ; commuta memoria
        sta $ff00    ; in banco 15.
        iny          ; continua a leg-
        dex          ; gere gli altri
        bne legge    ; byte dal blocco.
;-----------------------------------
        tya          ; aggiorna punta-
        clc          ; tori di pagina
        adc $fb      ; zero sommando
        sta $fb      ; loro il numero
        bcc return   ; di byte preleva-
        inc $fc      ; ti dal blocco.
return: rts          ; return.
;-----------------------------------
legbyt: lda $dd00    ; inverte bit 4
        eor #16      ; registro i/o
        sta $dd00    ; del cia.
        lda #8       ; attende che un
attesa: bit $dc0d    ; irq modifichi
        beq attesa   ; bit 4 di cia irq.
        lda $dc0c    ; legge byte.
        rts          ; return.
;-------- buffer caratteri ---------
mesg:   .byte $44,$52,$49,$56,$45,$20,$4e,$4f,$4e,$20,$46,$41,$53,$54
        .byte $00
comand: .byte $55,$30,$9f
nome:   .byte $00
.end
