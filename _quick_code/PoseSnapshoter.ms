-- Every N frames gets snapshot of a selected model and translate it 
--also could name objects from array of strings 
--select result objects
function snapshoter obj spacing names = (
    local N = 5
    local start = 0
    local last = 120
    local result = #()
    for i=0 to last by N do
    (
        sliderTime = i 
        c = snapshot $
        move c [spacing + spacing*i,0,0]
        if names != undefined then
        (
            c.name = $.name+ "_"+names[(i / N)+1]
        )
        append result c
    )
    select result
)
onames = #()
onames[1] = "standing1"
onames[2] = "standing2"
onames[3] = "standing_handscrossed"
onames[4] = "standing_hand_hips"
onames[5] = "standing_bodyguard"
onames[6] = "walking_r"
onames[7] = "walking_l"
onames[8] = "running_l"
onames[9] = "running_r"
onames[10] = "looking_at_r"
onames[11] = "looking_at_l"
onames[12] = "standing_handsback"
onames[13] = "talking_handhip"
onames[14] = "talking_twohands"
onames[15] = "sitting"
onames[16] = "sitting_handscrossed"
onames[17] = "sitting_reading"
onames[18] = "sitting_talking"
onames[19] = "sitting_handside"
onames[20] = "sitting_ground"
onames[21] = "sitting_groundside"
onames[22] = "standing_handgrab"
onames[23] = "standing_thinking"
onames[24] = "walking_salute"
onames[25] = "walking_handsback"
snapshoter $ 20 onames