utility pxLocoRandomizer "pX LocoRandomizer" width:162 height:304
(
	--Glabals
	global ValueToRandomize --string
	--Utility Rollout definitions
	GroupBox grp5 "Node Randomization" pos:[2,22] width:158 height:83
	label lblSelection "Selected: 0" pos:[6,5] width:99 height:13
	radiobuttons rdo "" pos:[42,45] width:63 height:48 labels:#("Position", "Rotation", "Scale")
	GroupBox grp3 "Randomize X Y Z values" pos:[3,109] width:157 height:183
	checkbox chkX "X" pos:[13,148] width:30 height:16 checked:true
	checkbox chkY "Y" pos:[13,172] width:32 height:14 checked:true
	checkbox chkZ "Z" pos:[13,196] width:30 height:16 checked:true
	spinner spnx1 "" pos:[45,148] width:47 height:16 enabled:true range:[-10000,10000,-1.5] type:#float scale:0.1 
	spinner spnx2 "" pos:[101,148] width:48 height:16 range:[-10000,10000,1.5] type:#float scale:0.1
	label lbl16 "Axis    Random Interval" pos:[13,126] width:128 height:14		
	spinner spny1 "" pos:[45,172] width:47 height:16 enabled:true range:[-10000,10000,-1.5] type:#float scale:0.1 
	spinner spny2 "" pos:[101,172] width:47 height:16 enabled:true range:[-10000,10000,1.5] type:#float scale:0.1 
	spinner spnz1 "" pos:[45,196] width:47 height:16 enabled:true range:[-10000,10000,-1.5] type:#float scale:0.1 
	spinner spnz2 "" pos:[101,196] width:47 height:16 enabled:true range:[-10000,10000,1.5] type:#float scale:0.1 
	checkbox chk6 "Constant Scale" pos:[46,219] width:104 height:16 enabled:false checked:true
	button btnApply "Apply" pos:[11,246] width:140 height:29
		

		

	rollout rolGeneric "Generic Randomizer!" width:162 height:565
	(
		local SupportedMods = #(Bend, Taper, Skew, Twist, Stretch) 
		edittext edt1 "" pos:[10,24] width:138 height:14
		label lbl8 "Property name (MAXScript)" pos:[16,7] width:139 height:15
		radiobuttons rdo3 "" pos:[14,59] width:134 height:48 labels:#("Float", "Integer", "MAXScript assignations")
		GroupBox grp6 "Value Type" pos:[6,43] width:149 height:70
		GroupBox grp7 "Randomize Value" pos:[6,114] width:148 height:79
		spinner spn13 "Interval" pos:[22,132] width:77 height:16 range:[-10000,10000,-1.5] type:#float scale:0.1
		spinner spn14 "" pos:[99,132] width:49 height:16 range:[-10000,10000,1.5]
		button btnApply1 "Apply" pos:[17,160] width:127 height:25
		GroupBox grp14 "Set Value" pos:[7,194] width:147 height:81 enabled:false
		spinner spn25 "Value" pos:[40,214] width:81 height:16 range:[-10000,10000,0]
		button btnApply2 "Apply" pos:[21,242] width:120 height:25
		GroupBox grp22 "MAXScript assignations list" pos:[5,280] width:152 height:254
		listbox lbx6 "" pos:[11,295] width:135 height:9
		edittext edt8 "" pos:[7,421] width:117 height:16
		button btnAdd "add" pos:[126,420] width:26 height:18
		button btnDelete "Delete selected" pos:[33,443] width:85 height:18
		button btnApply3 "Apply Random" pos:[13,465] width:135 height:33
		button btnApply4 "Apply selected only" pos:[15,503] width:134 height:22
		
		
		on btnAdd pressed do
		(
			lbx6.items = append lbx6.items edt8.text
		)
		on btnDelete pressed do
		(
			if lbx6.selection>0 then lbx6.items = deleteItem lbx6.items lbx6.selection	
		)
	)
    ---------
    ------
	--	
	-----
	---
	------
	--------	
	function UpdateSelection =
	(
		pxLocoRandomizer.lblSelection.Caption = "Selected: " + $Selection.count as string
	)	

	--Events-------------------------

	on pxLocoRandomizer open do
	(
		callbacks.addScript #selectionSetChanged "pxLocoRandomizer.UpdateSelection()" id:#pxLocoRandomizer
		UpdateSelection()	
		ValueToRandomize = "Position"
		addRollout rolGeneric		
	)
	on pxLocoRandomizer close do
	(
		callbacks.removeScripts #selectionSetChanged id:#pxLocoRandomizer
		removeRollout rolGeneric
	)
	on rdo changed state do
	(
	 	chk6.enabled = false
		spny1.enabled = true
		spny2.enabled = true
		spnz1.enabled = true
		spnz2.enabled = true	
		
		case rdo.state of 
		(
			1:(
				ValueToRandomize = "Position"				
			)
			2:(
				ValueToRandomize = "Rotation"
			)
			3:(
				ValueToRandomize = "Scale"
				chk6.enabled = true
				spny1.enabled = not chk6.checked
				spny2.enabled = not chk6.checked
				spnz1.enabled = not chk6.checked
				spnz2.enabled = not chk6.checked				
			)		
				
				
		)
				
	)
	on chk6 changed state do
	(
		spny1.enabled = not chk6.checked
		spny2.enabled = not chk6.checked
		spnz1.enabled = not chk6.checked
		spnz2.enabled = not chk6.checked
	)
	on btnApply pressed do
	(
		undo "pxLocoRandomizer" on
		(
		-- Apply random modifications
		for obj in Selection do
		(
			if chkX.checked then dx = random spnx1.value spnx2.value else dx = 0
			if chkY.checked then dy = random spny1.value spny2.value else dy = 0
			if chkZ.checked then dz = random spnz1.value spnz2.value else dz = 0
			case ValueToRandomize of
			(
				"Position": 
				(
					move obj [dx,dy,dz]
				)
				"Rotation":
				(
					myrot = eulerangles dx dy dz
					rotate obj myrot
				)
				"Scale":
				(
					if chk6.checked then 
					(
						dy = dx
						dz = dx
					)
					obj.scale.x = obj.scale.x - dx/20.0
					obj.scale.y = obj.scale.y - dy/20.0
					obj.scale.z = obj.scale.z - dz/20.0
				)
			)
		)--for
		)--undo		
	)--btnApply pressed
)