--denysalmaral.com
-- Zoom Extents selected with active camera, or does default Zoom extents selected if the active viewport is not a camera.
-- When Zoom extending with Camera, it only takes into account GeometryClass objects. Ignore anything else, like other cameras and lights.
-- Keeps the FOV and rotation, only moves camera position in space to fit them all.

macroScript camZoomExtents category:"pX Tools"
(
	--INTERCEPT SEGMENTS translated from my old delphi code ;)
	/* {
	  Intercept 2 segments
	  segm1: points from a1 to a2
	  segm2: points from b1 to b2
	 result poin3 
	  return undefined if cannot intercept
	} */
	
	-------------------------------------------------------------------FUNCTIONS-------------------------------------------
	function intercept  a1 a2 b1 b2  =
	( 
		local m1 = 0.0
		local m2 = 0.0
		local n1 = 0.0
		local n2 = 0.0  
		local X = 0.0
		local Y = 0.0
		local indef_m1 = false
		local indef_m2 = false
		
		local Result = undefined   	
		if (a2.x - a1.x) != 0 then
		(
			m1 = (a2.y - a1.y) / (a2.x - a1.x)
			n1 = a1.y - m1 * a1.x;
		) else 
		(
			X = a2.x;
			indef_m1 = true;
		)

		indef_m2 = false;
		if (b2.x - b1.x) != 0 then
		(
			m2 = (b2.y - b1.y) / (b2.x - b1.x);
			n2 = b1.y - m2 * b1.x;
		) else (
			X=b2.x;
			indef_m2 = true
		)

		if (not indef_m1) and (not indef_m2) then
		(
			if (m1 == m2) then 
			( 
				return undefined
			)--'parallel 
			else
			(
				X = (n2 - n1) / (m1 - m2);
			)
		) else if (indef_m1 and indef_m2) then return undefined --parallel


		if not indef_m1 then
		(
			Y = m1 * X + n1;
		) else
		(
			Y = m2 * X + n2;
		);
		Result= [ X, Y, 0]
		--return
		(Result)
	)

	function sceneBoundingVerts objList aclass mat =
	(
		local all_verts = #()
		local count = 0
		if mat == undefined then mat = matrix3 1
		for obj in objList do
		(
			if (isKindOf obj aclass)  or (aclass == undefined) then
			(
				bb = nodeGetBoundingBox obj mat			
				count = count + 8
				all_verts[count] = bb[1]
				all_verts[count-1] = bb[2]
				all_verts[count-2] = [bb[1].x, bb[1].y, bb[2].z] 
				all_verts[count-3] = [bb[1].x, bb[2].y, bb[1].z]
				all_verts[count-4] = [bb[2].x, bb[1].y, bb[1].z]
				all_verts[count-5] = [bb[2].x, bb[2].y, bb[1].z]
				all_verts[count-6] = [bb[2].x, bb[1].y, bb[2].z]
				all_verts[count-7] = [bb[1].x, bb[2].y, bb[2].z]			
			)
		)
		--return
		(all_verts)
	)

	function createDots posis = 
	(
		local dots = #()	
		for p in posis do
		(
			s = sphere()
			s.pos = p
			s.radius = 4
			s.segments = 4
			s.wireColor = color 10 200 10
			append dots s
		)
		--return
		(dots)
	)

	function deleteDots =
	(
		delete $sphere*
	)

	function camH_to_xy verts =
	(
		local result = #()
		result.count = verts.count
		for i = 1 to verts.count do
		(
			result[i] = [ verts[i].x, -verts[i].z, 0]
		)
		--return
		(result)
	)

	function camV_to_xy verts =
	(
		local result = #()
		result.count = verts.count
		for i = 1 to verts.count do
		(
			result[i] = [ -verts[i].y, -verts[i].z, 0]
		)
		--return
		(result)
	)

	function fovSystem FOV =
	(
		FOV = FOV * 0.5 
		local right = [  cos (90-FOV), sin (90-FOV), 0]
		local right_plus90 = [  cos (180-FOV), sin (180-FOV), 0]
		local rup = [0,0,1]
		local left = [ cos (90+FOV), sin (90+FOV), 0]
		local left_less90 = [ cos (FOV), sin (FOV), 0]		
		local lup = [0, 0, -1]
		--return
		#( right, right_plus90, rup,  left, left_less90, lup)
	)	
	
	function minY_in_sys verts mat   =
	(
		local imat = inverse mat
		local miny = 0
		local minidx = 0
		for i = 1 to verts.count do
		(
			local v = verts[i] * imat
			if i==1 then 
			(
				miny = v.y
				minidx = i
			) else if v.y < miny then
			(
				miny = v.y
				minidx = i
			)
		)
		--return
		(minidx)
	)
	

	--Asume the camera is in 0,0 and verts are in 2D(x,y) space
	--return optimal camera pos in 2D
	function best_point_for_FOV FOV verts2D =
	(
		local fsys = fovSystem FOV
		local right_vec = fsys[1]
		local left_vec = fsys[4]
		local right_mat =  (matrix3 fsys[1] fsys[2] fsys[3] [0,0,0])
		local left_mat =  (matrix3 fsys[4] fsys[5] fsys[6] [0,0,0])		
		

		local minRightVert = minY_in_sys verts2d right_mat
		local minLeftVert = minY_in_sys verts2d left_mat
	
		local ip = intercept verts2d[minRightVert] (verts2d[minRightVert] + right_vec)  \
					               verts2d[minLeftVert] (verts2d[minLeftVert] + left_vec)		
		--return
		#(ip, verts2d[minRightVert], verts2d[minLeftVert])
	)
	
	function balanced_center p1 p2 yLevel = 
	(
		--see where formula comes: https://drive.google.com/file/d/1Vj-q29ZXUx7TAmS_T5MzAiSPJqjhXiZv/view?usp=sharing 
		local a = p1.y - yLevel
		local b = p2.y - yLevel
		local C = p2.x - p1.x
		local resx = 0
		if (a + b) != 0 then
		(
			resx = (a*c)/(a + b) + p1.x
		)
		--return
		(resx)
	)
	
	function zoomExtentCamera cam =
	(
		local objs = selection
		if objs.count == 0 then objs = objects
		if objs.count == 0 then return [0,0,0] --nothing happens
		local verts = sceneBoundingVerts Objs GeometryClass cam.transform
		
		--horizontal FOV
		local safeActionFrame = 0.9 --reduce 10% the FOV to give air to the borders. (Action safe zone)
		local hFOV = (cam.fov*safeActionFrame) -- * pi / 180
		--vertical FOV
		local vFOV = hFOV *  (renderHeight as float / renderWidth)
		
		--creates a 2D cordinate systems where the right or left side of the FOV volume is our new X axis
		--verts in camera coord system are converted to 2D xy system, for simplificaiton (in my mind i think )
		-- after multipliying any position with the inverse of this system every Y value is the distance from this point
		--to the one of these FOV sides (rays).

		--HORIZONTAL---------------------------------------	
		local verts2d = camH_to_xy verts
		local bpResult = best_point_for_FOV hFOV verts2d		
		local ip_H = bpResult[1]
		local HvertRight = bpResult[2]
		local HvertLeft = bpResult[3]
		
		--back to cam system
		local ipc_H = [ ip_H.x, 0, -ip_H.y]		
		
		--VERTICAL----------------------------------
		verts2d = camV_to_xy verts
		local bpResult = best_point_for_FOV vFOV verts2d
		local ip_V = bpResult[1]
		local VvertRight = bpResult[2]
		local VvertLeft = bpResult[3]
		
		--back to cam system 		
		local ipc_V = [ 0, -ip_V.x, -ip_V.y]
		
		-- cam will get the highest Z (in camera system coords)
		-- if Horizontal fov gives the highest Z,  then cam can't move in X axsis. So it gets X from ipc_H
		-- if Vertical fov gives the hightest Z,  then cam can't move in  Y axis, so it get Y from ipc_V
		local cpos = [0,0,0]
		if ipc_H.z > ipc_V.z then
		(
			cpos.z = ipc_H.z
			cpos.x = ipc_H.x
			--what about y? need more math, y from V center calc
			cpos.y = -(balanced_center VvertLeft VvertRight ip_H.y)
		) else
		(
			cpos.z = ipc_V.z
			cpos.y = ipc_V.y
			--x from H center calc
			cpos.x = (balanced_center HvertLeft HvertRight ip_V.y)
		)
				
		--return camera translation needed
		((cpos * cam.transform)-cam.pos)
	)
	
	------------------------------------------------------------------------EXECUTION STARTS HERE ---------------------------------------------
	if viewport.getType() == #view_camera then
	(
		local cam = getActiveCamera()
		local cam_move = zoomExtentCamera cam
		cam.pos = cam.pos + cam_move
		if cam.target != undefined then
		(
			cam.target.pos = cam.target.pos + cam_move
		)
	) else
	( -- do a standard Zoom Extents selected.
		actionMan.executeAction 0 "310"  
	)
	
)