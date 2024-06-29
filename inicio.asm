global main

%macro mPuts 0
    sub     rsp,8
    call    puts
    add     rsp,8
%endmacro

%macro mGets 0
    sub     rsp,8
    call    gets
    add     rsp,8
%endmacro

extern puts
extern gets
extern sscanf
extern fopen
extern fgets
extern printf
extern fputs
extern fclose

section .data
    tablero     db  0, 0, 1, 1, 1, 0, 0
                db  0, 0, 1, 1, 1, 0, 0
                db  1, 1, 1, 1, 1, 1, 1
                db  1, 2, 2, 2, 2, 2, 1
                db  1, 2, 2, 3, 2, 2, 1
                db  0, 0, 2, 2, 2, 0, 0
                db  0, 0, 2, 2, 2, 0, 0

    salto_linea                 db 10, 0        
    simbolo_fuera_tablero       db ".", 0
    simbolo_oca                 db 'O', 0
    simbolo_zorro               db 'X', 0
    simbolo_espacio_vacio       db ' ', 0
    simbolo_separador           db '|', 0
    ;longfila                    db 7     ME TIRA ERROR USANDO VARIABLE, HARDCODEO EL 7 POR EL MOMENTO

    mensaje_mover_oca                   db "Ingrese la fila y columna de la oca a mover (ejemplo: 3 3). Presione f para salir de la partida: ", 0
    mensaje_mover_oca_direccion         db "Mueva la oca con w: arriba /a: izquierda /s: abajo /d: derecha. Presione f para salir de la partida: ", 0
    formatInputFilCol                   db "%hhu %hhu", 0                               ; Formato para leer enteros de 1 byte
    msjErrorInput                       db "Los datos ingresados son inválidos. Intente nuevamente.", 0
    mensaje_mover_zorro                 db "Mueva el zorro con w: arriba /a: izquierda /s: abajo /d: derecha /e: arriba-derecha /q: arriba-izquierda /z: abajo-izquierda /x: abajo-derecha. Presione f para salir de la partida: ", 0
    mensaje_mov_invalido                db "Movimiento invalido, intente nuevamente", 0
    mensaje_ingresar_j1                 db "Ingrese el nombre del jugador 1 (zorro): ", 0
    mensaje_ingresar_j2                 db "Ingrese el nombre del jugador 2 (ocas): ", 0
    mensaje_ganador                     db "El ganador es: ", 0
    mensaje_fin_juego                   db "El juego ha sido abandonado.", 0
    
    ;Variables de archivo
    archivoTablero              db      "tablero.txt",0
    modoAperturaRead            db      "r",0   ; Abro y leo un archivo de texto
    modoAperturaWrite           db      "w",0
    archivoEstadisticas         db      "estadisticas.txt",0

    msgErrorAp                  db      "Lo sentimos, no se pudo abrir el archivo.",10,0
    msgErrorLectura             db      "No se encontró una partida guardada, se iniciará una nueva.",10,0
    msgLeido                    db      "Leído con éxito.",10,0
    msgErrorConvirt             db      "Error convirtiendo el numero",10,0
    msgErrorEscritura           db      "Error escribiendo el archivo",10,0
    msgPartidaGuardada          db      "Se ha encontrado una partida guardada, desea continuarla? (si/no)",10,0
    msgGuardarPartida           db      "Estás saliendo del juego, querés guardar tu partida? (si/no)",10,0
    respuestaSi                 db      "si",0
    registro          times 51  db      " "
    tableroStr        times 51  db      " "
    
    estadisticas      times 0   db      ''
        turnoGuardado           db      " "
        cantOcasComidas         db      " "


    CANT_FIL_COL        equ     7
    DESPLAZ_LIMITE      equ     48
    TURNO_ZORRO         equ     1
    TURNO_OCAS          equ     2


section .bss
    buffer          resb 350  ; Suficiente espacio para el tablero con saltos de línea
    input_oca       resb 10
    fila            resb 1
    columna         resb 1
    inputValido     resb 1
    posicion_oca    resq 1
    input_zorro     resb 10
    nombre_jugador1 resb 50
    nombre_jugador2 resb 50
    turno           resb 1

    ;Variables de archivo
    handleArch                  resq  1
    numero                      resb  1
    posicionVect                resb  1
    posicionMatFil              resb  1
    posicionMatCol              resb  1
    respuestaPartidaGuardada    resb  4

