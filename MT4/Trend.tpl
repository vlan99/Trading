<chart>
symbol=GBPUSD
period=60
leftpos=11750
digits=5
scale=4
graph=1
fore=0
grid=1
volume=0
scroll=0
shift=1
ohlc=1
one_click=0
askline=0
days=0
descriptions=0
shift_size=20
fixed_pos=0
window_left=120
window_top=120
window_right=1273
window_bottom=613
window_type=3
background_color=0
foreground_color=16777215
barup_color=65280
bardown_color=65280
bullcandle_color=0
bearcandle_color=16777215
chartline_color=65535
volumes_color=14772545
grid_color=10061943
askline_color=255
stops_color=255

<window>
height=100
<indicator>
name=main
</indicator>
<indicator>
name=Custom Indicator
<expert>
name=MoneyManagement
flags=339
window_num=0
<inputs>
FontSize=11
MaxRiskPercentage=0.01000000
</inputs>
</expert>
shift_0=0
draw_0=0
color_0=0
style_0=0
weight_0=0
period_flags=0
show_data=1
</indicator>
<indicator>
name=Custom Indicator
<expert>
name=roundnumber_grid
flags=339
window_num=0
<inputs>
HGrid.Weeks=10
HGrid.Pips=1000
HLine=10061943
HLine2=10061943
Enable=1
</inputs>
</expert>
shift_0=0
draw_0=0
color_0=0
style_0=0
weight_0=0
period_flags=0
show_data=1
</indicator>
</window>
</chart>

