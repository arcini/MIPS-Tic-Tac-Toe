.data 0x0
board: .word 0,0,0,0,0,0,0,0,0
xwin: .asciiz "\n X wins!!"
owin: .asciiz "\n O wins!!"
cat: .asciiz "\n Cat game!!"
x: .byte 0x58, 0
o: .byte, 0xD8, 0
linedash: .byte 0xA, 0x20, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0x97, 0
vert: .byte 0x20, 0x7C, 0x20, 0
nl: .asciiz "\n"
space: .asciiz "  "
xcont: .asciiz "\n Player 1, input your move!"
ocont: .asciiz "\n Player 2, input your move!"
badmove: .asciiz "\n Invalid move! Please try again."
anotherone: .asciiz "\n Would you like to play again? (1 for Yes, 0 for No)"
player1score: .word 0
player2score: .word 0
scorestring1: .asciiz "\n Player 1: " 
scorestring2: .asciiz "\n Player 2: "
scores: .asciiz "\n Scores"
scoreunderline: .asciiz "\n -----------"



.text 0x3000
.globl main

main:
	#----- print the scores -----#
	la $a0, scores($0)
	ori $v0, $0, 4
	syscall
	la $a0, scoreunderline($0)
	ori $v0, $0, 4
	syscall
	la $a0, scorestring1($0)
	ori $v0, $0, 4
	syscall
	lw $a0, player1score($0)
	ori $v0, $0, 1
	syscall
	la $a0, scorestring2($0)
	ori $v0, $0, 4
	syscall
	lw $a0, player2score($0)
	ori $v0, $0, 1
	syscall

	addi $t1, $0, 1 #current player, 1 for player 1, 2 for player 2 (starts with 1), 0 for endgame
	addi $s0, $0, 1 #player 1 is X
	addi $s1, $0, 2 #player 2 is O
	addi $t0, $0, 9 #counter, starts at max amount of moves left (for cat)
	add $t6, $0, $0 #this is the winner of the game, 0 for cat
	j maincont
	
begingrid:
	jal printdash
	jal newline
	jal printvert
	add $t2, $0, $0 #counter for printing grid init @ 0
griditeration:
	#----- fills in each space of the row -----#
	la $a0, board($t2) #loads an address of a piece of grid into arg (a0 gets position of current piece)
	lw $t8, ($a0) #loads value of piece to t8
	jal getpc
	addi $ra, $ra, 28 #branch returns to specified instruction
	beq $t8, $s0, printX #if current space value is 1, print x
	beq $t8, $s1, printO #if current space value is 2, print O
	srl $a0, $t2, 2 #set arg to index of the grid space plus one
	addi $a0, $a0, 1
	
	#----- prints number -----#
	ori $v0, $0, 1 #if neither of the above, just print integer corresponding to the space
	syscall
	
	#----- each space is followed by a vertical line -----#
	jal printvert
	
	#----- check if grid is filled in -----#
	srl $a0, $t2, 2 #set arg to index of the grid space plus one
	addi $a0, $a0, 1
	beq $a0, 9, endgrid #finished grid
	
	#----- check if should be next row -----#
	addi $t7, $0, 3 
	div $t2, $t7
	mfhi $t7
	jal getpc
	addi $ra, $ra, 12 #branch returns to specified instruction 
	beq $t7, 2, printdash
	jal getpc
	addi $ra, $ra, 12 #branch returns to specified instruction 
	beq $t7, 2, newline
	jal getpc
	addi $ra, $ra, 12 #branch returns to specified instruction 
	beq $t7, 2, printvert
	
	#----- prep for next iteration -----#
	addi $t2, $t2, 4 #increment counter by 1
	j griditeration
endgrid:
	jal printdash #close out grid
	jr $s4
	
newline:
	la $a0, nl($0)
	ori $v0, $0, 4
	syscall
	jr $ra
	
printdash:
	la $a0, linedash($0)
	ori $v0, $0, 4
	syscall
	jr $ra
	
