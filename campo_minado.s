# Campo Minado 
#
# CONFIGURAÇÃO OBRIGATÓRIA (Tools > Bitmap Display):
# Unit Width: 1
# Unit Height: 1
# Display Width: 256
# Display Height: 256
# Base Address: 0x10010000

# --- AJUSTES DE POSICIONAMENTO ---
.eqv CELL_SIZE 45      # Tamanho da célula
.eqv OFFSET_X  15      # Margem Esquerda (15px)
.eqv OFFSET_Y  15      # Margem Superior (Reduzido de 50 para 15 para não cortar)

.eqv BOARD_WIDTH 256
.eqv BOARD_HEIGHT 256  # Ajustado para o tamanho da janela

# Endereços de MMIO (Teclado)
.eqv MMIO_CONTROL 0xffff0000
.eqv MMIO_DATA    0xffff0004

.data 0x10010000
bitmap_mem: .space 0x80000      # Memória de vídeo

.data
# Cores
C_WHITE:  .word 0x00FFFFFF
C_GRAY:   .word 0x00CCCCCC
C_BLACK:  .word 0x00000000
C_RED:    .word 0x00FF0000
C_BLUE:   .word 0x000000FF

# Tabuleiro 5x5
board5:
    .byte 0,1,0,0,0
    .byte 0,0,1,0,0
    .byte 0,0,0,0,1
    .byte 0,0,0,1,0
    .byte 0,0,0,0,0

revealed5: .space 25
count5:    .space 25
numbuf:    .space 16

msg_win: .asciiz "Vitoria!\n"
msg_hit: .asciiz "Bomba!\n"

.text
.globl main

main:
    jal compute_counts

    # Posição inicial
    li $s0, 0    # cursor row
    li $s1, 0    # cursor col

# -------------------------------------------------------------------------
# GAME LOOP
# -------------------------------------------------------------------------
game_loop:
    # 1. Desenhar
    move $a0, $s0
    move $a1, $s1
    jal draw_board

    move $a0, $s0
    move $a1, $s1
    jal draw_cursor

    # 2. Delay (50ms)
    li $v0, 32
    li $a0, 50
    syscall

    # 3. Ler MMIO
    li $t0, MMIO_CONTROL
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, game_loop

    li $t0, MMIO_DATA
    lw $t2, 0($t0)

    # 4. Input
    li $t3, 'w'
    beq $t2, $t3, mv_up
    li $t3, 's'
    beq $t2, $t3, mv_down
    li $t3, 'a'
    beq $t2, $t3, mv_left
    li $t3, 'd'
    beq $t2, $t3, mv_right
    li $t3, ' ' 
    beq $t2, $t3, action_reveal
    li $t3, 'q'
    beq $t2, $t3, exit_game

    j game_loop

# -------------------------------------------------------------------------
# MOVIMENTO
# -------------------------------------------------------------------------
mv_up:
    addi $s0, $s0, -1
    blt $s0, 0, clamp_top
    j game_loop
clamp_top:
    li $s0, 0
    j game_loop

mv_down:
    addi $s0, $s0, 1
    bgt $s0, 4, clamp_bot
    j game_loop
clamp_bot:
    li $s0, 4
    j game_loop

mv_left:
    addi $s1, $s1, -1
    blt $s1, 0, clamp_left
    j game_loop
clamp_left:
    li $s1, 0
    j game_loop

mv_right:
    addi $s1, $s1, 1
    bgt $s1, 4, clamp_right
    j game_loop
clamp_right:
    li $s1, 4
    j game_loop

action_reveal:
    move $a0, $s0
    move $a1, $s1
    jal reveal_cell
    beq $v0, 1, game_over_loss
    jal check_win
    beq $v0, 1, game_over_win
    j game_loop

# -------------------------------------------------------------------------
# FIM DE JOGO
# -------------------------------------------------------------------------
game_over_loss:
    li $t0, 0
rev_loop_loss:
    bgt $t0, 24, show_loss_msg
    la $t1, revealed5
    add $t1, $t1, $t0
    li $t2, 1
    sb $t2, 0($t1)
    addi $t0, $t0, 1
    j rev_loop_loss
