function FormatNumToStr Num Digits =
(
	s = (Num as string)
	for i=1 to (Digits-s.Count) do (s = "0" + s)	
	Result = s
)

Segm = 0
Count = 0
Dest = "F:\\_pxOutput\\Renders\\afro toon\\morphEnumAni\\Error"
for i=0 to 359 do
(
	Count = Count +1		
	if (Count==1) then
	(
		Dest =  "F:\\_pxOutput\\Renders\\afro toon\\morphEnumAni\\face" + (FormatNumToStr Segm 2)	
		MakeDir Dest		
		Segm = Segm + 1
	)				
	if (Count==20) then Count = 0
		
	SrcFile = "F:\\_pxOutput\\Renders\\afro toon\\morphEnumAni\\PNG\\afro_moEnumAni_" + (FormatNumToStr i 4) + ".png"
	--print SrcFile
	--print DestFile
	--copying while duplilcating 3 times
	for j = 0 to 2 do
	(
		DestFile = Dest + "\\afro_moEnumAni_" + (FormatNumToStr (i+j*20) 4) + ".png"
		CopyFile SrcFile DestFile
	)
)

