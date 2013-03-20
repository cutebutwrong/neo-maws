listxml Perl utility scripts as used by MAWS
--------------------------------------------

Usage: perl script.pl mameinfo.xml > outputfile.txt

---

xml2gamelist.pl
A script that accepts a MAME listxml file and outputs a text file in the style of the old gamelist.txt that was distributed with older versions of MAME.

xml2hilist.pl
A script that accepts a MAME listxml file and outputs a text file in the style of the old gamelist.txt, comparing save state support with hiscore.dat .

xml2cocktail.pl
A script that accepts a MAME listxml file and outputs a text file in the style of the old gamelist.txt with cocktail mode support.

xml2diplist.pl / xml2diplist2.pl
Created for Guru. A script that accepts a MAME listxml file and outputs an HTML page of games with missing dip switch information.

xml2dumpinfo.pl
Created for Guru. A script that accepts a MAME listxml file and outputs an HTML page of games that have bad or missing dumps.

xml2json.pl
An experimental script to transform MAME listxml to JSON format.

Please help yourself to any scripts. All require Perl 5 and above.
  
---

You will need Perl 5 or above. These scripts require a listxml file rather than accepting a stream from MAME.

---

other Perl utility scripts
--------------------------

maws_ini2ini32.pl
Convert an INI file (such as catver.ini or nplayers.ini) to the MAME32 compatible format. Developed for Nomax to support MAME32. 
Note: you must edit the file to configure source/target
