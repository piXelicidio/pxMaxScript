arr = #(10,10,11,11,12,18,13,13,12,11,12,12,11,10,9)
rad = 1

for i=1 to arr.count do
(
	sliderTime = i-1
	$box01.pos = [i, 0, arr[i] ]
)
for i=1+rad to arr.count-rad do
(
	sliderTime = i-1
	T = 0
	for j=(i - rad) to (i + rad) do
	(
		T = arr[j] + T
	)
	P= T / (rad*2.0 + 1)	
	$box02.pos = [ i, 10, P]
	
	maxdif = 0
	posi = i
	for j=(i - rad) to (i + rad) do
	(
		if abs(arr[j] - P) > maxdif then
		(
			maxdif = abs(arr[j] - P)
			posi = j
		)
	)
	
	T = T - arr[posi]
	PR = T  / (rad*2.0)
	$box03.pos = [i, 20, PR]
	
)

