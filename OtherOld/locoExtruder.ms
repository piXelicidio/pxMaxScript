
N = PolyOp.GetNumFaces $
for i=1 to 600 do
(
	-- N = PolyOp.GetNumFaces $ --Incliding new ones
	r = ( random 1 (N) );
	polyop.ExtrudeFaces $ #(r) 10	
)