show_loss_msg:
    move $a0, $s0
    move $a1, $s1
    jal draw_board
    la $a0, msg_hit
    li $v0, 4
    syscall
    j exit_game

game_over_win:
    la $a0, msg_win
    li $v0, 4
    syscall
    j exit_game

exit_game:
    li $v0, 10
    syscall

# -------------------------------------------------------------------------
# FUNÇÕES GRÁFICAS
# -------------------------------------------------------------------------
draw_pixel:
    li   $t0, 0x10010000
    li   $t1, BOARD_WIDTH
    mul  $t2, $a1, $t1      # y * width
    add  $t2, $t2, $a0      # + x
    sll  $t2, $t2, 2        # * 4
    add  $t2, $t2, $t0
    sw   $a2, 0($t2)
    jr $ra

draw_filled_rect:
    addi $sp, $sp, -32
    sw   $ra, 28($sp)
    sw   $s0, 24($sp)
    sw   $s1, 20($sp)
    sw   $s2, 16($sp)
    sw   $s3, 12($sp)
    sw   $s4, 8($sp)
    sw   $s5, 4($sp)
    sw   $s6, 0($sp)

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    move $s4, $v1

    li   $s5, 0    # dy
rect_y_loop:
    beq  $s5, $s3, rect_done
    li   $s6, 0    # dx
rect_x_loop:
    beq  $s6, $s2, rect_next_line
    
    add  $a0, $s0, $s6
    add  $a1, $s1, $s5
    move $a2, $s4
    jal  draw_pixel

    addi $s6, $s6, 1
    j rect_x_loop
rect_next_line:
    addi $s5, $s5, 1
    j rect_y_loop
rect_done:
    lw   $s6, 0($sp)
    lw   $s5, 4($sp)
    lw   $s4, 8($sp)
    lw   $s3, 12($sp)
    lw   $s2, 16($sp)
    lw   $s1, 20($sp)
    lw   $s0, 24($sp)
    lw   $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra

# -------------------------------------------------------------------------
# LÓGICA DO JOGO
# -------------------------------------------------------------------------
compute_counts:
    li $t0, 0
rloop:
    bgt $t0, 4, cdone
    li $t1, 0
cloop:
    bgt $t1, 4, rnext
    li $t2, 5
    mul $t3, $t0, $t2
    add $t4, $t3, $t1
    la $t5, board5
    add $t6, $t5, $t4
    lb  $t7, 0($t6)
    beq $t7, $zero, nbomb
    li $t8, 9
    la $t9, count5
    add $t9, $t9, $t4
    sb $t8, 0($t9)
    j ccont
nbomb:
    li $t8, 0
    li $t6, -1
drl:
    bgt $t6, 1, drd
    li $t7, -1
dcl:
    bgt $t7, 1, dcn
    bne $t6, $zero, chk
    bne $t7, $zero, chk
    j inc
chk:
    add $t9, $t0, $t6
    add $s3, $t1, $t7
    blt $t9, $zero, inc
    bgt $t9, 4, inc
    blt $s3, $zero, inc
    bgt $s3, 4, inc
    li $s4, 5
    mul $s5, $t9, $s4
    add $s5, $s5, $s3
    la $s6, board5
    add $s6, $s6, $s5
    lb $s7, 0($s6)
    beq $s7, $zero, inc
    addi $t8, $t8, 1
inc:
    addi $t7, $t7, 1
    j dcl
dcn:
    addi $t6, $t6, 1
    j drl
drd:
    la $t9, count5
    add $t9, $t9, $t4
    sb $t8, 0($t9)
ccont:
    addi $t1, $t1, 1
    j cloop
rnext:
    addi $t0, $t0, 1
    j rloop
cdone:
    jr $ra

reveal_cell:
    li $t0, 5
    mul $t1, $a0, $t0
    add $t2, $t1, $a1
    la $t3, revealed5
    add $t4, $t3, $t2
    li $t5, 1
    sb $t5, 0($t4)
    la $t6, board5
    add $t7, $t6, $t2
    lb $t8, 0($t7)
    beq $t8, $zero, rsafe
    li $v0, 1
    jr $ra
