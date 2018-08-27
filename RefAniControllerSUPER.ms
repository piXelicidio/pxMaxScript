xyz = getXYZcontrollers That.position.controller
zz = xyz[3]
rm = handler
a=0
k1=0
k2=0
for i=1 to zz.keys.count do
(
  k1 =i-1
  k2 =i
  if zz.keys[i].time > rm then exit
)

if (k1>0) and (k2<=zz.keys.count) then
(
print k1
print k2
  m = zz.keys[k2].value - zz.keys[k1].value
  m = m/(zz.keys[k2].time - zz.keys[k1].time)		
  res = m*(rm-zz.keys[k1].time) + zz.keys[k1].value	
) else (res=0)
v: T:0
v: S:0
v: F:0
v: NT:0
v: That:0
v: handler:0
