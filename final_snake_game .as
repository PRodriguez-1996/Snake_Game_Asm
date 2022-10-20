;Paul Rodriguez
;FinalSnakeGame makes a snake controlled with WASD that grows each time it collides with a glowing pixel
define snakeLength $00
define snakeHeadL $10
define snakeHeadH $11
define snakeBodyStart $12

define applePosLo $04
define applePosHi $05

define ASCII_w $77
define ASCII_a $61
define ASCII_s $73
define ASCII_d $64

define keyPress $ff
define currDir $02

define upDir $00
define leftDir $01
define downDir $02
define rightDir $03

JSR init
JSR loop

init:
  JSR initSnake
  JSR initApple
  RTS
  
initSnake:
  LDA #downDir ;initialize the direction the snake is traveling
  STA currDir
  LDA #$04
  STA snakeLength ;initialize the snakelength
  LDA #$22
  STA snakeHeadL ;initialize the lo byte of snake head
  LDA #$10
  STA snakeBodyStart ;initialize the lo byte of the snake body
  LDA #$03
  STA snakeHeadH ; initialize the hi byte of snake head
  STA $13 ;initialize the hi byte of the snake body
  RTS
initApple:
  LDA $FE 
  STA applePosLo ;gets a random number from the generator to use for the apple lobyte
  LDA $FE
  AND #$03
  CLC
  ADC #$02
  STA applePosHi ;gets a random number from the generator we must AND it by 3 and ADC it by 2 to make the range between 2 and 5 and we use it for the apple hibyte
  RTS
    
loop:
  JSR readKeys
  JSR checkAppleCollision
  JSR updateSnake
  JSR checkSnakeCollision
  JSR drawApple
  JSR drawSnake
  LDX #$00 ;initialize X to 0 for comparison
  JSR wasteTime
  JMP loop
  
checkAppleCollision:
  LDA applePosLo
  CMP snakeHeadL ;loads into A the lobyte of the apple and compares it to the lobyte of the snake head
  BNE noAppleCollision ;if its not equal we didnt eat the apple
  LDA applePosHi
  CMP snakeHeadH ;loads into A the hibye of the apple and compares it to the hibyte of the snake head
  BNE noAppleCollision ;if its not equal we didnt eat the apple
  INC snakeLength
  INC snakeLength ;if theyre both equal we incriment the snakelength by 2 since each pixel is a pair of bits
  JSR initApple ;we generate a new apple location
  RTS
noAppleCollision:
  RTS

checkSnakeCollision:
  LDX #$00 
  LDA (snakeHeadL,X) ;loads into A the value given by the coordinate of the snake head
  CMP #$01 ;compares it too white
  BEQ end2 ;if its white we hit ourselves
  RTS
  
end2:
  JMP end
  
readKeys: ;Loads the address that stores the keypressed and checks if it was WASD
  LDA keyPress
  CMP #ASCII_w
  BEQ upPress ;if it was W jump to the up routine
  CMP #ASCII_a
  BEQ leftPress ;if it was A jump to the left routine
  CMP #ASCII_s
  BEQ downPress ;if it was S jump to the down routine
  CMP #ASCII_d
  BEQ rightPress ;if it was D jump to the right routine
  RTS
  
upPress:
  LDA currDir
  CMP #downDir
  BEQ eatItself ;checks if the player pressed down while going up which is an illegal move
  LDA #upDir
  STA currDir ;stores up as the new current direction
  RTS
leftPress:
  LDA currDir
  CMP #rightDir
  BEQ eatItself ;checks if the player pressed right while going left which is an illegal move
  LDA #leftDir
  STA currDir ;stores left as the new current direction
  RTS 
downPress:
  LDA currDir
  CMP #upDir
  BEQ eatItself ;checks if the player pressed up while going down which is an illegal move
  LDA #downDir
  STA currDir ;stores down as the new current direction
  RTS 
rightPress:
  LDA currDir
  CMP #leftDir
  BEQ eatItself ;checks if the player pressed left while going right which is an illegal move
  LDA #rightDir
  STA currDir ;stores right as the new current direction
  RTS
eatItself: ;if this is called the player is attempting to eat themself so the routine just exits to nullify it
  RTS
  
updateSnake:
  LDX snakeLength
  DEX ;initializes X with the value of the snakeLength minus 1 for shiftvalues
  JSR shiftValues
  JSR updateHead
  RTS
  
shiftValues: ;the logic of shiftvalues is that the X offset will capture the hibyte of the last visible pixel of the snake and shift it over in memory by 2 into the hibyte of the tail which is the end of the snake
  LDA snakeHeadL,X 
  STA snakeBodyStart,X
  DEX ;decrement X so the offset will recursively shift the values until it finishes shifting over the head
  BPL shiftValues ;checks if X is negative signifying we have finished shifting over the head and are done
  RTS

updateHead: ;checks what the current direction is
  LDA currDir
  CMP #rightDir
  BEQ right ;branches to subroutine for right
  CMP #downDir
  BEQ down ;branches to subroutine for down
  CMP #upDir
  BEQ up ;branches to subroutine for up
  CMP #leftDir
  BEQ left ;branches to subroutine for left

up:
  LDA snakeHeadL ;load the lowbyte into A
  SEC
  SBC #$20 ;deccrements A by a row of pixels
  STA snakeHeadL ;updates the lowbyte
  BCC decHead ;if we overflowed we decrement hibyte
  RTS
decHead: ;decrements hi byte of snake head 
  DEC snakeHeadH
  JSR gameCheck
  RTS
left:
  DEC snakeHeadL ;decrements lobyte by 1
  LDA snakeHeadL
  AND #$1F ;ANDs lobyte by multiples of 1F
  CMP #$1F ;compares the byte to 1F to check if it wrapped past the left side of the screen
  BEQ end
  RTS 
down:
  LDA snakeHeadL ;load the lowbyte into A
  CLC
  ADC #$20 ;increments A by a row of pixels
  STA snakeHeadL ;updates the lowbyte
  BCS incHead ;if we overflowed we increment hibyte
  RTS
incHead: ;increments hi byte of snake head 
  INC snakeHeadH
  JSR gameCheck
  RTS
right:
  INC snakeHeadL ;increments lobyte by 1
  LDA #$1F
  AND snakeHeadL ;ANDs lobyte with multiples of 1F which checks if it hit the right of the screen
  BEQ end
  RTS
 
gameCheck: ;checks if snakeHeadH hit the top or bottom of screen
  LDA #$01
  CMP snakeHeadH ;if the hibyte is 01 it hit the top
  BEQ end
  LDA #$06
  CMP snakeHeadH ;if the hibyte is 06 it hit the bottom
  BEQ end
  RTS  

drawSnake:
  LDX snakeLength
  LDA #$00 ;loads black into A in order to 'erase'
  STA (snakeHeadL,X) ;using indirect addressing to 'erase' the tail
  LDX #$00 
  LDA #$01 ;loads white into A
  STA (snakeHeadL,X) ;using indirect addressing we draw the head
  RTS
drawApple:
  LDX #$04
  LDA $FE ;loads into the accumulator a random number which will act as a random color
  STA ($00,X) ;load the random color into the apples coordinate using indexed indirect addressing
  RTS

wasteTime: ;runs NOP 256 times to slow down the game
  NOP
  INX
  CPX #$FF
  BNE wasteTime
  RTS
  
end:
  BRK