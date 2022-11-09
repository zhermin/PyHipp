#!/bin/bash

echo -e "Number of all hkl files"
find . -name "*.hkl" | grep -v -e spiketrain -e mountains | wc -l

echo -e "Number of raw, lowpass, and highpass hkl files"
find . -name "rplhighpass*hkl" -or -name "rpllfp*hkl" -or -name "rplraw*hkl" | wc -l

echo -e "Number of mda files"
find mountains -name "firings.mda" | wc -l

echo -e "Completed Channels for Channels | Lowpass | Highpass | Firings.mda"
find . -name "channel*" | grep -v -e eye -e mountain | sort | cut -d "/" -f 1-4 | wc -l
find . -name "rpllfp*hkl" | grep -v -e eye -e mountain | sort | cut -d "/" -f 1-4 | wc -l
find . -name "rplhighpass*hkl" | grep -v -e eye -e mountain | sort | cut -d "/" -f 1-4 | wc -l
find . -name "firings.mda" | grep -v -e eye | sort | cut -d "/" -f 3 | wc -l

echo -e "\n---\n\nStart Times\n"
head -n 1 *.out

echo -e "\n---\n\nEnd Times\n"
tail -n 5 *.out
