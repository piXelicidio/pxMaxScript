macroScript BipContinuityZero category:"pX Tools" 
(
 idx = getkeyindex $.controller sliderTime
	print idx
 if idx!=0 then
 (
  bipkey = biped.getkey $.controller idx
  bipkey.continuity = 0
 )
)