section .text
main:
    mov     rdi, archivoTablero
    call    abrirLecturaArchivo
    cmp     rax, 0
    jle     errorApertura
        
    call    leerArchivoTablero  
    cmp     rax, 0
    jle     errorLeyendoArchivo

    mov     rdi, msgPartidaGuardada
    mPuts
    mov     rdi, respuestaPartidaGuardada
    mGets
    mov     rcx, 2
    lea     rsi, [respuestaSi]
    lea     rdi, [respuestaPartidaGuardada]
    repe    cmpsb
    jne     continuar_jugando
    call    copiarRegistroATablero
    call    cerrarArchivo

    call    cargarEstadisticas

continuar_jugando:
    sub     rsp,8
    call    ingresar_nombres_jugadores        ;llamo a la subrutina para ingresar nombres
    add     rsp,8

    sub     rsp,8
    call    construir_tablero       ;llamo a la subrutina para construir el tablero inicial
    add     rsp,8

    sub     rsp,8
    call    imprimir_tablero        ;llamo a la subrutina para imprimir el tablero
    add     rsp,8

loop_juego:
    mov     al, [turno]     ; veo de quien es el turno
    cmp     al, 1
    je turno_zorro          ; si es el turno del zorro, voy a la etiqueta turno_zorro
    cmp     al, 2
    je turno_ocas           ; si es el turno de las ocas, voy a la etiqueta turno_ocas

turno_zorro:
    sub     rsp,8
    call    pedir_movimiento_zorro  ;llamo a la subrutina para pedir movimiento del zorro
    add     rsp,8
    cmp     byte [input_zorro], 'f' ; Verificar si se desea abandonar la partida
    je      guardar_partida
    sub     rsp,8
    call    mover_zorro              ;llamo a la subrutina para mover al zorro
    add     rsp,8
    cmp     byte [inputValido], 'R'  ;comparo si el movimiento del zorro fue inválido
    je      turno_zorro              ;si fue inválido, vuelvo a pedir movimiento del zorro
    mov     byte [turno], TURNO_OCAS          ;si fue válido, cambio el turno a las ocas
    jmp     continuar_juego          ;voy a la etiqueta continuar_juego

turno_ocas:
    sub     rsp,8
    call    pedir_movimiento_oca     ;llamo a la subrutina para pedir movimiento de la oca
    add     rsp,8
    cmp     byte [input_oca], 'f'    ; Verificar si se desea abandonar la partida
    je      guardar_partida
    sub     rsp,8
    call    mover_oca                ;llamo a la subrutina para mover la oca
    add     rsp,8
    cmp     byte [inputValido], 'R'  ;comparo si el movimiento de la oca fue inválido
    je      turno_ocas               ;si fue inválido, vuelvo a pedir movimiento de la oca
    mov     byte [turno], TURNO_ZORRO          ;si fue válido, cambio el turno al zorro

continuar_juego:
    sub     rsp,8
    call    construir_tablero       ;reconstruyo el tablero después de cada turno
    add     rsp,8
    sub     rsp,8
    call    imprimir_tablero        ;imprimo el tablero después de cada turno
    add     rsp,8
    jmp     loop_juego              ;vuelvo al inicio del bucle del juego

    ret

ingresar_nombres_jugadores:
    mov     rdi, mensaje_ingresar_j1   
    mPuts
    mov     rdi, nombre_jugador1              ; guardo el nombre de cada jugador
    mGets
    mov rdi, mensaje_ingresar_j2
    mPuts
    mov rdi, nombre_jugador2
    mGets

    mov byte [turno], TURNO_ZORRO  ; Comienza el turno del zorro
    ret

construir_tablero:
    mov     rbx, 1            ; i que será la fila, iniciada en 1 y no aumenta hasta no terminar las 7 columnas
    mov     r10, 1            ; j que será la columna
    mov     rdi, buffer       ; Apuntar al inicio del buffer

