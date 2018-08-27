-- Poly  Paint, a tool to paint polygos with a flat color from texture, setting all vertices of a UV face to a single point in texture, giving always a flat color
-- By Denys Almaral - 2018
-- Updates
--  2018-08-25 v1.0 basic functionality 
(


	local bary = [0,0,0]
	local faceIndex = 1
	local lastTriFace = -1
	local theObj = undefined
	local bmpSize = 360
	local curr_UV = [0,0,0]
	local thePI = thePainterInterface
	 
	local tempBitmap = bitmap bmpSize bmpSize
	
	rollout roll_polyPaint "Poly Paint" 
	(
		bitmap bmpColorPal bitmap:tempBitmap pos:[0,0]
		checkButton paint3D "Start Paint Tool" pos:[18, bmpSize + 10 ] width:126 height:55		
		
		
		function updateColorBitmap = 
		(
			copy $.material.diffuseMap.bitmap tempBitmap
			bmpColorPal.bitmap = tempBitmap
		)
		
		function startStroke = ( thePI.undoStart() )
		
		fn getPolyFaceByTri node tri =
		(
			-- convert a mesh Face Index to a editable_poly poly index
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
			-- The main thing accours here -------------------------- ******************************
			thePI.getHitFaceData &bary &faceIndex theObj 0	
			
			if (aceIndex != lastTriFace) and (bary != [0,0,0]) then
			--do not repeat stuff if we are still in the same face
			-- bary != [0,0,0] dirty trick to detect ourside of node strokes
			(				
				local PolyIndex = (getPolyfaceByTri theObj faceIndex)								
				print PolyIndex
				print bary				
				local vnum = (polyop.getMapFace theObj 1 PolyIndex).count
				for i=1 to vnum do
				(
					theObj.Unwrap_UVW.setFaceVertex [ curr_UV.x, curr_UV.y,0] PolyIndex i false
				)
				update theObj
				thePI.clearStroke()
			)
			lastTriFace = faceIndex				
		)
		
		function endStroke = ( 
			thePI.undoAccept()
			lastTriFace = -1
			print "endStroke"
			)
		function cancelStroke = ( 
			thePI.undoCancel()
			lastTriFace = -1
			)
		function systemEndPaintSession = ( 
			paint3d.checked = false
			lastTriFace = -1
			print "paint end"
			)
		
		function startPainting3D =
		(
			if  thePI.InPaintMode() or theObj == undefined then 
			(
				thePI.endPaintSession()
				paint3D.checked = false
			) else
			(
				paint3D.checked = true
				thePI.pointGatherEnable = false
				thePI.initializeNodes 0 # (theObj)
				thePI.offMeshHitType =2
				thePI.minSize = 0.1
		        thePI.maxSize = 2
				thePI.drawring = true
				thePI.drawTrace = false
				thePI.drawNormal = true
				thePI.normalScale = 5
				thePI.pressureEnable = false
				thePI.scriptFunctions startStroke paintStroke endStroke cancelStroke SystemEndPaintSession
				thePI.startPaintSession()
			)			
		)
		
		function endPainting3D =
		(
			thePI.endPaintSession()
			paint3D.checked = false
		)
		
		-- EVENTS HANDLERS ***************************************
		
		on paint3D changed state do 
		( 
			if paint3D.checked = true then
			(
				theObj = $
				updateColorBitmap()
				startPainting3D() 
			) else
			(
				endPainting3D()
			)
		)
		
		on roll_polyPaint lbuttondown pos do
		(
			if (pos.y <= bmpSize) then
			(
			   --	get the position of mouse clicks over the window and convert it to UV coordinates.
				curr_UV.x =  pos.x / bmpSize
				curr_UV.y = 1 - ( pos.y / bmpSize )
			)			
		)
		
		on roll_polyPaint close do
		(
				endPainting3D()
		)
		
	)

	--// has to be with CreateDialog in order to get the lButtonDown event with mouse position
	createdialog roll_PolyPaint bmpSize (bmpSize + 150 )
	
)