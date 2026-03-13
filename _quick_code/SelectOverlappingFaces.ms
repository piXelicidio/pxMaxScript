--This in fact select polygons where all its vertices are overlapping vertices.
-- NOT the same as overlaping faces.

function findOverlappingVertPolygons obj threshold:0.001 =
(
    local poly = obj.baseObject
	modPanel.setCurrentObject $.baseObject
	
    if classof poly != Editable_Poly then
    (
        messageBox "Object is not an Editable_Poly!"
        return false
    )

    local numVerts = polyOp.getNumVerts poly
    local numFaces = polyOp.getNumFaces poly

    -- Collect all vertex positions
    local vertPositions = #()
    for i = 1 to numVerts do
        append vertPositions (polyOp.getVert poly i)

    -- Find overlapping vertices
    local overlappingVerts = #{}

    for i = 1 to numVerts do
    (
        for j = (i + 1) to numVerts do
        (
            if (distance vertPositions[i] vertPositions[j]) <= threshold then
            (
                overlappingVerts[i] = true
                overlappingVerts[j] = true
            )
        )
    )

    -- Find polygons where ALL vertices belong to the overlapping set
    local selectedFaces = #{}

    for f = 1 to numFaces do
    (
        local faceVerts = polyOp.getFaceVerts poly f
		if faceVerts!=undefined then
		(
			local allOverlapping = true
			for v in faceVerts do
			(
				if not overlappingVerts[v] then
				(
					allOverlapping = false
					exit
				)
			)
			if allOverlapping then selectedFaces[f] = true
		)
    )

    -- Apply selection and switch to polygon sub-object level
    polyOp.setFaceSelection poly selectedFaces
    subobjectLevel = 4
    redrawViews()

    format "Overlapping vertices found: %\n" overlappingVerts.numberSet
    format "Polygons selected:          %\n" selectedFaces.numberSet
)

findOverlappingVertPolygons $ threshold:0.001