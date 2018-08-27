global exitgame = false
c=0
delete $*
b = box()
while not exitgame do
(
	--- do stuff here	
	b.width = mouse.pos.x
	if mouse.buttonStates[1] then move b [1,1,1]
	redrawviews()
	exitgame = Keyboard.EscPressed
)
-- esperar a que suelte el esc
repeat until not (Keyboard.EscPressed)
MessageBox "Te vas de mi superjuego!"
Print "Este tipo no se porque me pone interrupted"