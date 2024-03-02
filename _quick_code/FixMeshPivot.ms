--Fixing the mesh native origin to be set to origin [0,0,0] while keeping it in place.
--Which is not the 3ds Max pivot
--It moves the Editable_Poly vertices the same value the current pivot has, then move the object position to 0,0,0.
--Results: Mesh looks in the same plase, but its native pivot is now at 0,0,0.

function FixMeshOrigin obj =
(
	if (classof obj)==Editable_Poly then
	(
		local pos = obj.pos
		if (distance pos [0,0,0]) > 0.00001 then
		(
			-- need to support polyOps 
			local numVerts = polyop.getNumVerts obj
			local allVerts = #{1..numVerts}
			polyop.moveVert obj allVerts pos
		)
		obj.pos = [0,0,0]
	) else print "Works only with Editable_poly"
)
FixMeshOrigin $
