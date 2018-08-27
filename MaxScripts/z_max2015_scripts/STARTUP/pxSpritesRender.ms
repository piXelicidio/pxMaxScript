/*
 px SpritesRender
 type: scrited Utility
 author: Denys Almaral (http://www.denysalmaral.com)
 instrunctions: http://www.denysalmaral.com/2012/04/px-spritesrender-3ds-max-scripted.html
 license: FREE
 
Update: 2017-09-09
- Accept any type of cameras
 Update: 2017-02-20
 - Building Sprites Sheet single image.
 Created: 2012-04-02
*/
utility pxSpritesRender "pX SpritesRender" width:162 height:400
(
	local cameranode = undefined
	local root = undefined
	local bm = undefined
	
	--Filter functions
	function Camera_filter obj = (isKindOf obj camera)
	
	--Visual Controls
	GroupBox grp1 "Target" pos:[3,3] width:155 height:140
	pickbutton btnPickObject "Pick Root Object" pos:[22,40] width:97 height:24 message:"Select Root Object to rotate"
	label lblObject "<None>" pos:[7,70] width:139 height:12
	pickbutton btnPickCamera "Pick Camera" pos:[28,92] width:100 height:26 message:"Select camera for render" filter:Camera_filter
	label lblCamera "<None>" pos:[10,121] width:139 height:19
	GroupBox grp2 "Render" pos:[4,146] width:154 height:189
	button btnRender "Render" pos:[25,256] width:104 height:30 enabled:false
	spinner spnAngCount "Angular Views" pos:[29,171] width:106 height:16 range:[1,1000,8] type:#integer scale:1 
 
 
 
	label lbl3 "Renders active segment using current output settings from Render Dialog" pos:[9,289] width:143 height:41
	GroupBox grp5 "About" pos:[7,339] width:152 height:56
	label lbl7 "pX SpritesRender 1.0" pos:[24,355] width:109 height:15
	HyperLink linkDenys "Denys Almaral" pos:[37,371] width:78 height:17 color:(color 0 0 255) hovercolor:(color 0 100 255) address:"http://www.denysalmaral.com" 
 
 
 
	HyperLink LinkHelp "(?) Help" pos:[106,13] width:43 height:16 color:(color 0 0 255) hovercolor:(color 0 100 255) address:"http://www.denysalmaral.com/2012/04/px-spritesrender-3ds-max-scripted.html"
	checkbox chkBuildSheet "Build Sprite Sheet" pos:[19,200] width:121 height:20 checked:true
	
    --functions
	function RenderCurr =
	(
		--this render all the segment and save it 
		local s = RendOutPutFileName
		if bm != undefined then close bm
		bm = Render camera:cameraNode framerange:#active OutPutfile:s quiet:true
	)
	
	function RenderFrame fidx=
	(
		--this render a single frame on memory		
		
		if cameraNode!=undefined then	
		(	
			bm = Render OutPutfile:RendOutPutFileName camera:cameraNode frame:fidx  quiet:true vfb:true pos:#vfb_upper_left
		) else
		(
			bm = Render OutPutfile:RendOutPutFileName frame:fidx quiet:true 
		)
		unDisplay bm
		Result = bm		
	)
	
	function ModifyName fname idx idx2: =
	(
		local ext = (GetFilenameType fname)
		local newName = (GetFilenamePath fname) + "separated/" + (GetFileNameFile fname)
		local num = (idx as string)
		for j=1 to (4-num.count) do num = "0" + num
		if idx2!=unsupplied then
		(
			local num2 =(idx2 as string)
			for j=1 to (4-num2.count) do num2 = "0" + num2
			newName = newName + "_" + num + "_" +num2+ ext		
		) else
		(		
			newName = newName + "_" + num + "_" + ext		
		)
		print newName
		Result = newName
	)
	
	--events

	on btnPickObject picked obj do
	(
		lblObject.Caption = obj.name
		root = obj
		if cameranode != undefined then btnRender.Enabled = true
	)
	on btnPickCamera picked obj do
	(
		lblCamera.Caption = obj.name
		cameranode = obj
		if root != undefined then btnRender.Enabled = true
	)
	on btnRender pressed do
	(		
		animButtonState = false
	    local nameBak = RendOutPutFileName		
		makedir ((GetFilenamePath nameBak)+"/separated")
		local rotBak = Root.rotation	
		local rotz = eulerAngles 0 0 (360/spnAngCount.value)
		
		local SpriteSheet=undefined --bitmap
		local reSheets=#() --RenderElements sprite sheet
		
		--RenderElements
		local re = MaxOps.GetCurRenderElementMgr()
		local reNames = #()		
		
		reNames.count = re.NumRenderElements()
		
		for i=0 to reNames.count-1 do 
		(
			reNames[i+1] = re.GetRenderElementFilename i
			
		)
		
		-- old loop
		--for i=0 to spnAngCount.value-1 do
		--(
		--	RendOutputFileName = (ModifyName nameBak i)
		--	for j=0 to reNames.count-1 do re.SetRenderElementFilename j (ModifyName reNames[j+1] i)
		--	RenderCurr()			
		--	Rotate root rotz
		--) 
		for i=0 to spnAngCount.value-1 do
		(				
			for thisframe=(animationRange.start.frame as integer) to (animationRange.end.frame as integer) do
			(
				--render elements thing
				for rn=1 to reNames.count do 
				(
					re.SetRenderElementFilename (rn-1) (ModifyName reNames[rn] i idx2:thisframe)					
				)
				
				--render a frame
				RendOutPutFileName = ModifyName nameBak i  idx2:thisframe					
				local newBmp = RenderFrame thisframe
				--TODO: create subfolder for frames  function: makeDir
												
				--if chkSaveFrames.checked then save newBmp
				
				if chkBuildSheet.checked then 
				(
					if ((i==0) and (thisframe==0)) then
					( 
						-- First sprite ever! lets build the sheet out of it
						bigHeight = spnAngCount.value * newBmp.Height
						bigWidth = newBmp.Width * ((animationRange.end.frame as integer)+1)
						
						--saving info to file
						textfile = createFile (nameBak+".txt")
						format "SheetWidth = %\n" bigWidth to:textfile
						format "SheetHeight = %\n" bigHeight to:textfile	
						format "SpriteWidth = %\n" newBmp.width to:textfile			
						format "SpriteHeight = %\n" newBmp.height to:textfile			
						format "AnimationFrames = %\n"  ((animationRange.end.frame as integer)-(animationRange.start.frame as integer) +1)  to:textfile	
						format "AngularViews = %\n"  spnAngCount.value to:textfile
						close textfile	
							
						SpriteSheet = bitmap bigWidth bigHeight
						SpriteSheet.filename = nameBak		
	
						--RenderElements sheet
						for rn=1 to reNames.count do
						(
							reSheets[rn] = bitmap bigWidth bigHeight
							reSheets[rn].filename = reNames[rn]
						)
					)
					
					if SpriteSheet!=undefined then
					(
						-- Joining the images
						pasteBitmap newBmp SpriteSheet [0,0] [ thisFrame*newBmp.Width , i * newBmp.Height]
					)
					
					for rn=1 to reNames.count do
					(
						--joining images for renderElements
						if reSheets[rn]!=undefined then
						(
							--get bitmap from file
							local elementBmp = OpenBitmap (re.GetRenderElementFilename (rn-1))
						
							pasteBitmap elementBmp reSheets[rn] [0,0] [ thisFrame*elementBmp.Width , i * elementBmp.Height ]
						)
					)
				)
			)
			Rotate root rotz
		)		
		if chkBuildSheet.checked then
		(
			if SpriteSheet!=undefined then
			(
				save SpriteSheet
				close SpriteSheet
			)
			for rn=1 to reNames.count do
			(
				--saving
				if reSheets[rn]!=undefined then 
				(
					save reSheets[rn]	
					close reSheets[rn]
				)					
			)
		)
		RendOutPutFileName = nameBak
		Root.rotation = rotBak
		for i=0 to reNames.count-1 do re.SetRenderElementFilename i reNames[i+1]
	)
)
