-- Texture and UVs merger by Denys Almaral
-- merge objects textures and relocate UVs to the new bigger image
-- Objects need to be clean Editable Poly


(
	local texBigSize = 128
	local texBmp = bitmap texBigSize texBigSize filename:".\\images\\outputTexBig.png" color:gray
	local xCursor = 0
	local yCursor = 0
	local maxHeight = 0
	local texPadd = 2
	
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
	
	for i=1 to $selection.count do
	(
		
		local obj = $selection[i]
		local srcBmp = obj.material.diffuseMap.bitmap		
		if (xCursor + srcBmp.width) > texBigSize then 
		( 
			xCursor = 0
			yCursor = yCursor + maxHeight
			maxHeight = 0
		)
		pasteBitmap srcBmp texBmp [0,0] [xCursor, yCursor]	
		relocateUV obj xCursor yCursor srcBmp
		xCursor = xCursor + srcBmp.width	+ texPadd		
		if srcBmp.height > maxHeight then maxHeight = srcBmp.height
	)
	save texBmp
)

