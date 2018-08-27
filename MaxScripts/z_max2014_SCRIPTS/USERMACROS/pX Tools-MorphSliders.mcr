macroScript MorphSliders category:"pX Tools" buttonText:"Quick Morph Sliders"
(
	local MorphList = #() --[i][1]= name [1][2] subAnim
	local MixItemUp     = 0
	local MixItemDown = 0
	local MixItemLeft   = 0
	local MixItemRight  = 0
	
	
	rollout roll_MorphSliders "Sliders" width:406 height:388
	(
		button btnCreate "Create simple sliders" pos:[8,301] width:172 height:28
		listbox lbxChannels "Channel List" pos:[7,38] width:176 height:15 
 

		button btnGetMorphs "ADD MORPH CHANNELS" pos:[20,8] width:200 height:25 toolTip:"Get Mopher Channels from seleted object"
		GroupBox grp1 "4 channels Mix Slider" pos:[247,47] width:147 height:211
		button btnSetUp ">  Up" pos:[191,74] width:52 height:24								
								

		button btnSetDown ">  Down" pos:[190,105] width:52 height:24
		button btnSetLeft ">  Left" pos:[189,137] width:52 height:24
		button btnSetRight ">  Right" pos:[189,166] width:52 height:24
		label lblUp "---" pos:[256,78] width:133 height:18
		label lblDown "---" pos:[256,110] width:133 height:18
		label lblLeft "---" pos:[256,141] width:133 height:18
		label lblRight "---" pos:[256,171] width:129 height:18				
				

		button btnRemoveAll "<<" pos:[189,221] width:51 height:24 toolTip:"Remove All"
		button btnCreateMix "Create Slider Mix" pos:[257,215] width:125 height:34
		edittext edtPrefix "Prefix" pos:[204,277] width:95 height:17
		checkbox chkIgnoreWired "Skip wired" pos:[10,277] width:77 height:18 checked:true
		checkbox chkSelectedOnly "Selected Item Only" pos:[11,259] width:120 height:18 checked:false
		button btnUnwire "Restore controllers (Unwire)" pos:[8,332] width:171 height:26 toolTip:"Restore morph channel controllers to Float Blezier without wiring"
		button btnRemoveAllChannels "Remove All" pos:[11,364] width:66 height:19
		button btnRemoveSel "Remove Selected" pos:[83,365] width:95 height:17
		spinner spnSize "Size" pos:[219,304] width:85 height:16 range:[0.1,100,2]
		--progressBar pbar "ProgressBar" pos:[99,280] width:81 height:14
		colorPicker cpSlider "Slider" pos:[317,278] width:54 height:18 color:(color 220 255 100) title:"Choose a color"
		colorPicker cpBase "Base" pos:[322,304] width:52 height:19 color:(color 100 100 200)
		HyperLink linkDenys "by Denys Almaral" pos:[294,361] width:100 height:17 color:(color 0 0 255) hovercolor:(color 0 100 255) address:"http://www.denysalmaral.com" 
 
 
		HyperLink LinkHelp "(?) Help" pos:[344,12] width:43 height:16 color:(color 0 0 255) hovercolor:(color 0 100 255) address:"http://www.denysalmaral.com/2015/03/px-quick-morph-sliders-creation-tool.html"
		
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

		on btnCreate pressed do
		(
				-- Create Simple Sliders
				--settings
				local replaceSliders = true
				local skipWired = false								
				local SliderSize = SpnSize.value
			    local SlidersSDx = 1.0 + SliderSize
				local sliderShapes = true
				
				local prefix = edtPrefix.text
		
				
		
				-- Go for each channel
				
					cCount = 0
						for i=1 to MorphList.count do 			 
						(
							    --pbar.value = i*100/MorphList.count
								cCount = cCount + 1
																
								moName = MorphList[i][1]
							    if (chkIgnoreWired.checked and ((classof MorphList[i][2].controller)==Float_Wire) )  then continue	
								if (chkSelectedOnly.checked and (lbxChannels.selection!=i)) then continue
																	
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
									paramWire.connect subani MorphList[i][2] ("Y_Position*100/"+(SliderSize as string))
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
								
							
						)--for i	
			UpdateListbox()				
			
		)--On button pressed
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
					for i=1 to 100 do
					(						
						if (WM3_MC_HasData mo i) then
						(
							moName = substituteString (WM3_MC_GetName mo i) " " "_"
							append MorphList #(moName, mo[i])														
						)
					)
					
					
					
				)
				UpdateListbox()
				
			)				
		)
		on btnSetUp pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				lblUp.text = MorphList[idx][1]
				MixItemUp = idx
				if lbxChannels.selection<lbxChannels.items.count then lbxChannels.selection = idx+1
			)
		)
		on btnSetDown pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				lblDown.text = MorphList[idx][1]
				MixItemDown = idx
				if lbxChannels.selection<lbxChannels.items.count then lbxChannels.selection = idx+1
			)
		)
		on btnSetLeft pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				lblLeft.text = MorphList[idx][1]
				MixItemLeft = idx
				if lbxChannels.selection<lbxChannels.items.count then lbxChannels.selection = idx+1
			)
		)
		on btnSetRight pressed do
		(
			idx = lbxChannels.selection
			if idx!=undefined then
			(	
				lblRight.text = MorphList[idx][1]
				MixItemRight = idx
				if lbxChannels.selection<lbxChannels.items.count then lbxChannels.selection = idx+1
			)
		)
		on btnRemoveAll pressed do
		(
			lblUp.text = "---"			
			lblDown.text = "---"
			lblLeft.text = "---"
			lblRight.text = "---"
			MixItemDown = 0
			MixItemUp = 0			
			MixItemLeft = 0
			MixItemRight = 0
		)
		on btnCreateMix pressed do
		(
			-- Create a Mixed morphs slider
			
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
					rect.parent = sbase					
					rect.length = SliderSize 
					rect.wireColor = cpBase.color
					rect.pivot.y = -SliderSize/2
					rect.pos.y = 0					
					
					ncY.upper_limit = SliderSize
					moName = moName + "_" + MorphList[MixItemUp][1]
					paramWire.connect subaniY MorphList[MixItemUp][2] ("Y_Position*100/"+(SliderSize as string)+"*(if Y_Position>0 then 1 else 0)")
					paramWire.connect subaniY rect.baseObject[#width] ("Y_Position/2+0.1")	
					sbase.length = SliderSize*2
				)
				if MixItemDown!=0 then
				(		
					rect = rectangle()
					rect.parent = sbase					
					rect.length = SliderSize 
					rect.wireColor = cpBase.color
					rect.pivot.y = -SliderSize/2
					rect.pos.y = 0					
					rotate rect (angleaxis 180 [0,0,1])					
					
					ncY.lower_limit = -SliderSize	
					moName = moName + "_" + MorphList[MixItemDown][1]
					paramWire.connect subaniY MorphList[MixItemDown][2] ("Y_Position*100/-"+(SliderSize as string)+"*(if Y_Position<0 then 1 else 0)")
					paramWire.connect subaniY rect.baseObject[#width] ("Y_Position/-2+0.1")		
					sbase.length = SliderSize*2	
				)
				if MixItemLeft!=0 then
				(
					rect = rectangle()
					rect.parent = sbase					
					rect.length = SliderSize 
					rect.wireColor = cpBase.color
					rect.pivot.y = -SliderSize/2
					rect.pos.y = 0
					rotate rect (angleaxis 90 [0,0,1])					
										
					ncX.lower_limit = -SliderSize
					moName = moName + "_" + MorphList[MixItemLeft][1]
					paramWire.connect subaniX MorphList[MixItemLeft][2] ("X_Position*100/-"+(SliderSize as string)+"*(if X_Position<0 then 1 else 0)")
					paramWire.connect subaniX rect.baseObject[#width] ("X_Position/-2+0.1")		
					sbase.Width = SliderSize*2	
				)
				if MixItemRight!=0 then
				(
					rect = rectangle()
					rect.parent = sbase					
					rect.length = SliderSize 
					rect.wireColor = cpBase.color
					rect.pivot.y = -SliderSize/2
					rect.pos.y = 0
					rotate rect (angleaxis -90 [0,0,1])	
					
					ncX.upper_limit = SliderSize
					moName = moName + "_" + MorphList[MixItemRight][1]
					paramWire.connect subaniX MorphList[MixItemRight][2] ("X_Position*100/"+(SliderSize as string)+"*(if X_Position>0 then 1 else 0)")
					paramWire.connect subaniX rect.baseObject[#width] ("X_Position/2+0.1")	
					sbase.width = SliderSize*2
				)
				
				sbase.pos.x = 0
				sbase.pos.y = 0
				sbase.pos.z = -1-SliderSize				
				rotate sbase (angleaxis 90 [1,0,0])
				UpdateListbox()
			)
		)
		on btnUnwire pressed do
		(
			for i=1 to MorphList.count do 			 
			(				
				if (chkSelectedOnly.checked and (lbxChannels.selection!=i)) then continue
				if  ((classof MorphList[i][2].controller)==Float_Wire)   then MorphList[i][2].controller=Bezier_Float()
			)			
			UpdateListbox()
		)
		on btnRemoveAllChannels pressed do
		(
			MorphList=#()
			UpdateListbox()
		)
		on btnRemoveSel pressed do
		(
			if (LbxChannels.selection!=undefined)  then DeleteItem MorphList LbxChannels.selection
			UpdateListbox()
		)
	)
	
	rf = newRolloutFloater "pX Quick Morph Sliders" 406 420
    addRollout roll_MorphSliders rf	
) 