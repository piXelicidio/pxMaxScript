fn SpreadSelection = 
(
	local sel = (polyOp.getFaceSelection $) as array
	local verts = #{}
	for i = 1 to sel.count do
	(
		verts = verts + polyOp.getVertsUsingFace $ sel[i]
	)
	 local faces = polyOp.getFacesUsingVert $  verts
	polyOp.setFaceSelection $ faces 
	update $
)

spreadSelection()