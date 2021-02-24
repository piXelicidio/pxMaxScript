(
	print "faces"
	print (polyOp.getNumFaces $)
	print (polyOp.getNumMapFaces $ 1)
	print "vertices"
	print (polyOp.getNumVerts $)
	print (polyOp.getNumMapVerts $ 1)
	for i=1 to (polyOp.getNumFaces $) do
	(
		--print "-"
		face = ( polyop.getFaceVerts $ i)		
		mapface = (polyop.getMapFace $ 1 i)
		if face.count == mapface.count then
		(
			print "=="
		)		
	)
)
