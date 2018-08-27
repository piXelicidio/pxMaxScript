--Morph sliders by Denys Almaral

-- Searshing the first morpher modifier


if $!=undefined then
(
	--settings
	replaceSliders = false
	skipWired = true
	SlidersDx = 0.3
	SlidersDy = 0.1
	SlidersSDx = 2
	sliderShapes = true
	local SlidersColCount =8
	local prefix = "blond_"

	mo = undefined
	for i=1 to $.modifiers.count do
	(
			if (classof $.modifiers[i])==Morpher then
			(
				mo = $.modifiers[i]
				break
			)
	)

	-- Go for each channel
	if mo!=undefined then
	(
		cCount = 0
			for i=1 to 100 do 			 
			(
				if (WM3_MC_HasData mo i) then
				(
										
					cCount = cCount + 1
					
					if ( skipWired and ((classof mo[i].controller)==Float_Wire) )  then continue
					
					moName = substituteString (WM3_MC_GetName mo i) " " "_"
					if SliderShapes then
					(
						
						--SliderShapes 
						sbase = rectangle()
						sbase.width = 0.4
						sbase.length = 2.5
						sbase.wireColor = [100,100,200]
						sbase.pivot.y = -1
						s = donut()
						s.radius1 = 0.1
						s.radius2 = 0.5
						s.wireColor = [200, 255, 0]
						s.parent = sbase
						setTransformLockFlags s (#{1..9}-#{2})
						subani = s[#transform][#position][#Y_position]
						nc = Float_Limit()
						nc.lower_limit = 0
						nc.upper_limit = 2
						subani.controller = nc
						
						sbase.pos.x = 0.1 + cCount*SlidersSDx	
						sbase.pos.y = 0
						sbase.pos.z = -3
						
						rotate sbase (angleaxis 90 [1,0,0])
						-- Parameters wiring
						paramWire.connect subani mo[i] "Y_Position*50"
						paramWire.connect subani s.baseObject[#radius_1] "Y_Position/6.66+0.1"
						--deleting olds, setNames
						newName = prefix+"Sliderb_" + moName					
						existObj =  Execute ("$"+newName)
						if (existObj!=undefined) and replaceSliders then delete existObj
						sbase.Name = newName
						newName = prefix+"Slider_" + moName					
						existObj =  Execute ("$"+newName)
						if (existObj!=undefined) and replaceSliders then delete existObj
						s.Name = newName
					)
					else
					(
						-- SliderManipulators		
						
						sm = SliderManipulator()
						sm.xPos = 0.05 + ((cCount-1) / SlidersColCount)*SlidersDx
						sm.yPos = 0.1 + (Mod (cCount-1) SlidersColCount)*SlidersDy 					
						newName = prefix+"Slider_" + moName					
						existObj =  Execute ("$"+newName)
						if (existObj!=undefined) and replaceSliders then delete existObj
						sm.Name = newName
						sm.sldName = moName
						-- Parameters wiring
						paramWire.connect sm.baseObject[#value] mo[i] "Value"
					)
					
				)
			)
	)
)