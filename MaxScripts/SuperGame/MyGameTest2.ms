rollout pepe "poepe" width:162 height:249
(
	timer tmr1 "Timer" pos:[18,51] width:24 height:24 interval:5
	on tmr1 tick  do
	(
		e = eulerangles 0 0 1
		rotate $box01 e
		if keyboard.ControlPressed then
		(
			Move $Box01 [0,0,1]
		)
		if keyboard.ShiftPressed then
		(
			Move $Box01 [0,0,-1]
		)
	)
)
createdialog pepe