imprimir_siguiente_caracter:   
    mov     rax, rbx
    dec     rax
    imul    rax, rax, 7       ; (i-1) * longfila
    mov     rdx, r10
    dec     rdx
    add     rax, rdx          ; (i-1) * longfila + (j-1)
    mov     rsi, tablero
    add     rsi, rax          ; rsi apunta a la posición actual en el tablero

    cmp     byte [rsi], 0      ;segun el numero en tablero imprimo un caracter distinto
    je      imprimir_fuera_tablero                
    cmp     byte [rsi], 2           
    je      imprimir_espacio_vacio              
    cmp     byte [rsi], 1         
    je      imprimir_oca
    cmp     byte [rsi], 3
    je      imprimir_zorro

imprimir_fuera_tablero:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_fuera_tablero]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

imprimir_oca:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_oca]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

imprimir_zorro:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_zorro]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

imprimir_espacio_vacio:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_espacio_vacio]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

continuar_construyendo_tablero:
    inc     r10                ; Incrementar en uno para tener la siguiente columna
    cmp     r10, 8             ; Si no llegué a la columna 7, construyo el siguiente elemento de la misma fila              
    jl      imprimir_siguiente_caracter       

    ; Añadir un salto de línea al final de la fila
    mov     al, [salto_linea]
    stosb
    mov     r10, 1
    inc     rbx                ; Incremento en uno la fila (siguiente fila)
    cmp     rbx, 8             ; Si llegué a la fila 7, termino la construcción
    je      fin_construir_tablero

    jmp     imprimir_siguiente_caracter

fin_construir_tablero:
    ret

imprimir_tablero:
    mov     rdi, buffer
    mPuts
    ret

pedir_movimiento_zorro:
    mov rdi, mensaje_mover_zorro
    mPuts
    mov rdi, input_zorro
    mGets
    ret

mover_zorro:
    mov rsi, tablero
    mov rcx, 49

buscar_zorro:
    lodsb
    cmp al, 3
    je zorro_encontrado
    loop buscar_zorro
    ret

zorro_encontrado:
    mov rbx, rsi   ; Mueve el valor del registro rsi (posición actual del zorro) a rbx
    dec rbx         ; Decrementa rbx en 1 para apuntar correctamente a la posición actual del zorro

    mov rdi, input_zorro
    mov al, [rdi]
    cmp al, 'w'
    je mover_zorro_arriba
    cmp al, 's'
    je mover_zorro_abajo
    cmp al, 'a'
    je mover_zorro_izquierda
    cmp al, 'd'
    je mover_zorro_derecha
    cmp al, 'e'
    je mover_zorro_arriba_derecha
    cmp al, 'q'
    je mover_zorro_arriba_izquierda
    cmp al, 'z'
    je mover_zorro_abajo_izquierda
    cmp al, 'x'
    je mover_zorro_abajo_derecha
    ret

mover_zorro_arriba:
    sub rbx, 7                  ; resto 7 a rbx para mover al zorro una fila hacia arriba
    jmp validar_movimiento_zorro 

mover_zorro_abajo:
    add rbx, 7                  ; sumo 7 a rbx para mover al zorro una fila hacia abajo
    jmp validar_movimiento_zorro

mover_zorro_izquierda:
    dec rbx                     ; resto 1 a rbx para mover al zorro una columna a la izquierda
    jmp validar_movimiento_zorro

mover_zorro_derecha:
    inc rbx                     ; sumo 1 a rbx para mover al zorro una columna a la derecha
    jmp validar_movimiento_zorro

mover_zorro_arriba_derecha:
    sub rbx, 6                  ; resto 6 a rbx para mover al zorro en diagonal arriba derecha
    jmp validar_movimiento_zorro

mover_zorro_arriba_izquierda:
    sub rbx, 8                  ; resto 8 a rbx para mover al zorro en diagonal arriba izquierda
    jmp validar_movimiento_zorro

mover_zorro_abajo_izquierda:
    add rbx, 6                  ; sumo 6 a rbx para mover al zorro en diagonal abajo izquierda
    jmp validar_movimiento_zorro

mover_zorro_abajo_derecha:
    add rbx, 8                   ; sumo 8 a rbx para mover al zorro en diagonal abajo derecha
    jmp validar_movimiento_zorro

