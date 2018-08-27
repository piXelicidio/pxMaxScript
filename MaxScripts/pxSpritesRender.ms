utility pxSpritesRender "pX SpritesRender" width:162 height:331
(
	local cameranode = undefined
	local root = undefined
	local bm = undefined
	
	--Filter functions
	function Camera_filter obj = ((classof obj)==TargetCamera)
	
	--Visual Controls
	GroupBox grp1 "Target" pos:[3,3] width:155 height:140
	pickbutton btnPickObject "Pick Root Object" pos:[30,24] width:97 height:24 message:"Select Root Object to rotate"
	label lblObject "<None>" pos:[32,56] width:52 height:12
	pickbutton btnPickCamera "Pick Camera" pos:[29,85] width:100 height:26 message:"Select camera for render" filter:Camera_filter
	label lblCamera "<None>" pos:[32,115] width:52 height:19
	GroupBox grp2 "Render" pos:[4,146] width:154 height:173
	button btnRender "Render" pos:[45,273] width:71 height:30 enabled:false
	spinner spnAngCount "Angular Views" pos:[29,171] width:106 height:16 range:[1,1000,8] type:#integer scale:1 
	label lbl3 "Renders active segment using current output settings from Render Dialog" pos:[9,218] width:143 height:47
	
    --functions
	function RenderCurr =
	(
		s = RendOutPutFileName
		if bm != undefined then close bm
		bm = Render camera:cameraNode framerange:#active OutPutfile:s
	)
	function ModifyName fname idx =
	(
		ext = (GetFilenameType fname)
		newName = (GetFilenamePath fname) + (GetFileNameFile fname)
		num = (idx as string)
		for j=1 to (4-num.count) do num = "0" + num
		newName = newName + "_" + num + "_" + ext
		return newName
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
	    nameBak = RendOutPutFileName
		rotBak = Root.rotation	
		rotz = eulerAngles 0 0 (360/spnAngCount.value)
		
		--RenderElements
		re = MaxOps.GetCurRenderElementMgr()
		reNames = #()
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