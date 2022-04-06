[org 0x7c00] ; location of the boot sector
mov bp, 0x7c00 ; set the base stack pointer
mov sp, bp ; set the head the stack pointer

start_game:
; set the number of match sticks for each row
mov byte [line+0], 1
mov byte [line+1], 3
mov byte [line+2], 5
mov byte [line+3], 7

; set the current player to player1
mov word [player_curr_str], word player1_str

; update the game
game_loop:
	call clear_screen ; clear the screen
	; print the game board
	call print_game
	; print the current player
	mov bx, [player_curr_str]
	call print
	mov bx, players_turn_str
	call print
	; get input from the player
	input_loop:
		; ask player for input
		mov bx, input_string
		call print
		; get the players input
		call get_input
		; check if the players input is valid
		mov al, byte [line+bx-1]
		sub al, cl
		; check if the new number of matchsticks is greater than 7 or less than 0
		cmp al, 7
		jg input_loop ; if invalid input try geting input again
		cmp al, 0 
		jl input_loop ; if invalid input try geting input again
	end_input_loop:
	mov byte [line+bx-1], al ; set the number of matchsticks int the
	call swap_players ; update the current player
	; find the total number of matchsticks on the board
	mov bx, line ; set bx to the line array base address
	mov cl, 0 ; set teh sum register(cl) to 0
	.cg_loop:
		add cl, [bx] ; add the value bx is pointing at to the sum
		inc bx ; increment the array pointer
		cmp bx, line+4 ; check if bx is pointing to the index just after the line array
		jne .cg_loop ; if still in the array add the next line
	; check if the number of matchsticks is 0
	cmp cl, 0
	je game_win ; game was won
	jmp game_loop ; next itoration of the game loop
	game_win:
		; print who is the wining player
		mov bx, [player_curr_str]
		call print
		mov bx, player_wins_str
		call print
		; print play again
		mov bx, play_again_str
		call print
		; weight for player input
		mov ah, 0x00
		int 0x16
		jmp start_game; start next game

; swapes the current player
swap_players:
	cmp word [player_curr_str], word player1_str ; compaer the current player string ptr to the player 1 string
	je set_p2_turn ; if the current player is player 1 set the current player to player 2
	jmp set_p1_turn ; set the current player to player 1
	set_p2_turn:
		mov word [player_curr_str], word player2_str ; set the player to player 2
		jmp end_set_turn
	set_p1_turn:
		mov word [player_curr_str], word player1_str ; set the player to player 1
	end_set_turn:
	ret

; get the user input for row and number of matches to remove
; bx: row, cl: num matches
get_input:
	; get the row from the user
	mov ah, 0x00
	int 0x16
	call print_char ; print the char typed
	mov bl, al ; noved the char to bl so we can get the next char
	mov bh, 0 ; zero out the high part of bx
	sub bx, '0' ; subtract the ascii code for '0' from the input char to get the numaric value of the input
	; print a ',' to seperate the inputs
	mov al, ','
	call print_char
	; get the number of matches to remove from the user
	mov ah, 0x00
	int 0x16
	call print_char ; print the char the typed
	mov cl, al ; move the input char to cl so ax can be used for printing
	sub cl, '0' ; subtract the ascii code fo '0' from the input char to get the numarical value of the input
	; print \r\n
	mov al, 0x0d
	call print_char
	mov al, 0x0a
	call print_char
	ret ; return

; prints the game board
print_game:
	mov ah, 0x0e ; sets ah to be able to print chars
	mov bx, line ; put the pointer to the start of the lines array in bx
	.pg_row_loop:
		; print the row number
		; get the offset from the base of the array
		mov cx, bx
		sub cx, line
		add cl, '1' ; add the base ascii code for '1'
		mov al, cl ; move the char to al
		int 0x10 ; print the char
		mov al, ' '
		int 0x10
		mov al, '|' ; sets the '|' to be printed out
		mov ch, [bx] ; sets the number of matches in the current row into ch
		.pg_col_loop:
			cmp ch, 0 ; checks if the number of matches left to print is 0
			je .pg_col_end ; if there are no mor matches to print move to the mext row of matches 
			int 0x10 ; print the char '|' that was set earlier
			dec ch ; decrement the number of matches left to print
			jmp .pg_col_loop ; print the next match
		.pg_col_end:
			; prnt \r\n\n
			mov al, 0x0d
			int 0x10
			mov al, 0x0a
			int 0x10
			int 0x10
			inc bx ; move bx to point to the next row of matches
			cmp bx, line+4 ; check if we have hit the end of the matches array
			je .pg_end ; if we are done printing the matches return
			jmp .pg_row_loop ; start printing the next row of matches
	.pg_end:
		ret ; return

; prints the string being pointed to in bx
print:
	mov ah, 0x0e ; set ah to be able to print
	.printLoop:
		cmp [bx], byte 0 ; check if bx is pointing to the null ternimation char
		je .printEnd ; if so return
		; print the char bx is pointing to
		mov al, [bx]
		int 0x10
		inc bx ; increment bx to the next char to print 
		jmp .printLoop ; print the next char
	.printEnd:
		ret ; return

; prints the char in al
print_char:
	mov ah, 0x0e
	int 0x10
	ret

; clears the screen by reseting the print mode
clear_screen:
	mov ax, 0x0003
	int 0x10
	ret

input_string: db "Please input a valid row (1-4) and number of matches to remove",0x0a,0x0d,0

player_curr_str: dw player1_str ; pointer to the player string
player1_str: db "Player1",0
player2_str: db "Player2",0

players_turn_str: db "'s turn",0x0a,0x0d,0
player_wins_str: db " Wins!!!",0x0a,0x0d,0

play_again_str: db "press any keys to play again",0x0a,0x0d,0

line: db 1,3,5,7 ; array of the number of matches in each line

times 510-($-$$) db 0 ; fill the reset of the 510 usable bytes to 0
dw 0xaa55 ; magic number needed for the boot sector