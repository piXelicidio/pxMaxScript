 (


	local bary = [0,0,0]
	local faceIndex = 1
	local theObj = undefined
	local bmpSize = 360
	local curr_UV = [0,0,0]
	 
	local tempBitmap = bitmap bmpSize bmpSize
	
	rollout roll_polyPaint "Poly Paint" 
	(
		bitmap bmpColorPal bitmap:tempBitmap pos:[0,0]
		checkButton paint3D "Start Paint Tool" pos:[18, bmpSize + 10 ] width:126 height:55		
		
		
	   	 on roll_polyPaint lbuttondown pos do
		(
			if (pos.y <= bmpSize) then
			(
				curr_UV.x =  pos.x / bmpSize
				curr_UV.y = 1 - ( pos.y / bmpSize )
			)			
		)
		
		function updateColorBitmap = 
		(
			copy $.material.diffuseMap.bitmap tempBitmap
			bmpColorPal.bitmap = tempBitmap
		)
		
		function startStroke = ( thePainterInterface.undoStart() )
		
		fn getPolyFaceByTri node tri =
		(
			local index = 1
			local poly = 0
			local getFaceDeg = polyop.getFaceDeg
			for k = 1 to polyop.getNumFaces node while poly == 0 do
			(
				index += getFaceDeg node k - 2
				if (tri < index) do poly = k
			)
			poly
		)
		
		function paintStroke = 
		(			
			thePainterInterface.getHitFaceData &bary &faceIndex theObj 0						
			print faceIndex
            faceIndex = (getPolyfaceByTri theObj faceIndex)
			print faceIndex
			local vnum = (polyop.getMapFace theObj 1 faceIndex).count
			for i=1 to vnum do
			(
				theObj.Unwrap_UVW.setFaceVertex [ curr_UV.x, curr_UV.y,0] faceIndex i false
			)
			update theObj
			thePainterInterface.clearStroke()
		)
		
		function endStroke = ( thePainterInterface.undoAccept())
		function cancelStroke = ( thePainterInterface.undoCancel())
		function systemEndPaintSession = ( paint3d.checked = false)
		
		function startPainting3D =
		(
			if  thePainterInterface.InPaintMode() or theObj == undefined then 
			(
				thePainterInterface.endPaintSession()
				paint3D.checked = false
			) else
			(
				paint3D.checked = true
				thePainterInterface.pointGatherEnable = true
				thepainterInterface.initializeNodes 0 # (theObj)
				thePainterInterface.offMeshHitType = 2
				thePainterInterface.scriptFunctions startStroke paintStroke endStroke cancelStroke SystemEndPaintSession
				thePainterInterface.startPaintSession()
			)			
		)
		
		on paint3D changed state do 
		( 
			theObj = $
			updateColorBitmap()
			startPainting3D() 
		)
		
	)

	--// has to be with CreateDialog in order to get the lButtonDown event with mouse position
	createdialog roll_PolyPaint bmpSize (bmpSize + 150 )
	
)