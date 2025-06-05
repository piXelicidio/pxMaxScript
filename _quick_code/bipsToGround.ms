/*
bipsToGround Function
Aligns one or multiple biped characters to a specified ground height (default 0) by adjusting their root node position.
- Scans all biped nodes to find the lowest Z bound (foot contact).
- Shifts the biped root so the lowest point aligns to the given `ground` level.
*/

function bipsToGround selbips ground =
(
	if ground == undefined then ground = 0
	if (classof selbips==ObjectSet) then
	(	
		selbips = selbips as array
	) else
	(
		selbips = #(selbips)
	)
	
	for bip in selbips do 		
	(
		local maxnodes = biped.maxNumNodes bip
		local worldM = matrix3 1
		local minz = ground + 10000
		for i=1 to maxnodes do
		(
			for j=1 to 3 do 
			(
				obj = biped.getNode bip i link:j
				if obj != undefined then
				(
					bounds = nodeGetBoundingBox obj worldM
					if bounds[1].z < minz then minz = bounds[1].z
				)
			)
		)
		--print minz
		local rn = bip.controller.rootNode
		local rnPos = biped.getTransform rn #pos
		rnPos.z = rnPos.z + ground - minz 
		biped.setTransform rn #pos rnPos false
	)
)
bipsToGround $Selection 0