.segment "CODE"

;------ definitions -----------------
        errvtt = $300 
        baspn  = $3d  
        errsys = $4d3f
        fastser= $e5c3
        fast   = $77b3
        slow   = $77c4 
        open   = $ffc0
        setfil = $ffba
        setnam = $ffbd
        outfil = $ffc9
        bsout  = $ffd2
        clrchn = $ffcc
        close  = $ffc3
        bank15 = $a845
        chrget = $0380
        chftch = $03c9
        rgr    = $818c
        newstt = $af90
        getin  = $ffe4
        scnkey = $ff9f
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
        cmp #135     ; token d1 read?
        bne err      ; se no, errore.
        dec baspn    ; basic=basic-1.
;------------------------------------
        lda baspn    ; controlla se
        cmp #$ff     ; camblo d1 pagi-
        bne confr3   ; na, ed aggiorna
        dec baspn+1  ; puntatore alto.
;------------------------------------
confr3: jsr chftch   ; testo corrente
        cmp #$53     ; uguale ad "s”?
        bne err      ; se no, errore.
        jsr chrget   ; avanza d1 due
        jsr chrget   ; byte nel testo.
        cmp #34      ; virgolette?
        bne err      ; se no, errore.
;-------------------------------------
        jsr chrget   ; prossimo byte.
        ldx #0       ; legge carattere
loop1:  jsr chftch   ; corrente.
        cmp #34      ; virgolette?
        beq cont1    ; se sì, salta.
        sta nome,x   ; deposita byte.
        inx          ; controlla se
        cpx #17      ; len(nomefile) > 16.
        bcs err23    ; se si’, errore.
        inc baspn    ; Incrementa pun—
        bne loop1    ; tatori al testo
        inc baspn+1  ; e continua let-
        bne loop1    ; tura nomefile.
;------------------------------------
cont1:  stx len      ; salva len(nome).
        jsr bank15   ; passa 1n bank15.
;------------------------------------
        lda $d030    ; stores the current
        sta isfast   ; fast mode
        jsr rgr      ; check video mode
        cmp #$05     ; is it 80 col?
        bmi col40    ; if not skips
        jsr fast     ; executes fast
col40:  lda #15
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
loop2:  lda comand,x ; "u0", 159, ed
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
reads2: lda mesg,x
        jsr bsout    ; legge caratteri
        beq nobrst   ; del messaggio
        inx          ; fino allo zero.
        bne reads2
;------------------------------
nobrst: jsr cleanup  ; chiude canale comando
        ldx #255     ; ritorna al basic
        jmp errsys   ; senza errore (x)
;------------------------------
burst:  sei          ; disabilita irq.
        lda #$80     ; inserisce in
        ldy #00      ; due puntatori
        sty $fb      ; ind. di start
        sta $fc      ; del caricamento.
;------------------------------
        lda $dd00    ; azzera bit 4 del
        and #$ef     ; registro I/O
        sta $dd00    ; del cia 2.
        jsr fastser  ; modo fast input.
        lda $dc0d    ; azzera reg. irq.
;------------------------------
start: jsr rdbyte    ; legge stato.
        cmp #2       ; se <2 (tutto ok)
        bcc main     ; salta a routine.
        bne cont2    ; se <>2, salta.
;------------------------------
        jsr cleanup  ; se =2 (file not found)
        ldx #4       ; torna a1 basic
        jmp errsys   ; con errore 4.
;------------------------------
cont2:  cmp #31      ; se status <> 31,
        bne exit     ; esce, altrimenti
        jsr rdbyte   ; legge altro dato
        tax          ; bytes ultimo set-
        jsr entry2   ; tore), e salta.
exit:   jsr cleanup  ; pulisce              
        lda isfast   ; was it fast?
        cmp #$fd     ; 
        beq basic    ; yes, exits. 
        jsr slow     ; execute slow 
basic:  jsr chrget   ; aggiorna testo, e
        jmp newstt   ; salta a basic execute.
;---------------------------------
main:   lda $fc      ; raggiunto limite
        cmp #$f0     ; della memoria?
        bcc vai      ; se no, goto 143.
        jsr cleanup  ; se si, pulisce 
        ldx #16      ; ed esce con out
        jmp errsys   ; of memory error.
vai:    jsr rdblk    ; legge un settore
        jmp start    ; e ricomincia.
;------ s u b r o u t i n e s -------
cleanup:lda #15      ; chiude canale di 
        jsr close    ; comando
        cli          ; ripristina irq
        rts          ; torna
;------------------------------------
rdblk:  ldx #254     ; bytes per blocco.
entry2: ldy #0       ; offset scrittura.
reads:  jsr rdbyte   ; legge un byte.
;       sta $ff01    ; passa in bank 0.
;       sta ($fb),y  ; deposita byte.
        jsr bsout    ;
        lda $dc01
        cmp #$7f
        beq exit 
;       lda #0       ; commuta memoria
;       sta $ff00    ; in banco 15.
loop3:  iny          ; continua a leg-
        dex          ; gere gli altri
        bne reads    ; byte dal blocco.
;-----------------------------------
        tya          ; aggiorna punta-
        clc          ; tori di pagina
        adc $fb      ; zero sommando
        sta $fb      ; loro il numero
        bcc return   ; di byte preleva-
        inc $fc      ; ti dal blocco.
return: rts          ; return.
;-----------------------------------
rdbyte: lda $dd00    ; inverte bit 4
        eor #16      ; registro i/o
        sta $dd00    ; del cia.
        lda #8       ; attende che un
wating: bit $dc0d    ; irq modifichi
        beq wating   ; bit 4 di cia irq.
        lda $dc0c    ; legge byte.
        rts          ; return.
;-------- buffer caratteri ---------
isfast: .byte $00
mesg:   .byte $44,$52,$49,$56,$45,$20,$4e,$4f,$4e,$20,$46,$41,$53,$54
        .byte $00
comand: .byte $55,$30,$9f
nome:   .byte $00