validar_movimiento_zorro:
    cmp byte [rbx], 2           ; Comparar destino con una posición vacía (2)
    jne movimiento_invalido_zorro         
    mov byte [rsi - 1], 2       ; Actualizar la posición anterior del zorro con 2 (vacío)
    mov byte [rbx], 3           ; Colocar al zorro en la nueva posición
    mov byte [inputValido], 'S' ; Indicar que el movimiento fue válido
    ret

movimiento_invalido_zorro:
    mov byte [inputValido], 'R'
    mov rdi, mensaje_mov_invalido
    mPuts
    ret

pedir_movimiento_oca:
    mov rdi, mensaje_mover_oca
    mPuts
    mov rdi, input_oca
    mGets
    cmp byte [input_oca], 'f'    ; Verificar si se desea abandonar la partida
    je fin_juego
    ; Validar las coordenadas de la oca
    sub rsp,8
    call validar_coordenadas_oca
    add rsp,8
    cmp byte [inputValido], 'S'
    je pedir_direccion_oca

    mov rdi, msjErrorInput
    mPuts
    sub rsp,8
    call pedir_movimiento_oca
    add rsp,8
    ret

pedir_direccion_oca:
    mov rdi, mensaje_mover_oca_direccion
    mPuts
    mov rdi, input_oca
    mGets
    ret

mover_oca:
    mov rsi, tablero
    ; Calcular la posición en el tablero
    mov rbx, [posicion_oca]

    ; Leer la dirección de movimiento
    mov rdi, input_oca
    mov al, [rdi]
    cmp al, 'w'
    je mover_oca_arriba
    cmp al, 's'
    je mover_oca_abajo
    cmp al, 'a'
    je mover_oca_izquierda
    cmp al, 'd'
    je mover_oca_derecha
    ret

mover_oca_arriba:
    sub rbx, 7
    jmp validar_movimiento_oca

mover_oca_abajo:
    add rbx, 7
    jmp validar_movimiento_oca

mover_oca_izquierda:
    dec rbx
    jmp validar_movimiento_oca

mover_oca_derecha:
    inc rbx
    jmp validar_movimiento_oca

validar_movimiento_oca:
    cmp byte [rbx], 2
    jne movimiento_invalido_oca
    mov rsi, [posicion_oca]
    mov byte [rsi], 2          ; Actualizar la posición anterior de la oca con 2 (vacío)
    mov byte [rbx], 1          ; Colocar la oca en la nueva posición
    mov byte [inputValido], 'S' ; Indicar que el movimiento fue válido
    ret

movimiento_invalido_oca:
    mov byte [inputValido], 'R'
    mov rdi, mensaje_mov_invalido
    mPuts
    ret

validar_coordenadas_oca:
    mov byte [inputValido], 'N'
    mov rdi, input_oca
    mov rsi, formatInputFilCol
    mov rdx, fila
    mov rcx, columna
    sub rsp,8
    call sscanf
    add rsp,8

    cmp rax, 2
    jl coordenadas_invalidas

    cmp byte [fila], 1
    jl coordenadas_invalidas
    cmp byte [fila], 7
    jg coordenadas_invalidas

    cmp byte [columna], 1
    jl coordenadas_invalidas
    cmp byte [columna], 7
    jg coordenadas_invalidas

    ; Calcular la posición en el tablero
    movzx ax, byte [fila]
    sub ax, 1
    imul ax, 7
    movzx dx, byte [columna]
    sub dx, 1
    add ax, dx
    mov rbx, rax
    add rbx, tablero

    ; Verificar si hay una oca en la posición ingresada
    cmp byte [rbx], 1
    jne coordenadas_invalidas

    mov byte [inputValido], 'S'
    mov [posicion_oca], rbx    ; Guardar la posición de la oca
    ret

coordenadas_invalidas:
    mov rdi, msjErrorInput
    mPuts
    ret

errorApertura:
    mov   rdi, msgErrorAp
    mPuts
    jmp   fin_juego

errorLeyendoArchivo:
    mov   rdi, msgErrorLectura
    mPuts
    jmp   continuar_jugando

errorEscritura:
    mov   rdi, msgErrorEscritura
    mPuts
    jmp   fin_juego

