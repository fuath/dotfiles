#!/bin/bash
# Dylan's Lemonbar
# Feel free to use/edit this script!
# If you manage to improve the script please send a PR

# Kills lemon bar to keep one instance open
# Useful as I'm constantly editing and then reloading this file.
if pgrep -x lemonbar; then
	pkill lemonbar
	pkill bar.sh
fi

# Variables {{{

white="FFFFFF"
black="#1C1C1C"
darkgrey="#252525"
blue="#689D6A"
lightblue="#8EC07C"
yellow="#FABD2F"

font="-benis-lemon-medium-r-normal--10-110-75-75-m-50-iso8859-1"
icons="-wuncon-sijipatched-medium-r-normal--10-100-75-75-c-80-iso10646-1"

# }}}

# Bar Size {{{

if [[ $(xrandr | awk '/DFP10/ {print $1}') == "DFP10" ]]; then
	size="1600x25"

elif [[ $(xrandr | awk '/eDP1/ {print $1}') == "eDP1" ]]; then
	size="1366x25"

else
	size=""
fi

# }}}

# Battery {{{

battery(){
	upower=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | awk '/state:/ {print $2}')

	if [[ $upower == "" ]]; then
		batt=""

	elif [[ $upower == "fully-charged" ]]; then
		batt=" Fully Charged"
		echo "%{B$lightblue} $batt "

	elif [[ $upower == "charging" ]]; then
		perc=$(acpi | cut -d, -f2 | sed -e 's/\%* *//g')
		batt=""
		echo "%{B$lightblue} $batt$perc% "

	elif [[ $upower == "discharging" ]]; then
		batt=$(acpi | cut -d, -f2 | sed -e 's/\%* *//g')

		if [[ $batt -gt 75 ]]; then
			echo "%{B$lightblue}  $batt%"

		elif [[ $batt -gt 50 && $batt -lt 76 ]]; then
			echo "%{B$lightblue}  $batt%"

		elif [[ $batt -gt 25 && $batt -lt 50 ]]; then
			echo "%{B$lightblue}  $batt%"

		elif [[ $batt -gt 10 && $batt -lt 50 ]]; then
			echo "%{B$yellow}  $batt%"

		else
			echo "%{B$yellow}  $batt%"
		fi
	fi
}

# }}}

# Clock {{{

clock(){
	# Displays the date eg "Sun 17 May 9:10 AM"
	date=$(date '+%a %d %b %l:%M %p')
	echo "$date"
}

# }}}

# Cpu {{{

cpu(){
	cpuusage=$(mpstat | awk '/all/ {print $4 + $6}')
	echo "$cpuusage% Used"
}

# }}}

# Memory {{{

memory(){
	# Show free memory
	free -m | awk '/Mem:/ {print " " $3" MB Used "}'
}

# }}}

# Music {{{

music(){
	musictoggle="A:mpc toggle:"
	musicnext="A4:mpc next:"
	musicprevious="A5:mpc prev:"

	# Displays currently playing mpd song, if nothing is playing it displays "Paused"
	if [[ $(mpc status | awk 'NR==2 {print $1}') == "[playing]" ]]; then
		current=$(mpc current)
		playing=$(echo " $current")
	else
		# playing=$(echo " Paused")
		playing=$(echo "")
	fi

	echo "%{$musictoggle}%{$musicnext}%{$musicprevious} $playing %{A}%{A}%{A}"
}

# }}}

# Volume {{{

volume(){
	volup="A4:pulseaudio-ctl up:"
	voldown="A5:pulseaudio-ctl down:"
	volmute="A:pulseaudio-ctl mute:"

	# Volume Indicator
	if [[ $(pulseaudio-ctl full-status | awk '/ / {printf $2}') == "yes" ]]; then
		vol=$(echo " Mute")
	else
		mastervol=$(pulseaudio-ctl full-status | awk '/ / {printf $1}')
		vol=$(echo " $mastervol")
	fi

	echo "%{$volup}%{$voldown}%{$volmute} $vol %{A}%{A}%{A}"
}

# }}}

# Wifi {{{

wifi(){
	strength=$(cat /proc/net/wireless | awk '/wlp4s0/ {print $3}' | sed -e 's/\.//g')

	if [[ $strength -gt 75 ]]; then
		echo "%{B$darkgrey}  $strength% "

	elif [[ $strength -gt 50 && $strength -lt 75 ]]; then
		echo "%{B$darkgrey}  $strength% "

	elif [[ $strength -gt 1 && $strength -lt 50 ]]; then
		echo "%{B$darkgrey}  $strength% "

	else
		echo "%{B$black}"
	fi
}

# }}}

# Window Title {{{

windowtitle(){
	# Grabs focused window's title
	# The echo "" at the end displays when no windows are focused.
	title=$(xdotool getactivewindow getwindowname 2>/dev/null || echo "Hi")
	echo " $title" | cut -c 1-50 # Limits the output to a maximum # of chars
}

# }}}

# Workspace Switcher {{{

workspace(){
	# Workspace switcher using wmctrl
	workspacenext="A4:bspc desktop -f next:"
	workspaceprevious="A5:bspc desktop -f prev:"

	wslist=$(\
		wmctrl -d \
		| awk '/[a-z]$/ {printf $2 $9}'\
		| sed -e 's/ //g' \
		-e 's/\-/\;/g' \
		-e 's/\*[ 0-9A-Za-z]*[^ -~]*/%{B#689D6A}  &  %{B}/g' \
		-e 's/\;[ 0-9A-Za-z]*[^ -~]*/%{B#252525}%{A:bspc desktop -f &:}  &  %{A}%{B}/g' \
		-e 's/\*//g' \
		-e 's/ \;/ /g'\
		)

	# Adds the scrollwheel events and displays the switcher
	echo "%{$workspacenext}%{$workspaceprevious}$wslist%{A}%{A}"
}

# }}}

# Echo all the things {{{

while :; do
	echo "\
		%{l}\
			$(workspace)\
			%{B$black} $(windowtitle) \
		%{l}\
		%{c}\
			%{B$black} $(clock) \
		%{c}\
		%{r}\
			$(wifi) \
			$(battery) \
			%{B$blue} $(volume) \
			%{B$blue} $(music) \
			%{B$black}\
		%{r}\
		"
	sleep .03s

done |
# }}}

# Finally, launches bar while piping the above while loop!
# | bash is needed on the end for the click events to work.
lemonbar -g $size -f $font -f $icons -F \#FF$white 2> /dev/null | bash