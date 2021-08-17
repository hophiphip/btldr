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
%define FIELD_WIDTH 32
%define FIELD_HEIGHT 20

%define COLOR_BLACK 0

%define COLOR_LIGHTBLUE 9
%define COLOR_LIGHTGREEN 10
%define COLOR_LIGHTCYAN 11
%define COLOR_LIGHTRED 12
%define COLOR_LIGHTMAGENTA 13
%define COLOR_YELLOW 14
%define COLOR_WHITE 15

%define BACKGROUND_COLOR COLOR_BLACK

; ---------------------------------------------------------------

entry:
  mov ax, VGA_MODE
  int 0x10

  mov ax, VGA_OFFSET
  mov es, ax
  
  draw_cells:
    mov ax, 0
    mov cl, COLOR_LIGHTCYAN
    draw_vertial:
      mov bx, 0
      draw_horizontal:
        call put_cell
        add bx, CELL_WIDTH
        cmp bx, SCREEN_WIDTH
        jne draw_horizontal
      add ax, CELL_HEIGHT
      cmp ax, SCREEN_HEIGHT
      jne draw_vertial

  jmp end


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

end:
  jmp $

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
