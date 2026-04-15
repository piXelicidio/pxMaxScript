--Morph sliders by Denys Almaral


macroScript MorphSliders category:"pX Tools" buttonText:"Quick Morph Sliders"
(
	local MorphList = #() --[i][1]= name [1][2] subAnim
	local MixItemUp     = 0
	local MixItemDown = 0
	local MixItemLeft   = 0
	local MixItemRight  = 0
	
	struct IniFile
	(
		filename,
		section,
		function read key =
		(
			(getINISetting filename section key)
		),

		function write key value =
		(
			(setINISetting filename section key (value as string))
		),

		function remove key =
		(
			delIniSetting filename section key
		),

		function removeSection =
		(
			delIniSetting filename section
		),

		function hasKey key =
		(
			(hasINISetting filename section key)
		),

		function hasSection =
		(
			(hasINISetting filename section)
		)
	)

	fn getScriptIniFilePath =
	(
		return (getDir #usermacros) + "\\pxMorphSliders.ini"		
	)

	fn saveBool ini key value =
	(
		ini.write key (if value then "1" else "0")
	)

	fn loadBool ini key defaultValue =
	(
		local value = ini.read key
		if value == "" then defaultValue else (value != "0")
	)

	fn colorToString c =
	(
		(c.r as string) + "_" + (c.g as string) + "_" + (c.b as string)
	)

	fn stringToColor s =
	(
		if s == undefined or s == "" then undefined
		else
		(
			local parts = filterString s "_"
			if parts.count == 3 then color (parts[1] as integer) (parts[2] as integer) (parts[3] as integer) else undefined
		)
	)

	rollout roll_MorphSliders "Sliders" width:406 height:388
	(
		button 'btnCreate' "Create simple sliders" pos:[8,301] width:172 height:28 align:#left
		listbox 'lbxChannels' "Channel List" pos:[7,38] width:176 height:15 align:#left 
 
		button 'btnGetMorphs' "ADD MORPH CHANNELS" pos:[20,8] width:200 height:25 toolTip:"Get Morpher Channels from selected object" align:#left
		GroupBox 'grp1' "4 channels Mix Slider" pos:[193,47] width:201 height:211 align:#left

		button 'btnSetUp' "^  Up" pos:[242,75] width:100 height:24 align:#left			
			
				
		button 'btnSetDown' "V  Down" pos:[246,180] width:100 height:24 align:#left
		button 'btnSetLeft' "<  Left" pos:[200,128] width:78 height:24 align:#left
		button 'btnSetRight' "Right >" pos:[304,128] width:82 height:24 align:#left



		button 'btnRemoveAll' "clear" pos:[200,223] width:51 height:24 toolTip:"Remove All" align:#left
		button 'btnCreateMix' "Create Slider Mix" pos:[257,215] width:125 height:34 align:#left
		
		edittext 'edtPrefix' "Prefix" pos:[204,277] width:95 height:17 align:#left
		checkbox 'chkIgnoreWired' "Skip wired" pos:[10,277] width:77 height:18 checked:true align:#left
		checkbox 'chkSelectedOnly' "Selected Item Only" pos:[11,259] width:120 height:18 checked:false align:#left
		button 'btnUnwire' "Restore controllers (Unwire)" pos:[8,332] width:171 height:26 toolTip:"Restore morph channel controllers to Float Bezier without wiring" align:#left
		button 'btnRemoveAllChannels' "Remove All" pos:[11,364] width:66 height:19 align:#left
		button 'btnRemoveSel' "Remove Selected" pos:[83,365] width:95 height:17 align:#left
		spinner 'spnSize' "Size" pos:[205,303] width:85 height:16 range:[0.1,100,2] align:#left
		checkbox 'chkChildOf' "Make it child of selected" pos:[205,325] checked:false 
		checkbox 'chkReplace' "Replace existing by  name" pos:[205,350] checked:true
		--progressBar pbar "ProgressBar" pos:[99,280] width:81 height:14
		colorPicker 'cpSlider' "Slider" pos:[317,278] width:54 height:18 color:(color 220 255 100) title:"Choose a color" align:#left
		colorPicker 'cpBase' "Base" pos:[322,304] width:52 height:19 color:(color 100 100 200) align:#left
		 
 
		HyperLink 'LinkHelp' "(?) Help" pos:[344,12] width:43 height:16 color:(color 0 0 255) hovercolor:(color 0 100 255) address:"https://denysalmaral.com/post/px-quick-morph-sliders-creation-tool-for-3ds-max/" align:#left
		
		function FreezeTransform CurObj = 	
		( 			
			suspendEditing which:#motion
			-- freeze rotation		
			CurObj.rotation.controller = Euler_Xyz() 		
			CurObj.rotation.controller = Rotation_list() 			
			CurObj.rotation.controller.available.controller = Euler_xyz() 		
						
			CurObj.rotation.controller.setname 1 "Frozen Rotation"		
			CurObj.rotation.controller.setname 2 "Zero Euler XYZ" 				
						
			CurObj.rotation.controller.SetActive 2 		
			
			-- freeze position
			CurObj.position.controller = Bezier_Position() 			
			CurObj.position.controller = position_list() 			
			CurObj.position.controller.available.controller = Position_XYZ() 	
								
			CurObj.position.controller.setname 1 "Frozen Position"
			CurObj.position.controller.setname 2 "Zero Pos XYZ"			
						
			CurObj.position.controller.SetActive 2 		

			-- position to zero
			CurObj.Position.controller[2].x_Position = 0
			CurObj.Position.controller[2].y_Position = 0
			CurObj.Position.controller[2].z_Position = 0	
			resumeEditing which:#motion
		)
		
		function UpdateListbox =
		(			
			local newItems=#()
			for i=1 to MorphList.count do
			(
				moName = MorphList[i][1] 
				if ((classof MorphList[i][2].controller)==Float_Wire)  then append NewItems (moName+" (wired)") else append NewItems moName 
			)
			lbxChannels.items = NewItems
		)

		--on lbxChannels 

        
		function GetItemsToProcess =
		(
			local items = #()
			for i=1 to MorphList.count do
			(
				if (chkIgnoreWired.checked and ((classof MorphList[i][2].controller)==Float_Wire)) then continue
				if (chkSelectedOnly.checked and (lbxChannels.selection!=i)) then continue
				append items MorphList[i]
			)
			return items
		)

		function UpdateCreateButtonCaption =
		(
			local items = GetItemsToProcess()
			btnCreate.caption = "Create (" + (items.count as string) + ") simple sliders"
			if (items.count == 0) then btnCreate.enabled = false else btnCreate.enabled = true
		)

		function UpdateMixButtonState =
		(
			local count = 0
			if MixItemUp != 0 then count += 1
			if MixItemDown != 0 then count += 1
			if MixItemLeft != 0 then count += 1
			if MixItemRight != 0 then count += 1
			btnCreateMix.enabled = (count >= 2)
		)

		on roll_MorphSliders open do
		(
			local ini = IniFile()
			ini.filename = getScriptIniFilePath()
			ini.section = "MorphSliders"
			chkIgnoreWired.checked = loadBool ini "chkIgnoreWired" true
			chkSelectedOnly.checked = loadBool ini "chkSelectedOnly" false
			local prefixVal = ini.read "edtPrefix"
			if prefixVal != "" then edtPrefix.text = prefixVal
			local spnValue = ini.read "spnSize"
			if spnValue != "" then spnSize.value = spnValue as float
			chkChildOf.checked = loadBool ini "chkChildOf" false
			chkReplace.checked = loadBool ini "chkReplace" true
			local sliderColor = stringToColor (ini.read "cpSlider")
			if sliderColor != undefined then cpSlider.color = sliderColor
			local baseColor = stringToColor (ini.read "cpBase")
			if baseColor != undefined then cpBase.color = baseColor
			UpdateCreateButtonCaption()
			UpdateMixButtonState()
		)
		on roll_MorphSliders close do
		(
			local ini = IniFile()
			ini.filename = getScriptIniFilePath()
			ini.section = "MorphSliders"
			saveBool ini "chkIgnoreWired" chkIgnoreWired.checked
			saveBool ini "chkSelectedOnly" chkSelectedOnly.checked
			ini.write "edtPrefix" edtPrefix.text
			ini.write "spnSize" (spnSize.value as string)
			saveBool ini "chkChildOf" chkChildOf.checked
			saveBool ini "chkReplace" chkReplace.checked
			ini.write "cpSlider" (colorToString cpSlider.color)
			ini.write "cpBase" (colorToString cpBase.color)
		)
		on btnCreate pressed do
		(
			undo "Create Sliders" on
			(
				--settings
				local replaceSliders = chkReplace.checked
				local skipWired = chkIgnoreWired.checked								
				local SliderSize = SpnSize.value
			    local SlidersSDx = 1.0 + SliderSize
				local sliderShapes = true
				
				local prefix = edtPrefix.text
		
				-- Go for each channel
				local itemsToProcess = GetItemsToProcess()
				
				cCount = 0
				for i=1 to itemsToProcess.count do 
				(
						moName = itemsToProcess[i][1]
						cCount = cCount + 1
						--SliderShapes 
						sbase = rectangle()									
									sbase.width = 0.4
									sbase.length = SliderSize 
									sbase.wireColor = cpBase.color
									sbase.pivot.y = -SliderSize/2
									s = donut()
									s.radius1 = 0.1
									s.radius2 = SliderSize/4
									s.wireColor = cpSlider.color
									FreezeTransform s
									s.parent = sbase
									
									setTransformLockFlags s (#{1..9}-#{2})									
									subani = s[#transform][#position][2][#Y_position]
									nc = Float_Limit()
									nc.lower_limit = 0
									nc.upper_limit = SliderSize
									subani.controller = nc
									
									sbase.pos.x = 0.1 + cCount*SlidersSDx	
									sbase.pos.y = 0
									sbase.pos.z = -1 - SliderSize
									
									rotate sbase (angleaxis 90 [1,0,0])
									-- Parameters wiring
									paramWire.connect subani itemsToProcess[i][2] ("Y_Position*100/"+(SliderSize as string))
									paramWire.connect subani sbase.baseObject[#width] ("Y_Position/2+0.1")
									--deleting olds, setNames
									newName = prefix+"Sliderb_" + moName					
									existObj =  Execute ("$"+newName)
									if (existObj!=undefined) and replaceSliders then delete existObj
									sbase.Name = newName
									newName = prefix+"Slider_" + moName					
									existObj =  Execute ("$"+newName)
									if (existObj!=undefined) and replaceSliders then delete existObj
									s.Name = newName

									if (chkChildOf.checked) then 
									(
										local posi = sbase.pos 
										sbase.parent = $
										in coordsys parent
										(
											sbase.pos = posi
										)
									)
								
						) -- for i=1 to itemsToProcess.count
						
				UpdateListbox()
				UpdateCreateButtonCaption()
			)
		)--On button pressed
		on chkIgnoreWired changed state do UpdateCreateButtonCaption()
		on chkSelectedOnly changed state do UpdateCreateButtonCaption()
		on lbxChannels selected idx do UpdateCreateButtonCaption()
		on btnGetMorphs pressed do
		(
			if $!=undefined then
			(
				mo = undefined				
				for i=1 to $.modifiers.count do
				(
						if (classof $.modifiers[i])==Morpher then
						(
							mo = $.modifiers[i]
							break
						)
				)				
								
				
				if mo!=undefined then
				(				
					local capacity = wm3_NumberOfChannels mo
					for i=1 to capacity do
					(						
						if (WM3_MC_HasData mo i) then
						(
							moName = substituteString (WM3_MC_GetName mo i) " " "_"
							append MorphList #(moName, mo[i])								
						)
					)
					
					
					
				)
				UpdateListbox()
				UpdateCreateButtonCaption()
				
			)				
		)
		on btnSetUp pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				if idx!=0 then
				(
					btnSetUp.text = "^ " + MorphList[idx][1]
					MixItemUp = idx
					UpdateMixButtonState()
					if lbxChannels.selection<lbxChannels.items.count then 
					(
						lbxChannels.selection = idx+1
						UpdateCreateButtonCaption()
					)
				)
			)
		)
		on btnSetDown pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				if idx!=0 then
				(
					btnSetDown.text = "V " + MorphList[idx][1]
					MixItemDown = idx
					UpdateMixButtonState()
					if lbxChannels.selection<lbxChannels.items.count then 
					(
						lbxChannels.selection = idx+1
						UpdateCreateButtonCaption()
					)
				)
			)
		)
		on btnSetLeft pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				if idx!=0 then
				(
					btnSetLeft.text = "< " + MorphList[idx][1]
					MixItemLeft = idx
					UpdateMixButtonState()
					if lbxChannels.selection<lbxChannels.items.count then 
					(
						lbxChannels.selection = idx+1
						UpdateCreateButtonCaption()
					)
				)
			)
		)
		on btnSetRight pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				if idx!=0 then
				(
					btnSetRight.text = MorphList[idx][1] + " >"
					MixItemRight = idx
					UpdateMixButtonState()
					if lbxChannels.selection<lbxChannels.items.count then 
					(
						lbxChannels.selection = idx+1
						UpdateCreateButtonCaption()
					)
				)
			)
		)
		on btnRemoveAll pressed do
		(
			btnSetUp.text = "^  Up"			
			btnSetDown.text = "V  Down"
			btnSetLeft.text = "<  Left"
			btnSetRight.text = "Right >"
			MixItemDown = 0
			MixItemUp = 0			
			MixItemLeft = 0
			MixItemRight = 0
			UpdateMixButtonState()
		)
		on btnCreateMix pressed do
		(
			undo "Create Mix Slider" on
			(
				local replaceSliders = true
				local skipWired = false				
				local SlidersSDx = SpnSize.value + 1
				local SliderSize = SpnSize.value
				local sliderShapes = true
				
				local SlidersColCount =8
				local prefix = edtPrefix.text
				local moName=""
				
				if ((MixItemUp!=0) or (MixItemDown!=0) or (MixItemLeft!=0) or (MixItemRight!=0)) then 
				(
					
						sbase = rectangle()
						sbase.width =SliderSize
						sbase.length = SliderSize
						sbase.wireColor = cpBase.color
								
						s = donut()
						
						s.radius1 = 0.1
						s.radius2 = SliderSize/4
						s.wireColor = cpSlider.color
						FreezeTransform s
						s.parent = sbase
						setTransformLockFlags s (#{1..9}-#{1,2})				
						subaniX = s[#transform][#position][2][#X_position]
						subaniY = s[#transform][#position][2][#Y_position]				
						ncX = Float_Limit()
						ncX.lower_limit = 0
						ncX.upper_limit = 0
						subaniX.controller = ncX
						ncY = Float_Limit()
						ncY.lower_limit = 0
						ncY.upper_limit = 0
						subaniY.controller = ncY
						
						if MixItemUp!=0 then
						(
							rect = rectangle()
							rect.name = uniquename (prefix + "mix_rec_" + MorphList[MixItemUp][1])
							rect.parent = sbase					
							rect.length = SliderSize 
							rect.wireColor = cpBase.color
							rect.pivot.y = -SliderSize/2
							rect.pos.y = 0					
							
							ncY.upper_limit = SliderSize
							moName = moName + "_" + MorphList[MixItemUp][1]
							paramWire.connect subaniY MorphList[MixItemUp][2] ("(abs(Y_Position)+Y_Position)*50/"+(SliderSize as string))
							paramWire.connect subaniY rect.baseObject[#width] ("Y_Position/2+0.1")	
							sbase.length = SliderSize*2
						)
						if MixItemDown!=0 then
						(		
							rect = rectangle()
							rect.name = uniquename (prefix + "mix_rec_" + MorphList[MixItemDown][1])
							rect.parent = sbase					
							rect.length = SliderSize 
							rect.wireColor = cpBase.color
							rect.pivot.y = -SliderSize/2
							rect.pos.y = 0					
							rotate rect (angleaxis 180 [0,0,1])					
							
							ncY.lower_limit = -SliderSize	
							moName = moName + "_" + MorphList[MixItemDown][1]
							paramWire.connect subaniY MorphList[MixItemDown][2] ("(abs(-Y_Position)-Y_Position)*50/"+(SliderSize as string))
							paramWire.connect subaniY rect.baseObject[#width] ("Y_Position/-2+0.1")		
							sbase.length = SliderSize*2	
						)
						if MixItemLeft!=0 then
						(
							rect = rectangle()
							rect.name = uniquename (prefix + "mix_rec_" + MorphList[MixItemLeft][1])
							rect.parent = sbase					
							rect.length = SliderSize 
							rect.wireColor = cpBase.color
							rect.pivot.y = -SliderSize/2
							rect.pos.y = 0
							rotate rect (angleaxis 90 [0,0,1])					
												
							ncX.lower_limit = -SliderSize
							moName = moName + "_" + MorphList[MixItemLeft][1]
							paramWire.connect subaniX MorphList[MixItemLeft][2] ("(abs(-X_Position)-X_Position)*50/"+(SliderSize as string))
							paramWire.connect subaniX rect.baseObject[#width] ("X_Position/-2+0.1")		
							sbase.Width = SliderSize*2	
						)
						if MixItemRight!=0 then
						(
							rect = rectangle()
							rect.name = uniquename (prefix + "mix_rec_" + MorphList[MixItemRight][1])
							rect.parent = sbase					
							rect.length = SliderSize 
							rect.wireColor = cpBase.color
							rect.pivot.y = -SliderSize/2
							rect.pos.y = 0
							rotate rect (angleaxis -90 [0,0,1])	
							
							ncX.upper_limit = SliderSize
							moName = moName + "_" + MorphList[MixItemRight][1]
							paramWire.connect subaniX MorphList[MixItemRight][2] ("(abs(X_Position)+X_Position)*50/"+(SliderSize as string))
							paramWire.connect subaniX rect.baseObject[#width] ("X_Position/2+0.1")	
							sbase.width = SliderSize*2
						)
						
						sbase.name = uniquename (prefix + "mix_sliderb" + moName)
						s.name = uniquename (prefix + "mix_slider" + moName)
						sbase.pos.x = 0
						sbase.pos.y = 0
						sbase.pos.z = -1-SliderSize				
						rotate sbase (angleaxis 90 [1,0,0])

						if (chkChildOf.checked) then 
						(
							local posi = sbase.pos 
							sbase.parent = $
							in coordsys parent
							(
								sbase.pos = posi
							)
						)
						UpdateListbox()
					
				)
			)
		)
		on btnUnwire pressed do
		(
			local msg = "This will remove the wiring for the selected morph channels and restore them to default Bezier Float controllers.\n\nSliders will stop working for these channels. Do you want to continue?"
			if (queryBox msg title:"Restore Controllers (Unwire)") then
			(
				undo "Unwire Morphs" on
				(
					for i=1 to MorphList.count do 			 
					(				
						if (chkSelectedOnly.checked and (lbxChannels.selection!=i)) then continue
						if  ((classof MorphList[i][2].controller)==Float_Wire)   then MorphList[i][2].controller=Bezier_Float()
					)			
					UpdateListbox()
					UpdateCreateButtonCaption()
				)
			)
		)
		on btnRemoveAllChannels pressed do
		(
			MorphList=#()
			UpdateListbox()
			UpdateCreateButtonCaption()
		)
		on btnRemoveSel pressed do
		(
			if (LbxChannels.selection!=undefined)  then DeleteItem MorphList LbxChannels.selection
			UpdateListbox()
			UpdateCreateButtonCaption()
		)
	)
	
    rollout roll_Tools "Tools" width:395 height:38
    (
        local objWithMorpher = undefined
        local operations = #("replace", "add")
        function morphFilter obj = (obj.modifiers[#morpher]!=undefined)
        group "Assign Multiple Morph Targets" (
            pickbutton pickMorpher "Pick Object with Morpher" filter:morphFilter across:2
            button btnAssignMorphTargets "<< Assign selected as Targets" enabled:false
            radiobuttons radioAction "" labels:operations default:1 columns:2 across:2 enabled:false
            checkBox chkUsePostFix "Use _<postfix> only" checked:true toolTip:"Use only name text after last underscore" enabled:false
			button btnResetMorpher "Reset Morpher" enabled:false
        )
        
        on pickMorpher picked obj  do 
        (
            if obj != undefined then 
            (
                pickMorpher.text = obj.name
                objWithMorpher = obj
                btnAssignMorphTargets.enabled = radioAction.enabled = chkUsePostFix.enabled = btnResetMorpher.enabled = true
            )
        )
        
        on btnAssignMorphTargets pressed do 
        (
            undo "Assign Morph Targets" on
            (
                if objWithMorpher != undefined then  
                (
                    morpherMod  = objWithMorpher.modifiers[#morpher]
                    if morpherMod != undefined then
                    (                        
                        local usePostfixName = chkUsePostFix.checked 
                        local currentChannel = 1
                        
                        for i=1 to selection.count do 
                        (
                            local obj = selection[i]
                            local targetChannel = i
                            
                            -- Find target channel based on operation
                            if radioAction.state == 2 then ( -- "Add" operation
                                while (WM3_MC_HasData morpherMod currentChannel) and currentChannel <= 100 do
                                    currentChannel += 1
                                targetChannel = currentChannel
                            )
                            
                            -- Assign if within range
                            if targetChannel <= 100 then (
                                WM3_MC_BuildFromNode morpherMod targetChannel obj 
                                
                                if usePostfixName then (
                                    local namesParts = (FilterString obj.name "_")
                                    if namesParts.count > 0 then (
                                        local postfix = namesParts[namesParts.count]
                                        WM3_MC_SetName morpherMod targetChannel postfix
                                    )
                                )
                                
                                -- Prepare for next search if in Add mode
                                if radioAction.state == 2 then currentChannel += 1
                            )
                            else (
                                messageBox "Morpher channel limit reached (100)!" title:"pX Tools"
                                exit
                            )
                        )
                    )
                )                
            )
        )

        on btnResetMorpher pressed do 
        (
            undo "Reset Morpher" on
            (
                if objWithMorpher != undefined then 
                (
                    morpherMod = objWithMorpher.modifiers[#morpher]
                    if morpherMod != undefined then
                    (
                        for i = 1 to 100 do 
                        (
                            WM3_MC_Delete morpherMod i
                        )
                    )
                )
            )
        )
        on roll_Tools open do
        (
            local ini = IniFile()
            ini.filename = getScriptIniFilePath()
            ini.section = "MorphSliders"
            local radioValue = ini.read "radioAction"
            if radioValue != "" then radioAction.state = radioValue as integer
            chkUsePostFix.checked = loadBool ini "chkUsePostFix" true
        )
        on roll_Tools close do
        (
            local ini = IniFile()
            ini.filename = getScriptIniFilePath()
            ini.section = "MorphSliders"
            ini.write "radioAction" (radioAction.state as string)
            saveBool ini "chkUsePostFix" chkUsePostFix.checked
        )
    )

	global morphsliders_floater = newRolloutFloater "pX Quick Morph Sliders" 406 550

    addRollout roll_MorphSliders morphsliders_floater
    addRollout roll_Tools morphsliders_floater
)