--get a selected group of objects with a rotation list including a rotation noise
-- and write some object Y position to the Noise Weight.
-- The controller object has Float Limit controller on the Y Position... :-o ... and goes from 0 .. 10
-- useful to control tree animation from pxTreeMotion script (add it later to it)

objCtrl = $rigSlider_windWeight

for i=1 to selection.count do
(
    local subAnim_Source = objCtrl[#transform][#position][2][#Y_position]
    local obj = selection[i]
    local subAnim_Dest = obj[#transform][#rotation][#Weights][#Weight__Noise_Rotation]
    paramWire.connect subAnim_Source subAnim_Dest "Y_Position/10"
)