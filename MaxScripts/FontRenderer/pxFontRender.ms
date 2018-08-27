utility pxFontRender "pX FontRender 1.0" width:162 height:270
(
	local cameranode = undefined
	local root = undefined
	local bm = undefined
	
	--Filter functions
	function Text_filter obj = ((classof obj.baseObject)==Text)--para el viewPort Activo
	--Conveirte coordenada 3D del World en coordenada 2D del screen del render
	--del viewport actual, Si no es perspective o camera ... cacharro..
	function Point3toScreen Vector =
	(
		thePos = Vector * viewport.getTM()
		screen_origin = mapScreenToView [0,0] (thePos.z) [RenderWidth, RenderHeight]
		end_screen = mapScreenToView [RenderWidth, RenderHeight] (thePos.z) [RenderWidth, RenderHeight]
		world_size = screen_origin-end_screen
		x_aspect = RenderWidth/(abs world_size.x)
		y_aspect = RenderHeight/(abs world_size.y)
		screen_coords = point2 (x_aspect*(thePos.x-screen_origin.x)) (-(y_aspect*(thePos.y-screen_origin.y)))
		Return screen_coords
	) 
	
	--Visual Controls
	GroupBox grp1 "Target" pos:[3,3] width:155 height:86
	pickbutton btnPickObject "Pick Text Shape" pos:[30,24] width:97 height:24 message:"Select Root Object to rotate" filter:Text_filter
	label lblObject "<None>" pos:[32,56] width:52 height:12
	GroupBox grp2 "Render" pos:[4,94] width:154 height:166
	button btnRender "Render" pos:[42,188] width:71 height:30 enabled:false
	
    --functions
	function RenderCurr =
	(
		s = RendOutPutFileName
		if bm != undefined then close bm
		bm = Render OutPutfile:s		
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
		btnRender.Enabled = true
	)
	on btnRender pressed do
	(		
		animButtonState = false
	    nameBak = RendOutPutFileName
		--rotBak = Root.rotation	
		--rotz = eulerAngles 0 0 (360/spnAngCount.value)
		
		--RenderElements
		re = MaxOps.GetCurRenderElementMgr()
		reNames = #()
		reNames.count = re.NumRenderElements()
		for i=0 to reNames.count-1 do reNames[i+1] = re.GetRenderElementFilename i
		
		textfile = createfile ( (GetFilenamePath nameBak) + (GetFileNameFile nameBak) + ".txt" )
		
		format "pivotX pivotY CharWidth\n" to:textfile
				
		for ch=32 to 127 do
		(
			Root.text = bit.IntAsChar ch
			
			RendOutputFileName = (ModifyName nameBak ch)
			for j=0 to reNames.count-1 do re.SetRenderElementFilename j (ModifyName reNames[j+1] ch)
			RenderCurr()			
			pivotPos = Point3toScreen Root.position
			
			format "% % %\n" (pivotPos.x as integer) (pivotpos.y as integer) 0 to:textfile
			
		)
		close textfile
		RendOutPutFileName = nameBak
		--Root.rotation = rotBak
		for i=0 to reNames.count-1 do re.SetRenderElementFilename i reNames[i+1]
	)
)