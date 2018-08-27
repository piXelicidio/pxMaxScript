utility pxLocoRandomizer "pX LocoRandomizer" width:162 height:304
(
	--Glabals
	global ValueToRandomize --string
	global objXXX
	global errCount
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
		
    rollout rolAbout "About..." width:162 height:91
    (
    	label lbl13 "pX LocoRandomizer" pos:[32,14] width:97 height:19
    	label lbl14 "by Denys Almaral (piXel)" pos:[21,42] width:119 height:19
    	label lbl15 "Version 1.0 - November 2008" pos:[8,62] width:146 height:16
		
    )		

	rollout rolGeneric "Generic Randomizer!" width:162 height:674
	(
		edittext edtPropName "" pos:[10,23] width:141 height:14
		label lbl8 "Property name (MAXScript)" pos:[16,7] width:139 height:15
		GroupBox grp7 "Randomize Value" pos:[6,114] width:148 height:79
		spinner spn13 "Interval" pos:[22,132] width:77 height:16 range:[-10000,10000,-1.5] type:#float scale:0.1
		spinner spn14 "" pos:[99,132] width:49 height:16 range:[-10000,10000,1.5]
		button btnApply1 "Apply" pos:[17,160] width:127 height:25
		GroupBox grp14 "Set Value" pos:[7,194] width:147 height:81 
		spinner spn25 "Value" pos:[40,214] width:81 height:16 range:[-10000,10000,0]
		button btnApply2 "Apply" pos:[21,242] width:120 height:25
		GroupBox grp22 "MAXScript assignations list" pos:[5,280] width:152 height:254
		listbox lbx6 "" pos:[11,296] width:135 height:8
		edittext edt8 "" pos:[7,421] width:117 height:16
		button btnAdd "add" pos:[126,420] width:26 height:18
		button btnDelete "Delete selected" pos:[33,443] width:85 height:18
		button btnApply3 "Apply Random" pos:[13,465] width:135 height:33
		button btnApply4 "Apply selected only" pos:[15,503] width:134 height:22
		label lblSel2 "Objects selected: 0" pos:[15,43] width:121 height:15
		label lblSuc "Successes: 0" pos:[12,61] width:122 height:15
		label lblErr "Errors: 0" pos:[12,80] width:88 height:14		
				
		GroupBox grpPresets "Load example presets..." pos:[4,534] width:154 height:127
		listbox lbx5 "" pos:[8,551] width:146 height:6 enabled:true items:#("First 3 Mat.Editor Materials", "Lights ON/OFF", "Lights Random Colors","UVW Mapping gizmo x","Angle from Blend Modifier")
		button btnLoad "Load" pos:[91,637] width:58 height:18
		
			
		--presets------

		on rolGeneric open do
		(
			edtPropName.text = "position.x"
		)
		on btnApply1 pressed do --Randomize Value
		(
			undo "pxLocoRandomizer" on
			(
				errCount = 0
				for i=1 to Selection.count do
				(
					dvalue = random spn13.value spn14.value
					objXXX = Selection[i]
					s = "objXXX." + edtPropName.text + " += " + (dvalue as string)
					try (execute s) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				lblErr.caption = "Errors: " + errCount as string
			)
		)
		on btnApply2 pressed do --Set Value
		(
			undo "pxLocoRandomizer" on
			(
				errCount = 0
				dvalue = spn25.value
				for i=1 to Selection.count do
				(					
					objXXX = Selection[i]
					s = "objXXX." + edtPropName.text + " = " + (dvalue as string)
					try (execute s) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				lblErr.caption = "Errors: " + errCount as string
			)
		)
		on lbx6 doubleClicked idx do
		(
			edt8.text = lbx6.items[idx]
		)
		on btnAdd pressed do
		(
			lbx6.items = append lbx6.items edt8.text
		)
		on btnDelete pressed do
		(
			if lbx6.selection>0 then lbx6.items = deleteItem lbx6.items lbx6.selection	
		)
		on btnApply3 pressed do --Set Value
		(
			if lbx6.items.count>0 then
			(
			undo "pxLocoRandomizer" on
			(
				errCount = 0
				for i=1 to Selection.count do
				(				
					RndItem = random 1 lbx6.items.count	
					ItemString = lbx6.items[RndItem]
					objXXX = Selection[i]
					s = "objXXX." + edtPropName.text + " = " + ItemString
					try (execute s) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				lblErr.caption = "Errors: " + errCount as string
			)--undo
			)--if
		)--on
		on btnApply4 pressed do --Set Value
		(
			if lbx6.selection>0 then
			(
			undo "pxLocoRandomizer" on
			(
				errCount = 0
				ItemString = lbx6.selected
				for i=1 to Selection.count do
				(											
					objXXX = Selection[i]
					s = "objXXX." + edtPropName.text + " = " + ItemString
					try (execute s) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				lblErr.caption = "Errors: " + errCount as string
			)--undo
			)--if
		)--on
		on btnLoad pressed do
		(
			case lbx5.selection of
			(
			1:(
				lbx6.items = #("GetMEditMaterial 1","GetMEditMaterial 2","GetMEditMaterial 3");
				edtPropName.text = "Material"				
				)
			2:(
				lbx6.items = #("True", "False")
				edtPropName.text = "On"
				)
			3:(
				lbx6.items = #("random (color 50 50 50) (color 200 200 200)")
				edtPropName.text = "Color"
			  )
			4:(
				lbx6.items = #()
				edtPropName.text = "UVWMapping.gizmo.position.x"
			  )
			5:(
				lbx6.items = #()
				edtPropName.text = "Blend.angle"
			  )		
			
			)--case
		)--on
	)	--	
	-----
	---
	------
	--------	
	function UpdateSelection =
	(
		pxLocoRandomizer.lblSelection.Caption = "Selected: " + $Selection.count as string
		rolGeneric.lblSel2.Caption = "Objects selected: " + $Selection.count as string
	)	

	--Events-------------------------

	on pxLocoRandomizer open do
	(
		callbacks.addScript #selectionSetChanged "pxLocoRandomizer.UpdateSelection()" id:#pxLocoRandomizer
		UpdateSelection()	
		ValueToRandomize = "Position"
		addRollout rolGeneric	
		addRollout rolAbout	
	)
	on pxLocoRandomizer close do
	(
		callbacks.removeScripts #selectionSetChanged id:#pxLocoRandomizer
		removeRollout rolGeneric
		removeRollout rolAbout
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