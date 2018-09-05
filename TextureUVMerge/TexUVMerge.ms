-- Texture and UVs merger by Denys Almaral
-- merge objects textures and relocate UVs to the new bigger image
-- Objects need to be collapsed Editable Poly


(
	--settings
	local texBigSize = 300
	local texBmp = bitmap texBigSize texBigSize filename:"c:\\temp\\outputTexBig.png" color:gray
	local padding = 2
	local rescaling =1
	--vars
	local xCursor = 0
	local yCursor = 0
	local maxHeight = 0	
	yCursor = yCursor + padding
	
	function relocateUV obj xc yc srcBitmap =
	(
		-- oldUV tranformTo newUV
		local numMapVerts = polyOp.getNumMapVerts obj 1
		for i = 1 to numMapVerts do
		(
			local oldUV = polyOp.getMapVert obj 1 i
			local newUV = [0,0,0]
			newUV.x = ( oldUV.x * (srcBitmap.width) + (xc) ) / texBmp.width
			newUV.y = ((1-oldUV.y) * (srcBitmap.height) + (yc) ) 
			newUV.y = 1 - ( newUV.y / (texBmp.height) )
			polyOp.setMapVert obj 1 i newUV
		)
		update obj
	)
	
	function pasteTexture srcBitmap x y =
	(
		pasteBitmap srcBitmap texBmp [0,0] [x,y]
		if padding > 0 then
		(
			for step=1 to padding do
			(
				-- spread border color
				--top
				local pixels = getPixels srcBitmap [0,0]  srcBitmap.width linear:true
				setPixels texBmp [x,y-step] pixels
				--bottom
				pixels = getPixels srcBitmap [0,srcBitmap.height-1]  srcBitmap.width linear:true
				setPixels texBmp [x,y+srcBitmap.height+(step-1)] pixels
				
	
			)
			for step=1 to padding do
			(
				-- left and right
				for yy = (y-padding) to (y + srcBitmap.height+padding) do
				(
					local pixels = getPixels texBmp [x, yy] 1 linear:true
					setPixels texBmp [x-step, yy] pixels
					pixels = getPixels texBmp [x+srcBitmap.width-1,yy] 1 linear:true
					setPixels texBmp [x+srcBitmap.width+step-1, yy] pixels
				)
			)
		)
	)
	
	for i=1 to $selection.count do
	(
		
		local obj = $selection[i]		
		if (classof obj)!=Editable_poly then continue		
		if obj.material == undefined then continue
	    if obj.material.diffuseMap == undefined then continue
		local srcBmp = obj.material.diffuseMap.bitmap
		if srcBmp==undefined then continue
		
		--rescaling
		if rescaling != 1 then
		(
			local tempBmp = bitmap (srcBmp.width*rescaling) (srcBmp.height*rescaling)
			copy srcBmp tempBmp
			srcBmp = tempBmp
		)
		
		xCursor = xCursor + padding
		if (xCursor + srcBmp.width) > texBigSize then 
		( 
			xCursor = padding
			yCursor = yCursor + maxHeight + padding*2
			maxHeight = 0
		)
		pasteTexture srcBmp xCursor yCursor	
		-----------------
		relocateUV obj xCursor yCursor srcBmp
		-----------------
		xCursor = xCursor + srcBmp.width	+ padding
		if srcBmp.height > maxHeight then maxHeight = srcBmp.height
	)
	save texBmp
	display TexBmp
)

