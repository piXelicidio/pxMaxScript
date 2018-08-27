rollout SuperSuma "Lester Super-OCX" width:162 height:113
(
    --Con esta simple linea se carga el OCX
	ActiveXControl sumLester "{848DB595-5C0A-462C-ACCB-C97C94D8B925}" pos:[13,7] width:139 height:8 enabled:true
	
	--Estas de aquí son pacotillas visuales...
	spinner spn1 "A = " pos:[16,24] width:55 height:16 range:[-100,100,25]
	spinner spn2 "B = " pos:[88,23] width:59 height:16 range:[0,100,33]
	button btn1 "SuperSumar..." pos:[11,51] width:138 height:23
	label lbl1 "Resultado = ?" pos:[27,84] width:119 height:21
	
	on btn1 pressed do
	(
		b = double 0.1		
		sumLester.Sumar  (spn1.value as double) (spn2.value as double) (b) 
		lbl1.caption = "Resultado = "+ (b as string)	
	)
)

createDialog SuperSuma
