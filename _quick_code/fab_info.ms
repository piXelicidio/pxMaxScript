--technical info for FAB store
function getInfo objs =
(
	if objs==undefined then objs = objects
	ePolys = 0
	eMesh = 0
	totalTriangles = 0
	minTriangles = 100000000
	maxTriangles = 0
	finalTriangles = 0
	minFinalTriangles = 1000000
	maxFinalTriangles = 0
	totalQuads = 0
	minQuads = 1000000
	maxQuads = 0
	totalNGons = 0
	minNGons = 1000000
	maxNGons = 0
	maxNGonsCriminal = ""
	minVerts = 1000000
	maxVerts = 0
	for obj in objs do
	(
		if (classof obj)==Editable_poly then 
		( 
			ePolys = ePolys + 1
			numf = polyOp.getNumFaces obj
			numv = polyOp.getNumVerts obj
			triangles = 0
			quads = 0
			ftriangles = 0
			nGons = 0
			for i=1 to numf do
			(
				sides = polyOp.getFaceDeg obj i
				if sides != undefined then
				(						
					if sides == 3 then triangles += 1
					if sides == 4 then quads += 1
					if sides > 4 then nGons += 1
					ftriangles += (sides - 2)
				)
			)
			totalTriangles += triangles
			finalTriangles += ftriangles
			totalQuads += quads
			totalNGons += nGons
			if triangles <  minTriangles then minTriangles = triangles
			if triangles >  maxTriangles then maxTriangles = triangles
			if ftriangles < minFinalTriangles then minFinalTriangles = ftriangles
			if ftriangles > maxFinalTriangles then maxFinalTriangles = ftriangles
			if quads < minQuads then minQuads = quads
			if quads > maxQuads then maxQuads = quads
			if numv < minVerts then minVerts = numv
			if numv > maxVerts then maxVerts = numv
			if nGons < minNGons then minNGons = nGons
			if nGons > maxNGons then 
			(
				maxNGons = nGons
				maxNGonsCriminal = obj.name
			)
		)
		if (classof obj)==Editable_mesh then eMesh = eMesh + 1
	)
	format "num ePOlys: %\n" ePolys
	format "num eMeshes: %\n" eMesh
	
	format "triangles MIN: % MAX: % \n"  minTriangles maxTriangles
	format "quads  MIN: % MAX: % \n" minQuads maxQuads totalQuads
	format "finalTris MIN: % MAX: % \n"  minFinalTriangles maxFinalTriangles
	format "NGons MIN: % MAX: % NGonsCriminal:% \n" minNGons maxNGons maxNGonsCriminal
	format "verts MIN: % MAX: % \n" minVerts maxVerts	
	format "\n"
	format "NGons %\n" totalNGOns
	format "average triangles % (total %)\n " (totalTriangles /  ePolys)  totalTriangles
	format "average quads %  (total %)\n" (totalQuads / ePolys ) totalQuads
	format "average finalTris %  (total %)\n" (finalTriangles / ePolys ) finalTriangles
	
)
clearListener()
getInfo $