printX:
	la $a0, x($0)
	ori $v0, $0, 4
	syscall
	jr $ra
	
printO:
	la $a0, o($0)
	ori $v0, $0, 4
	syscall
	jr $ra
	
printvert:
	la $a0, vert($0)
	ori $v0, $0, 4
	syscall
	jr $ra
	
printspace:
	la $a0, space($0)
	ori $v0, $0, 4
	syscall
	jr $ra

printbad:
	la $a0, badmove($0)
	ori $v0, $0, 4
	syscall
	jr $ra
	
printxcont:
	jal getpc
	addi $s4, $ra, 8 #sets desired instruction to s4 so we can come back here later
	j begingrid #draws board
	la $a0, xcont($0) #asks for next move
	ori $v0, $0, 4
	syscall
	jr $s3
	
printocont:
	jal getpc
	addi $s4, $ra, 8 #sets desired instruction to s4 so we can come back here later
	j begingrid #draws board
	la $a0, ocont($0) #asks for next move
	ori $v0, $0, 4
	syscall
	jr $s3

maincont:
	jal getpc
	addi $s5, $ra, 8 
	j checkwin #checks endgame conditions
	beq $t0, 0, catwon #ends with cat if 9 moves have happened
	beq $t1, 1, player1cont #player 1's turn
	beq $t1, 2, player2cont #player 1's turn
	
player1cont:
	jal getpc
	addi $s3, $ra, 8 #sets desired instruction to s3 so we can come back here later
	j printxcont #prints board and statement
	ori $v0, $0, 5
	syscall #gets the move from the player
	blt $v0, 1, moveexcept #move must be 1-9
	bgt $v0, 9, moveexcept #move must be 1-9
	sub $v0, $v0, 1
	sll $v0, $v0, 2 #converts move to "index"
	
	lw $t7, board($v0) #gets piece at this index
	bne $t7, $0, moveexcept #if already a piece, do not overwrite! goes to moveexcept
	
	sub $t0, $t0, 1 #counts this as a move for cat check
	sw $s0, board($v0) #sets the piece into the board
	ori $t1, $0, 2 #it is now player 2's turn
	j maincont #next turn
	
player2cont:
	jal getpc
	addi $s3, $ra, 8 #sets desired instruction to s3 so we can come back here later
	j printocont #prints board and statement
	ori $v0, $0, 5
	syscall #gets the move from the player
	blt $v0, 1, moveexcept #move must be 1-9
	bgt $v0, 9, moveexcept #move must be 1-9
	sub $v0, $v0, 1
	sll $v0, $v0, 2 #converts move to "index"
	
	lw $t7, board($v0) #gets piece at this spot
	bne $t7, $0, moveexcept #if already a piece, do not overwrite! goes to moveexcept
	
	sub $t0, $t0, 1 #counted as a move for cat check
	sw $s1, board($v0) #sets the piece into the board
	ori $t1, $0, 1 #it is now player 2's turn
	j maincont #next turn
	
moveexcept:
	jal printbad #notify player of bad move
	j maincont #restart turn
	
checkwin: #runs the three checks
	jal getpc
	addi $s6, $ra, 8
	j win1 #horizontal check
	jal getpc
	addi $s6, $ra, 8
	j win2 #vertical check
	jal getpc
	addi $s6, $ra, 8
	j win3 #diagonal check
	jr $s5 #returns to maincont and continues to next turn
	
win1: #horizontal win
	#----- puts the three horizontal spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 24
 	lw $t3, board($t9)
	ori $t9, $0, 28
 	lw $t4, board($t9)
	ori $t9, $0, 32
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5 
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon
	
	#----- puts the three horizontal spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 12
	lw $t3, board($t9)
	ori $t9, $0, 16
 	lw $t4, board($t9)
	ori $t9, $0, 20
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5 
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon
	
	#----- puts the three horizontal spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 0
 	lw $t3, board($t9)
	ori $t9, $0, 4
 	lw $t4, board($t9)
	ori $t9, $0, 8
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon 
	
	jr $s6 #return to checkwin
	
