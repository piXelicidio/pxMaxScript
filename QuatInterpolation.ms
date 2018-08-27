q1 = $Box01.rotation
q2 = $Box02.rotation	
for i=0 to 20 do
(
	tendencia = i / 20.0
	qres = slerp q1 q2 tendencia
	b = box height:50 width:2 length:2
	b.rotation = qres
)