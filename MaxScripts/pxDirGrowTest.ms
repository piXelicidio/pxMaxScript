--- Dado el FACEx seleccionado del polypoly
--//Encontrar todos los FACE pegados por un Edge
--  - Coger todos los Edges[] que usan ese FACEx
--  - Ir por cada Edge[i] y buscar los FACES[] usando ese EDGE, descartar FACEx
--//AGREGAR A SELECCIÓN SI CUMPLEN CONDICIÓN 
--  - Ir por cada FACES[i] y ver si su sentro está UP/DOWN/LEFT/RIGHT y añadir a selección
--
--Listo.

polypoly = $
FacesX = polyOp.GetFaceSelection polypoly
AddFaces = #{}
for i in FacesX do
(
	EdgesX = polyOp.GetFaceEdges polypoly i
	NewFaces = polyOp.getFacesUsingEdge polypoly EdgesX
	NewFaces = NewFaces - FacesX
	print newFaces
	for j in newFaces do
	(
		FaceXcenter = polyOp.getFaceCenter polypoly i
		deltaCenter = polyOp.getFaceCenter polypoly j   --to new face center
		deltaCenter = deltaCenter - FaceXcenter
		--UP
		if (	((abs deltaCenter.z)>(abs deltaCenter.x)) and (deltaCenter.z>0) ) then
		(
			append AddFaces j
		)
	)
)
FacesX = FacesX + AddFaces
polyOp.SetFaceSelection polypoly FacesX
redrawViews()v