rsafe:
    li $v0, 0
    jr $ra

check_win:
    li $t0, 0
cw_l:
    li $t1, 25
    beq $t0, $t1, cw_y
    la $t2, board5
    add $t3, $t2, $t0
    lb $t4, 0($t3)
    beq $t4, $zero, cw_rev
    addi $t0, $t0, 1
    j cw_l
cw_rev:
    la $t5, revealed5
    add $t6, $t5, $t0
    lb $t7, 0($t6)
    beq $t7, $zero, cw_n
    addi $t0, $t0, 1
    j cw_l
cw_n:
    li $v0, 0
    jr $ra
cw_y:
    li $v0, 1
    jr $ra

draw_board:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $s2, 0 # r
dbl_r:
    bgt $s2, 4, dbl_end
    li $s3, 0 # c
dbl_c:
    bgt $s3, 4, dbl_nr
    
    # --- CALCULO COM OFFSET ---
    li $t1, CELL_SIZE
    
    # X = OFFSET_X + (c * CELL_SIZE)
    mul $t2, $s3, $t1
    add $t3, $t2, OFFSET_X  
    
    # Y = OFFSET_Y + (r * CELL_SIZE)
    mul $t5, $s2, $t1
    add $t6, $t5, OFFSET_Y
    
    # Estado da célula
    li $t9, 5
    mul $t9, $s2, $t9
    add $t9, $t9, $s3
    
    la $t7, revealed5
    add $t7, $t7, $t9
    lb $t7, 0($t7)
    
    la $t8, board5
    add $t8, $t8, $t9
    lb $t8, 0($t8)
    
    beqz $t7, col_hidden
    beqz $t8, col_safe
    la $v1, C_RED
    lw $v1, 0($v1)
    j draw_it
col_safe:
    la $v1, C_GRAY
    lw $v1, 0($v1)
    j draw_it
col_hidden:
    la $v1, C_WHITE
    lw $v1, 0($v1)
    
draw_it:
    move $a0, $t3
    move $a1, $t6
    li $a2, CELL_SIZE
    li $a3, CELL_SIZE
    
    # Borda visual entre celulas
    addi $a2, $a2, -2
    addi $a3, $a3, -2

    addi $sp, $sp, -8
    sw $s2, 0($sp)
    sw $s3, 4($sp)
    jal draw_filled_rect
    lw $s3, 4($sp)
    lw $s2, 0($sp)
    addi $sp, $sp, 8
    
    addi $s3, $s3, 1
    j dbl_c
dbl_nr:
    addi $s2, $s2, 1
    j dbl_r
dbl_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_cursor:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t1, CELL_SIZE
    
    # X = OFFSET_X + (c * CELL_SIZE)
    mul $t2, $a1, $t1
    add $t3, $t2, OFFSET_X
    
    # Y = OFFSET_Y + (r * CELL_SIZE)
    mul $t5, $a0, $t1
    add $t6, $t5, OFFSET_Y
    
    la $v1, C_BLACK
    lw $v1, 0($v1)
    
    # Borda Top
    move $a0, $t3
    move $a1, $t6
    li $a2, CELL_SIZE
    addi $a2, $a2, -2 # ajuste grid
    li $a3, 3
    jal draw_filled_rect
    
    # Borda Bottom
    move $a0, $t3
    move $a1, $t6
    addi $a1, $a1, 40 # CELL_SIZE - 5 aprox
    li $a2, CELL_SIZE
    addi $a2, $a2, -2
    li $a3, 3
    jal draw_filled_rect
    
    # Borda Left
    move $a0, $t3
    move $a1, $t6
    li $a2, 3
    li $a3, CELL_SIZE
    addi $a3, $a3, -2
    jal draw_filled_rect
    
    # Borda Right
    move $a0, $t3
    addi $a0, $a0, 40
    move $a1, $t6
    li $a2, 3
    li $a3, CELL_SIZE
    addi $a3, $a3, -2
    jal draw_filled_rect
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
