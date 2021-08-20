bits 16

org 0x7c00

; 320x200x8bit
%define VGA_MODE 0x13
%define VGA_OFFSET 0xA000

; in pixels
%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 200

; in pixels
%define CELL_WIDTH 10
%define CELL_HEIGHT 10

; in cells
%define FIELD_WIDTH 20
%define FIELD_HEIGHT 10
; in pixels
%define FIELD_Y (SCREEN_HEIGHT - (FIELD_HEIGHT * CELL_HEIGHT)) / 2
%define FIELD_X (SCREEN_WIDTH - (FIELD_WIDTH * CELL_WIDTH)) / 2
%define FIELD_END_Y (SCREEN_HEIGHT - FIELD_Y)
%define FIELD_END_X (SCREEN_WIDTH - FIELD_X)

; in pixels
%define PALETTE_OFFSET 10
%define PALETTE_COLOR_COUNT 7
%define PALETTE_Y FIELD_Y + (FIELD_HEIGHT * CELL_HEIGHT) + PALETTE_OFFSET
%define PALETTE_X FIELD_X + (((FIELD_WIDTH * CELL_WIDTH) - (PALETTE_COLOR_COUNT * CELL_WIDTH)) / 2)
%define PALETTE_END_Y (PALETTE_Y + CELL_HEIGHT)
%define PALETTE_UNDERSCORE_PADDING 2

; in pixels
%define UNDERSCORE_START ((PALETTE_END_Y + PALETTE_UNDERSCORE_PADDING) * SCREEN_WIDTH) + PALETTE_X
%define UNDERSCORE_END (UNDERSCORE_START + (CELL_WIDTH * (COLOR_WHITE - COLOR_LIGHTBLUE + 1)))

%define COLOR_BLACK 0

%define COLOR_LIGHTGRAY 7

%define COLOR_LIGHTBLUE 9
%define COLOR_LIGHTGREEN 10
%define COLOR_LIGHTCYAN 11
%define COLOR_LIGHTRED 12
%define COLOR_LIGHTMAGENTA 13
%define COLOR_YELLOW 14
%define COLOR_WHITE 15

%define BACKGROUND_COLOR COLOR_BLACK

; ---------------------------------------------------------------
struc game_state_t
  .current_col: resb 1
endstruc
; ---------------------------------------------------------------

entry:
  mov ax, VGA_MODE
  int 0x10

  mov ax, VGA_OFFSET
  mov es, ax
  
  call put_field
  call put_palette

  entry_loop:
    call put_underscore

    xor ax, ax
    int 0x16

    cmp al, 'a'
    jne dec_continue
      call col_dec
    dec_continue:

    cmp al, 'd'
    jne inc_continue
      call col_inc
    inc_continue:

    cmp al, ' '

    cmp al, 'q'
    je end

    jmp entry_loop

  jmp end

col_dec:
  push ax
    mov ax, [init_game_state + game_state_t.current_col] 
    cmp ax, COLOR_LIGHTBLUE
    je col_dec_reset
    ; decrement
    dec ax
    mov [init_game_state + game_state_t.current_col], ax
    jmp col_dec_end
    ; reset
    col_dec_reset:
    mov ax, COLOR_WHITE
    mov [init_game_state + game_state_t.current_col], ax
    col_dec_end:
  pop ax
  ret

col_inc:
  push ax
    mov ax, [init_game_state + game_state_t.current_col] 
    cmp ax, COLOR_WHITE
    je col_inc_reset
    ; increment
    inc ax
    mov [init_game_state + game_state_t.current_col], ax
    jmp col_inc_end
    ; reset
    col_inc_reset:
    mov ax, COLOR_LIGHTBLUE
    mov [init_game_state + game_state_t.current_col], ax
    col_inc_end:
  pop ax
  ret


put_underscore:
  push ax
  push bx
  push cx
    ; clear underscore area
    mov di, UNDERSCORE_START
    xor cx, cx
    clr_underscore_h:
      mov [es:di], cl
      inc di
      cmp di, UNDERSCORE_END
      jne clr_underscore_h

    ; underscore color
    mov cl, [init_game_state + game_state_t.current_col]
    ; underscore start
    mov ax, [init_game_state + game_state_t.current_col]
    sub ax, COLOR_LIGHTBLUE 
    mov bx, CELL_WIDTH
    mul bx
    add ax, UNDERSCORE_START
    ; underscore end
    mov bx, ax
    add bx, CELL_WIDTH - 1 ; -1 for cell padding
    ; underscore index
    mov di, ax
    put_underscore_h:
      mov [es:di], cl
      inc di
      cmp di, bx
      jne put_underscore_h

  pop cx
  pop bx
  pop ax
  ret

put_palette:
  push ax
  push bx
    mov ax, PALETTE_Y
    mov bx, PALETTE_X
    mov cl, COLOR_LIGHTBLUE
    put_palette_h:
      call put_cell

      ; increment color & x
      inc cl
      add bx, CELL_WIDTH
      cmp cl, COLOR_WHITE + 1
      jne put_palette_h
  pop bx
  pop ax
  ret

; put field at (FIELD_X, FIELD_Y)
put_field:
  push ax
  push bx
    mov ax, FIELD_Y
    put_field_v:
      mov bx, FIELD_X
      put_field_h:
        call rand_col
        call put_cell

        add bx, CELL_WIDTH
        cmp bx, FIELD_END_X

        jne put_field_h
      add ax, CELL_HEIGHT
      cmp ax, FIELD_END_Y
      jne put_field_v
  pop bx
  pop ax
  ret

; ax <- y
; bx <- x
; cl <- color
put_cell:
  push ax
  push bx
    ; di <- starting pixel coordinate
    ; di = y * SCREEN_WIDTH + x
    mov di, SCREEN_WIDTH    ; di = SCREEN_WIDTH
    mul di                  ; ax *= di
    mov di, ax              ; di = ax
    add di, bx              ; di += bx

    ; ax <- lowest border
    mov ax, CELL_HEIGHT - 1; -1 is a cell spacing
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, di

    put_cell_v:
      ; bx <- rightmost boder
      mov bx, di
      add bx, CELL_WIDTH - 1 ; -1 is a cell spacing

      push di
        put_cell_h:
          mov [es:di], cl
          inc di
          cmp di, bx
          jne put_cell_h
      pop di

      add di, SCREEN_WIDTH

      cmp di, ax
      jne put_cell_v
  pop bx
  pop ax
  ret

; puts random color in `cl`
rand_col:
  push ax
  push dx
    ; TimeStampCounter: puts counter into `ax`
    rdtsc 
    xor dx, dx
    mov cx, COLOR_WHITE - COLOR_LIGHTBLUE + 1
    div cx
    mov ax, dx
    add ax, COLOR_LIGHTBLUE
    mov cl, al
  pop dx
  pop ax
  ret

end:
  jmp $

; ---------------------------------------------------------------
init_game_state:
  istruc game_state_t
    at game_state_t.current_col, db COLOR_LIGHTBLUE
  iend
; ---------------------------------------------------------------

; debug size before padding it with 0
%assign program_size $ - $$
%warning program size is: program_size bytes

; padding
times 510 - ($ - $$) db 0
dw 0xaa55

; error if size is exceeding 512
%if $ - $$ != 512
  %fatal Program is size is not 512
%endif
