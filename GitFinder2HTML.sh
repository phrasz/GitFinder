#!/bin/bash

# ============================================================================
# A barebones Script Starter for BASH
	version=1.0
	progname=$(basename $0)
# ============================================================================
# Orignal Copyright:
# Copyright (C) 2007 by Bob Proulx <[hidden email]>.
# Found on: http://gnu-bash.2382.n7.nabble.com/Bash-getopts-option-td3251.html
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.


# ==============================================
print_help(){
	clear
    cat <<'EOF'
   _______ _   ________           _
  / ____(_) | |  ____(_)         | |
 | |  __ _| |_| |__   _ _ __   __| | ___ ___
 | | |_ | | __|  __| | | '_ \ / _` |/ _ \'__|
 | |__| | | |_| |    | | | | | (_| |  __/ |
  \_____|_|\__|_|    |_|_| |_|\__,_|\___|_|

Options:
      --help          Print this help message
      --version       Print program version
  -d, --device        Change the default NIC
  -r, --remote        Pull down remote IP
  -v, --verbose       Verbose output

Examples:
The most common use is to run it like this.
  $ ./GitFinder2HTML.sh -r

But sometimes like this.
  $ ./GitFinder2HTML.sh -r -d lan0 -v

EOF
}
# ==============================================

# ==============================================
print_version() {
	cat <<EOF
	$progname $version
	A local replacement for GitHub/Bitkeeper ^_^

	Free Software Foundation, Inc.
	This is free software.  You may redistribute copies of it under the terms of
	the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
	There is NO WARRANTY, to the extent permitted by law.

	Shell script Originally Written by Bob Proulx.
	Barebone Script Created by Phrasz
EOF
}
# ==============================================


Flags="d:vr"
Words="help,version,verbose,debug,device,remote,device"

if $(getopt -T >/dev/null 2>&1) ; [ $? = 4 ] ; then # New Words getopt.
    OPTS=$(getopt -o $Flags --long $Words -n "$progname" -- "$@")
else # Old classic getopt.
    # Special handling for --help and --version on old getopt.
    case $1 in --help) print_help ; exit 0 ;; esac
    case $1 in --version) print_version ; exit 0 ;; esac
    OPTS=$(getopt $Flags "$@")
fi

if [ $? -ne 0 ]; then
    echo "'$progname --help' for more information" 1>&2
    exit 1
fi

eval set -- "$OPTS"

# INTIALIZATIONS:
device="wlan0"
File="gitRepos"
remote=false
verbose=false
debug=false
TotalProjectSize=0
WebPage="index.html"
Date=`date --iso-8601=minutes`

port=`cat /etc/ssh/sshd_config | grep Port | awk '{print $2}'`
IP=`ifconfig $device | grep "inet addr" | awk '{print $2}' | tr ":" " " | awk '{print $2}'`
IP_REMOTE="0.0.0.0"
HOST=`hostname`
USER=`whoami`

while [ $# -gt 0 ]; do
    : debug: $1
    case $1 in
        --help)
            print_help
            exit 0
            ;;
        --version)
            print_version
            exit 0
            ;;
	 --debug)
            debug=true
            shift
            ;;
	-d | --device)
            device="$2"
            shift 2
            ;;
        -r | --remote)
            remote=true
            shift
            ;;
        -v | --verbose)
            verbose=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "[ERROR] Internal Error: option processing error: $1" 1>&2
            exit 1
            ;;
    esac
done


if $verbose;then
echo "[GitFinder] This is your Device: $device"
echo "[GitFinder] My IP: "$IP
echo "[GitFinder] My REMOTE IP: "$IP_REMOTE
fi

if $remote; then
	IP_REMOTE=`wget http://ipecho.net/plain -O - -q ; echo`
	if $verbose; then
		echo "[GitFinder] Your Remote IP is: "$IP
	fi
	#rm ip
fi

#declare -a names_array=( check check 1 2 1 2 )
sudo find / | grep ".git/HEAD" >> $File

index=0
while read line ; do
        GitArray[$index]="$line"
        index=$(($index+1))
done < $File
rm $File


#########################################
# Website Builder: Html Creation
# ------------------------------
#
cat > $WebPage <<'Html_Header'
<html>
	<head>
	<script>
		$(window).scroll(function(){
			if ($(window).scrollTop() >= 200){
				$("#menu").css({position:'fixed',left:'0',top:'0'});
			}
			else{
				$("#menu").css({position:'absolute',left:'0',top:'200px'});
			}
		});
	</script>
	<link rel="stylesheet" href="resources/TopBar.css" type="text/css" media="screen" />
		<title>
Html_Header
#########################################


#GitFinder Last Updated: 2013-06-14 9:16 PM
echo -e "\t\t\tLast Modified: $Date" >> $WebPage

#########################################
# Website Builder: Html Creation Part 2
# -------------------------------------
#
cat >> $WebPage <<'Html_Part2'
		</title>
	</head>
	<body>
		<ul id="menu">
			<li><a href="#" class="drop">Git Repositories</a>
				<div class="dropdown_1column">
					<div class="col_1">
						<ul>
Html_Part2

adjusted_lines=$index
adjusted_lines=$(( adjusted_lines - 1 )) #exception handling

