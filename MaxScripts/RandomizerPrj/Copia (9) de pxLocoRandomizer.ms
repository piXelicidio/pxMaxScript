utility pxLocoRandomizer "pX LocoRandomizer" width:162 height:304
(
	--Glabals
	local ValueToRandomize --string
	global objXXX
	local errCount
	local MaxVer = (maxVersion())[1]
	
	--Utility Rollout definitions-----------------------------
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
	button btnApply "Apply" pos:[55,246] width:96 height:29
	
	--nested rollouts----------------------------------------------------	
    rollout rolAbout "About..." width:162 height:124
    (
    	label lbl13 "pX LocoRandomizer" pos:[32,14] width:97 height:19
    	label lbl14 "by Denys Almaral (piXel)" pos:[21,42] width:119 height:19
    	label lbl15 "Version 1.0 - November 2008" pos:[8,62] width:146 height:16
    	button btn79 "close" pos:[56,95] width:41 height:18
		
    	on btn79 pressed  do closeUtility pxLocoRandomizer
    )
	rollout rolGeneric "Generic Randomizer!" width:162 height:674
	(
		local pnames = #()
		local sa = undefined
	
		edittext edtPropName "" pos:[11,16] width:141 height:14
		label lbl8 "Property name (MAXScript)" pos:[16,2] width:139 height:15
		GroupBox grp7 "Randomize Value" pos:[7,123] width:150 height:75
		spinner spn13 "Interval" pos:[21,143] width:77 height:16 range:[-10000,10000,-1.5] type:#float scale:0.1
		spinner spn14 "" pos:[99,143] width:49 height:16 range:[-10000,10000,1.5]
		button btnApply1 "Apply" pos:[58,166] width:94 height:25
		GroupBox grp14 "Set Value" pos:[7,199] width:147 height:76 
		spinner spn25 "Value" pos:[40,218] width:81 height:16 range:[-10000,10000,0]
		button btnApply2 "Apply" pos:[57,241] width:91 height:25
		GroupBox grp22 "MAXScript assignations list" pos:[5,280] width:152 height:254
		listbox lbx6 "" pos:[11,296] width:135 height:8
		edittext edt8 "" pos:[7,421] width:117 height:16
		button btnAdd "add" pos:[126,420] width:26 height:18
		button btnDelete "Delete selected" pos:[33,443] width:85 height:18
		button btnApply3 "Apply Random" pos:[13,465] width:135 height:33
		button btnApply4 "Apply selected only" pos:[15,503] width:134 height:22
		label lblSel2 "Selected: 0" pos:[29,86] width:121 height:15
		label lblSuc "Successes: 0" pos:[20,101] width:122 height:15
				
		GroupBox grpPresets "Load example presets..." pos:[4,534] width:154 height:127
		listbox lbx5 "" pos:[8,551] width:146 height:6 enabled:true items:#("First 3 Mat.Editor Materials", "Lights ON/OFF", "Lights Random Colors", "UVW Mapping gizmo x", "Angle from Blend Modifier")
		button btnLoad "Load" pos:[91,637] width:58 height:18 
		label lblType "Type: ?" pos:[8,59] width:154 height:16
		button btnPick "Pick..." pos:[87,33] width:62 height:20 toolTip:"Pick property from tree view. Enabled only when single object selected."
		button btnTest "Test" pos:[14,33] width:64 height:19 toolTip:"Test property. Enabled only when single object selected."
		checkbox chkAdd1 "Add" pos:[14,170] width:41 height:18 checked:true
		
			
		---rolGeneric---functions--------------
		
		--recursive function
		function SearchSubAnim ObjX =
		(
			local condition 
			if MaxVer <7000 then 
			(
				condition = (ObjX == sa) 
				if (classof ObjX)==subanim then condition = condition and (sa.value == ObjX.value)
			) else condition = (ObjX == sa) and (ObjX.name == sa.name)
			
			if condition then 
			(						
				return true
			)
			for i=1 to ObjX.numSubs do
			(
				if SearchSubAnim ObjX[i] then 
				(				
					n = getsubanimname ObjX i
					pnames = append pnames n
					return true
				)
			)
			
			return false	
		)					
		function PickParameterPath =
		(		
			if $Selection.count!=1 then
			(MessageBox "You most select ONE object only.." )
			else
			(
			 
			opts = 0
			opts = bit.set opts 2 true
			opts = bit.set opts 3 true
			opts = bit.set opts 10 true
			opts = bit.set opts 27 true
			if MaxVer < 7000 then tvp = trackView.pickTrackDlg() 
							 else tvp = trackView.pickTrackDlg options:opts
			if (tvp!=undefined) and (tvp.client!=undefined) then 
			( 
				sa = tvp.client[ tvp.subnum ]
				if sa != undefined then
				(
					pnames = #()
					
					if SearchSubAnim $selection[1] then
					(--ok
					)
					else
					(
						if MaxVer <7000 then MessageBox ("Parameter not found in selected object: "+$.name)
										else MessageBox ("Parameter: '"+sa.name+"'  not found in selected object: "+$.name)
					)
					
					
				)--if sa<>undefined
			  )--if tvp undefined		
			)--if selection
			return #(pnames, sa)
		)--end function
		
		function ConvParamPathToString pnames =
		(
			s = "" 
			for i=1 to pnames.count do
			(
			 	s = "[#"+ (pnames[i] as string)+"]" + s
			)
			return s
		)


		---rolGeneric---events-----------

		on rolGeneric open do
		(
			edtPropName.text = ".position.x"
		)
		on btnApply1 pressed do --Randomize Value
		(
			
			undo "pxLocoRandomizer" on
			(
				errCount = 0
				if chkAdd1.checked then oper=" += " else oper=" = "
				s = "objXXX" + edtPropName.text + oper
				for i=1 to Selection.count do
				(
					dvalue = random spn13.value spn14.value
					objXXX = Selection[i]
					es = s + (dvalue as string)
					try (execute es) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				
			)
		)
		on btnApply2 pressed do --Set Value
		(
			undo "pxLocoRandomizer" on
			(
				errCount = 0
				dvalue = spn25.value
				s = "objXXX" + edtPropName.text + " = " + (dvalue as string)
				for i=1 to Selection.count do
				(					
					objXXX = Selection[i]					
					try (execute s) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				
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
				s = "objXXX" + edtPropName.text + " = "
				for i=1 to Selection.count do
				(				
					RndItem = random 1 lbx6.items.count	
					ItemString = lbx6.items[RndItem]
					objXXX = Selection[i]
					es = s + ItemString
					try (execute es) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string
				
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
				s = "objXXX" + edtPropName.text + " = " + ItemString
				for i=1 to Selection.count do
				(											
					objXXX = Selection[i]					
					try (execute s) catch (errCount += 1);
				)
				lblSuc.caption = "Successes: " +  (Selection.count - errCount) as string				
			)--undo
			)--if
		)--on
		on btnLoad pressed do
		(
			case lbx5.selection of
			(
			1:(
				lbx6.items = #("GetMEditMaterial 1","GetMEditMaterial 2","GetMEditMaterial 3");
				edtPropName.text = ".Material"				
				)
			2:(
				lbx6.items = #("True", "False")
				edtPropName.text = ".On"
				)
			3:(
				lbx6.items = #("random (color 50 50 50) (color 200 200 200)")
				edtPropName.text = ".Color"
			  )
			4:(
				lbx6.items = #()
				edtPropName.text = "UVWMapping.gizmo.position.x"
			  )
			5:(
				lbx6.items = #()
				edtPropName.text = ".Blend.angle"
			  )		
			
			)--case
		)--on
		on btnPick pressed do
		(
			res = PickParameterPath()
			s = ConvParamPathToString( res[1] )
			if s!="" then 
			(
				edtPropName.text = s+".value"
				try(lblType.caption = "Type: "+ (classof res[2].value) as string)
				catch(lblType.caption = "Type: ?"	)				
			)
		)
		on btnTest pressed do
		(
			res = "mm"
			objXXX = Selection[1]
			s = "(classof objXXX" + edtPropName.text + ") as string"
			try (res = execute s) catch (res = "NOT FOUND")
			lblType.caption = "Type: "+ res
		
		)
	)	---
	---
	---
	--
	------
	------
	--pxLocoRandomizer----- functions----------------	
	function UpdateSelection =
	(
		pxLocoRandomizer.lblSelection.Caption = "Selected: " + $Selection.count as string
		rolGeneric.lblSel2.Caption = "Selected: " + $Selection.count as string
		rolGeneric.btnTest.enabled = ($Selection.count==1)
		rolGeneric.btnPick.enabled = ($selection.count==1)
		
	)


	--pxLocoRandomizer---------Events-------------------------
	checkbox chkAdd0 "Add" pos:[9,252] width:41 height:18 checked:true
	on pxLocoRandomizer open do
	(
		callbacks.addScript #selectionSetChanged "pxLocoRandomizer.UpdateSelection()" id:#pxLocoRandomizer
			
		ValueToRandomize = "Position"
		addRollout rolGeneric	
		addRollout rolAbout	
		
		UpdateSelection()
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
			if chkAdd0.checked then
			(
				if chkX.checked then dx = random spnx1.value spnx2.value else dx = 0
				if chkY.checked then dy = random spny1.value spny2.value else dy = 0
				if chkZ.checked then dz = random spnz1.value spnz2.value else dz = 0
			) else
			(
				case ValueToRandomize of 
				(
					"Position":(
						if chkX.checked then dx = random spnx1.value spnx2.value else dx = obj.position.x
						if chkY.checked then dy = random spny1.value spny2.value else dy = obj.position.y
						if chkZ.checked then dz = random spnz1.value spnz2.value else dz = obj.position.z
					)
					"Rotation":(
						myrot = obj.rotation as eulerangles
						if chkX.checked then dx = random spnx1.value spnx2.value else dx = myrot.x
						if chkY.checked then dy = random spny1.value spny2.value else dy = myrot.y
						if chkZ.checked then dz = random spnz1.value spnz2.value else dz = myrot.z
					)
					"Scale":(
						if chkX.checked then dx = random spnx1.value spnx2.value else dx = obj.scale.x
						if chkY.checked then dy = random spny1.value spny2.value else dy = obj.scale.y
						if chkZ.checked then dz = random spnz1.value spnz2.value else dz = obj.scale.z
					)
				)				
			)
			case ValueToRandomize of
			(
				"Position": 
				(
					if chkAdd0.checked then
					move obj [dx,dy,dz]
					else
					obj.position = [dx,dy,dz]
				)
				"Rotation":
				(
					myrot = eulerangles dx dy dz
					if chkAdd0.checked then
					rotate obj myrot
					else
					obj.rotation = myrot
				)
				"Scale":
				(
					if chk6.checked then 
					(
						dy = dx
						dz = dx
					)
					if chkAdd0.checked then
					(
					obj.scale.x = obj.scale.x + dx/20.0
					obj.scale.y = obj.scale.y + dy/20.0
					obj.scale.z = obj.scale.z + dz/20.0
					)
					else
					(
					obj.scale.x =  dx
					obj.scale.y =  dy
					obj.scale.z =  dz
					)
				)
			)
		)--for
		)--undo		
	)--btnApply pressed
)