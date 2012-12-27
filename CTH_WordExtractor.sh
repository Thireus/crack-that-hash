#***************************************************************#
#** This file is part of the Crack That Hash project.         **#
#** CTH_WordExtractor.sh v1.2a                                **#
#**                                                           **#
#** -- Let's call this, the padding technique... ;)           **#
#**                                                           **#
#** ********************************************************* **#
#** --------------- Updated: Dec-23-2012 -------------------- **#
#** ********************************************************* **#
#**                                                           **#
#** Author: Pascal CLEMENT aka Thireus <cth@thireus.com>      **#
#**                                                           **#
#** http://blog.thireus.com                                   **#
#**                                                           **#
#** Crack That Hash,                                          **#
#** Copyright © 2012  Thireus.                                **#
#***************************************************************#
#**PLEASE REFER TO THE README FILE FOR ADDITIONAL INFORMATION!**#
#***************************************************************#

######## CHANGELOG BEGIN ########
#  
# v 1.2a
# - Some bug fixes
#
# v 1.2
# - Some bug fixes
#
# v 1.1
# - Changed wordlist generation to all combinations of word size
# - Added directories
# - Added Stats and Occurency limit
#
# v 1.0
# - Initial Release
#
######## CHANGELOG END ########

######## TODO BEGIN ########
# 
# - SESSIONS
# - INPUT CHECK + DEFAULT VALUE
#
######## TODO END ########

#!/bin/bash

######## PARAMETERS BEGIN ########

POT='john.pot'

DIRECTORY_CTH='CTH'
DIRECTORY_TEMP='.cth'

FILENAME_TEMP='temp'
FILENAME_WORDLISTS='CTH_WORDLIST_'
FILENAME_FINAL='CTH_WORDLIST_FINAL_'

EXTENSIONS='dic'
EXTENSIONS_STAT='stat'

PADDING_BEGIN=0
PADDING_END=10

######## PARAMETERS END ########

######## FUNCTIONS BEGIN ########

die () {
    echo >&2 "$@"
    exit 1
}

######## FUNCTIONS END ########

######## GET PARAMETERS BEGIN ########

echo "WELCOME TO CTH_WordExtractor v1.0!"
echo ""

[ "$#" -eq 2 ] || [ "$#" -eq 3 ] || die "Usage: ./CTH_WordExtractor.sh WINDOW_BEGIN WINDOW_END [RESTORE_SESSION]"
echo $1 | grep -E -q '^[0-9]+$' || die "Numeric argument required for WINDOW_BEGIN, $1 provided."
echo $2 | grep -E -q '^[0-9]+$' || die "Numeric argument required for WINDOW_END, $1 provided."
if [ $1 -gt $2 ]; then
	die "WINDOW_BEGIN must be lower than WINDOW_END."
fi
if [ "$#" -eq 3 ]; then
	echo $3 | grep -E -q '^[0-9]+$' || die "Numeric argument required for RESTORE_SESSION, $1 provided."
fi

WINDOW_BEGIN=$1
WINDOW_END=$2

######## GET PARAMETERS END ########

######## REQUIRED HEADERS BEGIN ########

export LC_ALL='C'

POT=$(pwd)/$POT
FILENAME_TEMP=$(pwd)/$DIRECTORY_CTH/$DIRECTORY_TEMP/$FILENAME_TEMP
FILENAME_WORDLISTS=$(pwd)/$DIRECTORY_CTH/$DIRECTORY_TEMP/$FILENAME_WORDLISTS
FILENAME_FINAL=$(pwd)/$DIRECTORY_CTH/$FILENAME_FINAL

mkdir -p $DIRECTORY_CTH/$DIRECTORY_TEMP
cd $DIRECTORY_CTH/$DIRECTORY_TEMP

echo > $FILENAME_TEMP.$EXTENSIONS
rm $FILENAME_TEMP.$EXTENSIONS
echo > $FILENAME_WORDLISTS.$EXTENSIONS
rm $FILENAME_WORDLISTS*.$EXTENSIONS
echo > $FILENAME_FINAL.$EXTENSIONS
rm $FILENAME_FINAL*.$EXTENSIONS
echo > $FILENAME_WORDLISTS.$EXTENSIONS_STAT
rm $FILENAME_WORDLISTS*.$EXTENSIONS_STAT

######## REQUIRED HEADERS END ########

######## GENERATING SESSION BEGIN ########

CTH_RANDOM_SESSION=1

for (( r=1; r<=10000; r++ ))
do
	CTH_RANDOM_SESSION=$(($CTH_RANDOM_SESSION+$[ ( $RANDOM % 10000 )  + r ]))
done

CTH_RANDOM_SESSION=$(($CTH_RANDOM_SESSION % 100000))

# TODO: VERIFY SESSION NOT EXISTS...

PROTECTED=$CTH_RANDOM_SESSION'_CTHprotected'

######## GENERATING SESSION END ########

######## SCRIPT BEGIN ########

echo "SESSION NUMBER: $CTH_RANDOM_SESSION"
echo "IF THIS SCRIPT IS KILLED, PLEASE USE: 
'rm -r $(pwd)/$DIRECTORY_TEMP/*$PROTECTED $(pwd)/*$PROTECTED' TO CLEAN YOUR DIRECTORY!"
echo "TO RESUME A KILLED SESSION, PLEASE USE: 
'./CTH_WordExtractor.sh $WINDOW_BEGIN $WINDOW_END $CTH_RANDOM_SESSION' (feature coming soon)"
echo ""