guardar_partida:
    mov     rdi, archivoTablero
    call    abrirEscrituraArchivo

    mov     rdi, msgGuardarPartida
    mPuts
    mov     rdi, respuestaPartidaGuardada
    mGets
    mov     rcx, 2
    lea     rsi, [respuestaSi]
    lea     rdi, [respuestaPartidaGuardada]
    repe    cmpsb
    jne     fin_juego

    call    convertirTableroAStr
    call    escribirArchivo
    cmp     rax, 0
    jle     errorEscritura
fin_juego:
    call    cerrarArchivo

    mov     rdi, mensaje_fin_juego  ; Imprimir el mensaje de fin del juego
    mPuts
ret



;---------  RUTINAS INTERNAS -----------
abrirLecturaArchivo:
  
  mov   rsi, modoAperturaRead
  call  fopen

  mov   qword[handleArch],rax
ret

abrirEscrituraArchivo:
  
  mov   rsi, modoAperturaWrite
  call  fopen

  mov   qword[handleArch],rax
ret

leerArchivoTablero:

  mov   rdi, registro
  mov   rsi, 51
  mov   rdx, [handleArch]
  call  fgets

ret

escribirArchivo:

  mov   rdi, tableroStr
  mov   rsi, [handleArch]
  call  fputs
ret

cerrarArchivo:

  mov   rdi, [handleArch]
  call  fclose
ret


;---------------------------------
copiarRegistroATablero:

  mov   byte[posicionVect], 0
  mov   byte[posicionMatFil], 1
  mov   byte[posicionMatCol], 1

recorroReg:

  cmp   byte[posicionVect], 49
  jge    finalizoCopia

  mov   al, byte[posicionVect]
  cbw
  cwde
  cdqe
  mov   cl,[registro+rax]
  sub   cl, '0'
  mov   [numero], cl

  ; Agrego el nro a la matriz
  
  mov   al, byte[posicionMatFil] 
  cbw
  cwde
  cdqe
  dec   rax
  imul  rax, CANT_FIL_COL

  mov   rcx, rax

  mov   al, byte[posicionMatCol]
  cbw
  cwde
  cdqe
  dec   rax
  
  add   rcx, rax      ; Desplazamiento en matriz

  mov   al, byte[numero]
  mov   [tablero+rcx], al

avanzarColumna:
  inc   byte[posicionMatCol]
  cmp   byte[posicionMatCol], CANT_FIL_COL
  jg    avanzarFila
  jmp   sigoEnVector

avanzarFila:
  mov   byte[posicionMatCol], 1
  inc   byte[posicionMatFil]
  cmp   byte[posicionMatFil], CANT_FIL_COL
  jg    finalizoCopia

sigoEnVector:
  add   byte[posicionVect], 1
  jmp   recorroReg

finalizoCopia:
ret



convertirTableroAStr:
  mov   byte[posicionMatFil], 1
  mov   byte[posicionMatCol], 1

continuoCopiaStr:
  mov   al, byte[posicionMatFil] 
  cbw
  cwde
  cdqe
  dec   rax
  imul  rax, CANT_FIL_COL

  mov   rcx, rax

  mov   al, byte[posicionMatCol]
  cbw
  cwde
  cdqe
  dec   rax
  
  add   rcx, rax      ; Desplazamiento en matriz
  cmp   rcx, DESPLAZ_LIMITE
  jg    finalizoCopiaStr

  mov   al, [tablero+rcx]
  add   al, 48
  cbw
  cwde
  cdqe
  mov   [tableroStr+rcx], rax

avanzarColumnaStr:
  inc   byte[posicionMatCol]
  cmp   byte[posicionMatCol], CANT_FIL_COL
  jg    avanzarFilaStr
  jmp   continuoCopiaStr

avanzarFilaStr:
  mov   byte[posicionMatCol], 1
  inc   byte[posicionMatFil]
  cmp   byte[posicionMatFil], CANT_FIL_COL
  jg    finalizoCopiaStr
  jmp   continuoCopiaStr
  
finalizoCopiaStr:
  mov   byte[tableroStr+49], 10 ;Agrego un salto de línea al final del archivo
ret


cargarEstadisticas:
