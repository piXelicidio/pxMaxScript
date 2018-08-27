-- Count names repetitions
total=0
for i=1 to $objects.count do
(
	n = $Objects[i].name
	cn =  "$" + n + "*"
	Try
	(
		grupo = execute cn
		cant = -1
		for j=1 to grupo.count do
		(
			if grupo[j].name.count == n.count then 
			(
				cant = cant+1
				if cant>0 then print n				
			)
			
		)
		Total = Total + Cant  		
	) catch ()
	
)
print Total