for i in `seq 0 ${adjusted_lines}`;
do
        temp=${GitArray[$i]}

        new_len=${#temp}
        new_len=$(( new_len - 10 ))
        new_str=${temp:0:new_len}
	new_title=`echo $new_str | tr -d  " "`

	projectName=`echo $new_title | awk -F"/" '{ print $NF }'`
	echo -e "\t\t\t\t\t\t\t<li><a href=\"#$projectName\">$projectName</a><li>" >> $WebPage

	ProjectSize=`du -sh -k "$new_str" | awk '{print $1}'`
	TotalProjectSize=$((TotalProjectSize + ProjectSize ))

done

cat >> $WebPage <<'Html_Part3'
						</ul>
					</div>
				</div>
			</li>
			<li><a href="#" class="drop">Statistics</a>
				<div class="dropdown_2columns">
					<h3>Host Machine</h3><center>
Html_Part3

if $verbose; then
	echo "[GitFinder] My hostname: "$HOST
fi

echo -e "\t\t\t\t\t\t<center><p>$HOST</p></center>" >> $WebPage

cat >> $WebPage <<'Html_Part4'
					</center><br>
					<h3>Number of Projects Hosted</h3><center>
Html_Part4

if $verbose; then
	echo "[GitFinder] Total Projects: ${#GitArray[@]}"
fi
echo -e "\t\t\t\t\t\t<center><p>${#GitArray[@]}</p></center>" >> $WebPage

cat >> $WebPage <<'Html_Part5'
					</center><br>
					<h3>Size of Projects Hosted</h3><center>
Html_Part5

Temp2=$(( TotalProjectSize / 1024 ))
if $verbose; then
	echo "[GitFinder] Total File Size: $TotalProjectSize KB, $Temp2 MB"
fi

echo -e "\t\t\t\t\t\t<center><p>$TotalProjectSize KB, $Temp2 MB</p></center>" >> $WebPage

cat >> $WebPage <<'Html_Part6'
					</center><br>
				</div>
			</li>
			<li class="menu_right"><a href="#" class="drop">About</a>
				<div class="dropdown_2columns align_right">
					<div class="col_2">
						<h3>Why build Git Finder?</h3>
							<p>GitFinder was created in an attempt to allow a local Repo listing without too much extra hooliganry.</p>
						<h3>What About Gitweb?</h3>
							<p>I did look at some of the Git Web interfaces, and was impressed with their options/features. However, I wanted something that I can serve as files/static pages and do not want php/cgi.</p>
							<p>GitWeb might work for you and can be seen here:</p>
							<a href="https://git.wiki.kernel.org/index.php/Gitweb">GitWeb</a>
					</div>
				</div>
			</li>
		</ul>
		<div id="content-container">
			<br><br><!--CHEAT!-->
Html_Part6

for i in `seq 0 ${adjusted_lines}`;
do
        temp=${GitArray[$i]}

        new_len=${#temp}
        new_len=$(( new_len - 10 ))
        new_str=${temp:0:new_len}
	new_title=`echo $new_str | tr -d  " "`

	projectName=`echo $new_title | awk -F"/" '{ print $NF }'`
	echo -e "\t\t\t<a id=\"$projectName\"></a>" >> $WebPage #$WebPage
	echo -e "\t\t\t<div id=\"content2\">" >> $WebPage
	echo -e "\t\t\t\t<h2><a>$projectName</a></h2>" >> $WebPage #$WebPage

	if $verbose; then
		echo "[GitFinder] Project Name: $projectName"
	fi
	#cd "$new_str"
	git --work-tree="$new_str" --git-dir="$new_str/.git" log  | grep Date | awk '{print $4" "$3" "$6" at "$5}' > tempfile
	GitTime=`head -n 1 tempfile`
	git --work-tree="$new_str" --git-dir="$new_str/.git" log  | grep Author | awk '{print $2}' > tempfile
	GitAuthor=`head -n 1 tempfile`
	rm tempfile

	echo -e "\t\t\t\t<p>Last Updated $GitTime by $GitAuthor</p>" >> $WebPage #$WebPage

	ProjectSize=`du -sh "$new_str" | awk '{print $1}'`
	if $verbose; then
		echo "[GitFinder] Current Project Size: $ProjectSize"
	fi

	echo -e "\t\t\t\t<p> Project Size: $ProjectSize Bytes</p>" >> $WebPage

	echo -e "\t\t\t\t<div class=\"details\">" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t<p>" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t<font size=\"5\">Local</font>" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t<hr>" >> $WebPage #$WebPage

	if $verbose; then
        	echo "[GitFinder] GitArray["$i"]: git clone ssh://$USER@$IP:$port\""$new_str"\""
	        echo "[GitFinder] GitArray["$i"]: git clone ssh://$USER@$IP_REMOTE:$port\""$new_str"\""
		echo "[GitFinder] Last updated $GitTime by $GitAuthor"
	echo ""
	fi
	echo -e "\t\t\t\t\t\tgit clone ssh://$USER@$IP:$port\"$new_str\"" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t<br><br><font size=\"5\">Remote</font>" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t<hr>" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t\tgit clone ssh://$USER@$IP_REMOTE:$port\"$new_str\"" >> $WebPage #$WebPage
	echo -e "\t\t\t\t\t</p>" >> $WebPage # $WebPage
	echo -e "\t\t\t\t</div>" >> $WebPage # $WebPage
	echo -e "\t\t\t</div>" >>  $WebPage #$WebPage

done

#########################################
# Website Builder: Close Out
# --------------------------
#
cat >> $WebPage <<'Html_Footer'
			<div id="content2">
				<h2><a id="contact">Contact Me</a></h2>
				<div class="details">
					<p><a href="https://github.com/phrasz">Find me on Git!</a></p>
				</div>
			</div>
		</div>
	</body> </html>
Html_Footer
#########################################


#echo "This is Temp:"
#cat index.html
