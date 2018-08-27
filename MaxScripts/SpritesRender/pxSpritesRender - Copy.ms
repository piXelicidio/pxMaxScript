/*
 px SpritesRender
 type: scrited Utility
 author: Denys Almaral (http://www.denysalmaral.com)
 instrunctions: http://www.denysalmaral.com/2012/04/px-spritesrender-3ds-max-scripted.html
 license: FREE
 
 Last update: 2012-04-02
*/
utility pxSpritesRender "pX SpritesRender" width:162 height:394
(
	local cameranode = undefined
	local root = undefined
	local bm = undefined
	
	--Filter functions
	function Camera_filter obj = ((classof obj)==TargetCamera)
	
	--Visual Controls
	GroupBox grp1 "Target" pos:[3,3] width:155 height:140
	pickbutton btnPickObject "Pick Root Object" pos:[22,40] width:97 height:24 message:"Select Root Object to rotate"
	label lblObject "<None>" pos:[7,70] width:139 height:12
	pickbutton btnPickCamera "Pick Camera" pos:[28,92] width:100 height:26 message:"Select camera for render" filter:Camera_filter
	label lblCamera "<None>" pos:[10,121] width:139 height:19
	GroupBox grp2 "Render" pos:[4,146] width:154 height:173
	button btnRender "Render" pos:[45,273] width:71 height:30 enabled:false
	spinner spnAngCount "Angular Views" pos:[29,171] width:106 height:16 range:[1,1000,8] type:#integer scale:1 
	label lbl3 "Renders active segment using current output settings from Render Dialog" pos:[9,218] width:143 height:47
	groupBox grp5 "About" pos:[5,326] width:152 height:61
	label lbl7 "pX SpritesRender 1.0" pos:[24,343] width:109 height:15
	hyperLink linkDenys "Denys Almaral" pos:[37,363] width:78 height:17 color:(color 0 0 255) hoverColor:(color 0 100 255) address:"http://www.denysalmaral.com" 
	hyperLink LinkHelp "(?) Help" pos:[106,13] width:43 height:16 color:(color 0 0 255) hoverColor:(color 0 100 255) address:"http://www.denysalmaral.com/2012/04/px-spritesrender-3ds-max-scripted.html"
	
    --functions
	function RenderCurr =
	(
		local s = RendOutPutFileName
		if bm != undefined then close bm
		bm = Render camera:cameraNode framerange:#active OutPutfile:s quiet:true
	)
	function ModifyName fname idx =
	(
		local ext = (GetFilenameType fname)
		local newName = (GetFilenamePath fname) + (GetFileNameFile fname)
		local num = (idx as string)
		for j=1 to (4-num.count) do num = "0" + num
		newName = newName + "_" + num + "_" + ext		
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
		local rotBak = Root.rotation	
		local rotz = eulerAngles 0 0 (360/spnAngCount.value)
		
		--RenderElements
		local re = MaxOps.GetCurRenderElementMgr()
		local reNames = #()
		reNames.count = re.NumRenderElements()
		
		for i=0 to reNames.count-1 do reNames[i+1] = re.GetRenderElementFilename i
		
		for i=0 to spnAngCount.value-1 do
		(
			RendOutputFileName = (ModifyName nameBak i)
			for j=0 to reNames.count-1 do re.SetRenderElementFilename j (ModifyName reNames[j+1] i)
			RenderCurr()			
			Rotate root rotz
		)
		RendOutPutFileName = nameBak
		Root.rotation = rotBak
		for i=0 to reNames.count-1 do re.SetRenderElementFilename i reNames[i+1]
	)
)
