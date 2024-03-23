struct TVertInfo  ( RightSide, LinkedTo, PairedWith, vPos )
VertsInfo = #()

function GetVertsConnected EP vertIdx =
(
	edges = polyop.getEdgesUsingVert EP vertIdx
	verts = polyop.getVertsUsingEdge EP edges
	--return
	(verts - #{vertIdx})
)

function FindPairs ePoly =
(
	--settings
	usingDllManager = true	
	--vertices
	if (classOf ePoly) != Editable_poly then return undefined;
	numVerts = polyop.getNumVerts ePoly
	in coordsys local (
		allVerts = polyop.getVerts ePoly #{1..(numVerts)}	
	)
	print allVerts.count
	
	--conections
	vertConnections = #()
	vertConnections.count = numVerts
	for i = 1 to numVerts do
	(
		vertConnections[i] = (GetVertsConnected ePoly i) as array
	)
	
	TArrayArrayFloat = dotNetClass "System.single[][]"
	TArrayArrayInt = dotNetClass "System.int32[][]"
	csVerts = dotnet.valueToDotNetObject allVerts TArrayArrayFloat
	csVertConnections = dotnet.valueToDotNetObject vertConnections TArrayArrayInt
	
	--.net calls	
	if usingDllManager then
	(
		result = dllManager.callMethod "Symmetry.Functions.FindPairs" args:#(csVerts, csVertConnections)
	)	

	VertsInfo.count = numVerts;
	rightSide = result.rightSide
	pairedWith = result.pairedWith
	for i=1 to numVerts do 
	(
		vi = TVertInfo()
		vi.RightSide = rightSide[i]
		pw = pairedWith[i]+1
		if pw==0 then pw = undefined;
		vi.PairedWith = pw
		vi.vPos = allVerts[i]
		vi.LinkedTo = vertConnections[i]
		VertsInfo[i] = vi
	)
	
	--return
	(result)
)
ClearListener()
res = FindPairs $