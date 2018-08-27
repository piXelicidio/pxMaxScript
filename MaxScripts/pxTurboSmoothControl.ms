utility pxTMSmoothControl "pX TMSmoothControl" width:162 height:396
(
	button btn01 "Increase iterations" pos:[28,108] width:102 height:21
	button btn02 "Decrease iterations" pos:[25,136] width:107 height:21
	spinner spn1 "" pos:[45,164] width:66 height:16 enabled:true range:[0,10,0] type:#integer scale:1
	button btn5 "Set Iterations to 0" pos:[14,193] width:127 height:19
	GroupBox grp1 "" pos:[7,218] width:149 height:118
	label lbl1 "Replace all MeshSmooth modifiers with TurboSmooth. (Only MeshSmooth from Top of the modifiers Stack)" pos:[15,232] width:136 height:57
	button btn18 "Replace" pos:[37,294] width:79 height:24
	label lbl3 "TMSmoothcontrol by piXel  pxtracer@gmail.com www.pixelicidio.com" pos:[8,343] width:142 height:46
	button btn35 "ON" pos:[19,65] width:61 height:27
	GroupBox grp6 "" pos:[8,5] width:149 height:96
	label lbl10 "Set Top stack MeshSmooth / TurboSmooth to..." pos:[14,25] width:138 height:32
	button btn6 "OFF" pos:[87,65] width:61 height:27
	
	function IterationControl delta = 
	(
		for Obj in Selection do
		(
			m = Obj.Modifiers[1]
			if ((classof m) == TurboSmooth) or ((classof m) == MeshSmooth) then
			(
				m.iterations = m.iterations + delta		
			)		
		)
	)
	function SetIterations value = 
	(
		for Obj in Selection do
		(
			m = Obj.Modifiers[1]
			if ((classof m) == TurboSmooth) or ((classof m) == MeshSmooth) then
			(
				m.iterations = value		
			)		
		)
	)
	
	
	on btn01 pressed do
	(
		IterationControl 1
	)
	on btn02 pressed do
	(
		IterationControl -1
	)
	on spn1 changed val do
	(
		btn5.caption = "Set Iterations to " + (val as string)
	)
	on btn5 pressed do
	(
		SetIterations spn1.value
	)
	on btn18 pressed do
	(
		for Obj in Selection do
		(
			m = Obj.Modifiers[1]
			if ((classof m) == MeshSmooth) then
			(
				-- Remplazar por TurboSmooth
				NewM = TurboSmooth()
				NewM.iterations = m.iterations
				DeleteModifier Obj 1
				AddModifier Obj NewM
			)		
		)
	)
	on btn35 pressed do
	(		
		for Obj in selection do
		(
			m = Obj.Modifiers[1]
			if ((classof m) == TurboSmooth) or ((classof m) == MeshSmooth) then
			(
				-- ON!
				m.Enabled = true
			)
		)
	)
	on btn6 pressed do
	(
		for Obj in selection do
		(
			m = Obj.Modifiers[1]
			if ((classof m) == TurboSmooth) or ((classof m) == MeshSmooth) then
			(
				-- OFF
				m.Enabled = false
			)
		)
	)
)