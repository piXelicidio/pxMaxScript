--Unwrap_UVW.setFaceVertex point3  FaceIndex VertNumIndex boolSelect

vnum = (polyop.getMapFace $ 9 1).count
for i=1 to vnum do
(
	$.Unwrap_UVW.setFaceVertex [0,0,0] 9 i false
)