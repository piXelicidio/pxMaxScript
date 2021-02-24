(
	print "faces"
	print (polyOp.getNumFaces $)
	print (polyOp.getNumMapFaces $ 1)
	print "vertices"
	print (polyOp.getNumVerts $)
	print (polyOp.getNumMapVerts $ 1)
	
	local mapChannel = 1
	
	function prepare_for_polyops obj = 
	(
		local meshFaces = polyop.getNumFaces obj
		local mapFaces = polyop.getNumMapFaces obj mapChannel
		if mapFaces != meshFaces then
		(
			--in case faces difer
			polyop.setNumMapFaces obj mapChannel meshFaces keep:true
			mapFaces = meshFaces
		)
		local mapVerts = polyOp.getNumMapVerts obj mapChannel
		
		-- rebuild map verts for our convenience, one unique vert for each face, each face vert point to that vert
		-- keep one old vert
		local vertsCopy = #()
		vertsCopy.count = mapFaces
		local mapFaceSizes = #()
		for i = 1 to mapFaces do 
		(
			local mapFace = polyop.getMapFace obj mapChannel i
			mapFaceSizes[i] = mapFace.count
			vertsCopy[i] = polyop.getMapVert obj mapChannel mapFace[1]
		)
		polyop.setNumMapVerts obj mapChannel mapFaces keep:true
		for i = 1 to mapFaces do
		(
			polyop.setMapVert obj mapChannel i vertsCopy[i]
			local newFace = #()
			newFace.count = mapFaceSizes[i]
			for j = 1 to newFace.count do
			(
				newFace[j] = i
			)
			polyop.setMapFace obj mapChannel i newFace
		)
		update obj
	)
	prepare_for_polyops $
)