win2: #vertical win
	#----- puts the three vertical spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 0
	lw $t3, board($t9)
	ori $t9, $0, 12
 	lw $t4, board($t9)
	ori $t9, $0, 24
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5 
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon
	
	#----- puts the three vertical spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 4
 	lw $t3, board($t9)
	ori $t9, $0, 16
 	lw $t4, board($t9)
	ori $t9, $0, 28
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon 
	
	#----- puts the three vertical spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 8
	lw $t3, board($t9)
	ori $t9, $0, 20
 	lw $t4, board($t9)
	ori $t9, $0, 32
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon 
	
	jr $s6 #return to checkwin
	
win3: #diagonal win
	#----- puts the three diagonal spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 0
	lw $t3, board($t9)
	ori $t9, $0, 16
 	lw $t4, board($t9)
	ori $t9, $0, 32
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5 
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon
	
	#----- puts the three diagonal spaces into registers then ands them and if not 0, someone has won -----#
	ori $t9, $0, 8
 	lw $t3, board($t9)
	ori $t9, $0, 16
 	lw $t4, board($t9)
	ori $t9, $0, 24
 	lw $t5, board($t9)
 	and $t7, $t3, $t4 
 	and $t8, $t7, $t5
	jal getpc
	addi $ra, $ra, 8
	beq $t8, $t3, whowon
	
	jr $s6 #return to checkwin

whowon:
	bne $t8, $0, actualwin #check if the spaces contained pieces (not spaces) and branches
	jr $ra #return to end of checkwin

actualwin:
	beq $t3, 1, onewon #a one means player one has won
	beq $t3, 2, twowon #a two means player two has won
	
onewon:
	la $a0, xwin($0) 
	ori $v0, $0, 4
	syscall #print win statement
	
	lw $t7, player1score($0)
	addi $t7, $t7, 1
	sw $t7, player1score #increment score by one
	
	ori $a0, $0, 71 #music
	ori $a1, $0, 333
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	ori $a0, $0, 75
	ori $a1, $0, 333
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	ori $a0, $0, 78
	ori $a1, $0, 333
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	ori $a0, $0, 83
	ori $a1, $0, 500
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	j restart #goto restart
	
twowon:
	la $a0, owin($0)
	ori $v0, $0, 4
	syscall #print win statement
	
	lw $t7, player2score($0)
	addi $t7, $t7, 1
	sw $t7, player2score #increment score by one
	
	ori $a0, $0, 71 #music
	ori $a1, $0, 333
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	ori $a0, $0, 75
	ori $a1, $0, 333
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	ori $a0, $0, 78
	ori $a1, $0, 333
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	ori $a0, $0, 83
	ori $a1, $0, 500
	ori $a2, $0, 61
	ori $a3, $0, 100
	ori $v0, $0, 31
	syscall
	j restart #goto restart

catwon:
	la $a0, cat($0) #print cat statement
	ori $v0, $0, 4
	syscall
	j restart #goto restart

getpc: #sets $ra to the line after the call of this label (below "jal getpc")
	nop
	jr $ra

restart:
	la $a0, anotherone($0) #asks player if they would like to play again
	ori $v0, $0, 4
	syscall
	ori $v0, $0, 5 #input integer (1 for yes, 0 for no)
	syscall
	beq $v0, $0, end #if player says 0, end the program
	ori $t9, $0, 0 #otherwise, reset the board
	sw $0, board($t9)
	ori $t9, $0, 4
	sw $0, board($t9)
	ori $t9, $0, 8
	sw $0, board($t9)
	ori $t9, $0, 12
	sw $0, board($t9)
	ori $t9, $0, 16
	sw $0, board($t9)
	ori $t9, $0, 20
	sw $0, board($t9)
	ori $t9, $0, 24
	sw $0, board($t9)
	ori $t9, $0, 28
	sw $0, board($t9)
	ori $t9, $0, 32
	sw $0, board($t9)
	j main #start over

end:
	ori $v0, $0, 10 #end program
	syscall
	