# Extract john.pot passwords
echo "[-] EXTRACTING $POT in $FILENAME_TEMP.$EXTENSIONS..." && \
cat $POT | cut -d: -f 2- | sort | uniq > $FILENAME_TEMP.$EXTENSIONS.$PROTECTED && \
\
mv $FILENAME_TEMP.$EXTENSIONS.$PROTECTED $FILENAME_TEMP.$EXTENSIONS && \
echo "[X] $FILENAME_TEMP.$EXTENSIONS CREATED!" && \
\
count_i=0 && \
for (( w=$WINDOW_END; w>=$WINDOW_BEGIN; w-- ))
do
# i = window length
	
	# Revert Window
	i=$w
	count_i=$(($count_i+1))
	
	echo "" && \
	echo "[-] EXTRACTING WINDOW $count_i/$(($WINDOW_END-$WINDOW_BEGIN+1)) for $i char(s) words..."
	
	count_j=0 && \
	for (( p=$PADDING_BEGIN; p<=$PADDING_END; p++ ))
	do
	# j = padding

		j=$p
		
		echo "[-] PADDING $count_j/$(($PADDING_END-$PADDING_BEGIN)) for padding of $j char(s)..."
		
		cat $FILENAME_TEMP.$EXTENSIONS | cut -c$((1+$j))-$(($i+$j)) > $FILENAME_WORDLISTS$((1+$j))-$(($i+$j))_$i.$EXTENSIONS.$PROTECTED && \
		\
		mv $FILENAME_WORDLISTS$((1+$j))-$(($i+$j))_$i.$EXTENSIONS.$PROTECTED $FILENAME_WORDLISTS$((1+$j))-$(($i+$j))_$i.$EXTENSIONS && \
		echo "[X] $FILENAME_WORDLISTS$((1+$j))-$(($i+$j))_$i.$EXTENSIONS CREATED!"
		
		count_j=$(($count_j+1))
	 
	done

##NOTE: Unused ' | sort -nr' by awk, thus will not be used here.
	echo "[-] CONCATENATING all $i chars words..." && \
	cat $FILENAME_WORDLISTS*_$i.$EXTENSIONS | grep -E "^.{$i}$" | sort | uniq -c > $FILENAME_WORDLISTS$i-$i.$EXTENSIONS_STAT.$PROTECTED && \
	rm $FILENAME_WORDLISTS*_$i.$EXTENSIONS

done && \
for (( w=$WINDOW_END; w>=$WINDOW_BEGIN; w-- ))
do
# i = window length

	# Revert Window
	i=$w
	count_i=$(($count_i+1))

	echo "" && \
	echo "[-] READING stats for $i chars words..."

	cat $FILENAME_WORDLISTS$i-$i.$EXTENSIONS_STAT.$PROTECTED | awk '{array[$2]=$1; sum+=$1} END { for (i in array) printf "%-15s %-15d %6.2f%%\n", i, array[i], array[i]/sum*100}' | sort -k2,2 -n | tail -n 100

	echo "[!] PLEASE SELECT AN OCCURENCY LIMIT (default 1 occurency):" && \
	read LIMIT_OCCURENCY && \
	echo "[X] You entered: $LIMIT_OCCURENCY"

	echo "[-] BUILDING wordlist. Please wait..."
	# Concat all FILENAME_WORDLISTS for the same window length and higher than LIMIT_OCCURENCY occurencies
	cat $FILENAME_WORDLISTS$i-$i.$EXTENSIONS_STAT.$PROTECTED | awk '{array[$2]=$1; sum+=$1} END { for (i in array) if (array[i] >= '$LIMIT_OCCURENCY') printf "%s\n", i}' > $FILENAME_FINAL$i-$i.$EXTENSIONS.$PROTECTED && \
	rm $FILENAME_WORDLISTS$i-$i.$EXTENSIONS_STAT.$PROTECTED && \
	\
	mv $FILENAME_FINAL$i-$i.$EXTENSIONS.$PROTECTED $FILENAME_FINAL$i-$i.$EXTENSIONS && \
	echo "[X] $i chars words CONCATENATED in $FILENAME_FINAL$i-$i.$EXTENSIONS!"
	
	# Concat FILENAME_WORDLISTS to FILENAME_FINALs
	for (( s=$i; s>=$WINDOW_BEGIN; s-- ))
	do
		for (( t=$WINDOW_END; t>=$i && t!=$s; t-- ))
		do
			cat $FILENAME_FINAL$i-$i.$EXTENSIONS >> $FILENAME_FINAL$s-$t.$EXTENSIONS.$PROTECTED
		done
	done
   
done && \
\
for (( w=$WINDOW_END; w>=$WINDOW_BEGIN; w-- ))
do
	for (( x=$WINDOW_END; x>=$w && x!=$w; x-- ))
	do
		mv $FILENAME_FINAL$w-$x.$EXTENSIONS.$PROTECTED $FILENAME_FINAL$w-$x.$EXTENSIONS && \
		echo "" && \
		echo "[X] $FILENAME_FINAL$w-$x.$EXTENSIONS CREATED!"
	done
done

echo ""
echo "Bye bye =]"

######## SCRIPT END ########
