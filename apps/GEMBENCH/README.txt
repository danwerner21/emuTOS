GEM BENCH CHANGE LOG


Current benchmarking files - 

CT6066 - CT60 @ 66mhz
DEFAULT - STE TOS 206 8mhz stock 
STE20608 - same as above
STE20616 - STE TOS 206 @ 16mhz
STE20632 - STE TOS 206 @ 32mhz
FALCON30 - Stock falcon
STFMT28 - STFM running T28 booster (thanks Sophie)
STFM1048 - STFM TOS 104 @ 8mhz (stock machine)
PAK030 - STacy with PAK 030 booster (thanks Darklord)
CT6090SV - CT60 @ 90mhz with Supder Videl (Thanks  Fredrik)
MSTEB8 - MEGA STE BLITTER TOS 206
MSTEB16 - MEGA STE BLITTER TOS 206 16MHz
MSTEB16C - MEGA STE BLITTER TOS 206 16MHz CACHE ENABLED
PAK020 - PAK 020 STFM 16MHz
PAK020CD - PAK 020 STFM 16MHz with CACHE DISABLED
PAK02016 - PAK020 Booster running 16MHz (thanks Frank Lucas) - obsolete file ?
STE20682 - STE TOS 206 @ 8MHz 2 Colours - thanks IngoQ
ST20616 - STFM TOS 206 16MHz (V2.2 BOOSTER)
VELOCE - STE 020 BOOSTER 



*************************************
GEMBENCH V608 B31 - BETA 19-july-2018
*************************************
Added "tick" in menu for blitter on/off. Also fixed minor blitter on/off & info displayed bug. 
Added flashing red borders for when starting a new loop. This was a visual aid so I can look "at a glance" when I see the flashing red to see what loop its on  
Added "OUTPUT LOOP" to EXTRA menu. Will output current loop count to file (this means I dont have to watch it all the time to see what loop it got up to before crashing!)


*************************************
GEMBENCH V607 B30 - BETA 10-apr-2018
*************************************
Fixed critical bug in the ALT-RAM test. I noticed this with my STE on TOS206. It would crash just after doing the test (with no alt-ram installed). 
I don't know why this bug only just showed up as nothing has changed with this code since the very first release. 
However, there was some code running in the wrong order, this means it should have never worked since day one, but it did, madness!  

So this current build fixes routine and now it seems stable again. 


*************************************
GEMBENCH V607 B29 - BETA 28-nov-2017
*************************************
Patched to work with 68010 CPU. 


*************************************
GEMBENCH V607 B28A - BETA 18-sep-2017
*************************************
Added PI3 screen shot support for high-resolution.


*************************************
GEMBENCH V607 B28 - BETA 18-sep-2017
*************************************
IngoQ Also suggested the average calculation should be based on the CPU and graphics average averages, and not over every single test. 
Basically because the tests would be weighted towards the graphics figures as there are twice as many graphics tests over CPU tests. 
All the calculations affected are only under statistics figures.
More information on this is listed on my forum. https://www.exxoshost.co.uk/forum/viewtopic.php?f=25&t=27

Also I have now re-added in the classic average mode calculations. Under the extra menu you can toggle between classic no calculation and geometric calculation. 
Which mode is selected is now displayed in the window title bar.

IngoQ Also found saving screenshots was ignoring path changes and drive letter changes. Also the same with exporting results as a text file. This should now be fixed.
It is worth noting that saving and loading of the GB6 files is limited to the SETS folder in the GB6 directory and cannot be changed.

IngoQ Also submitted a new benchmark file for the STE in monochrome mode. It is worth noting that you cannot compare medium resolution tests 
done in four colours to high-resolution into colours the results will vary. So you have to use different benchmark file for each resolution or colour depth change.

I do not use mono resolution personally so I have never taken any benchmark files for it. If anyone can supply other monochrome benchmarks and I can include them in future builds.


*************************************
GEMBENCH V606 B27A - BETA 16-sep-2017
*************************************
IngoQ Noticed a typo in my code relating to what tests were being calculated for the statistics results.
so previous versions would incorrectly include a CPU test in the display statistics for example.this has now been fixed.

This version is called build 27A.


*************************************
GEMBENCH V606 B27 - BETA 14-sep-2017
*************************************
It has come to my attention that the average results not calculating correctly. I actually took the calculation code direct from the original Gembench 4 code. 
So as there actually seems to be a bug, this bug has been there since day one and it has taken 30+ years for anyone to actually notice. 
I think because Gembench 6 allows you to change the reference profile properly, it is now shows up this bug more than the original Gembench. 

Originally I had for example, 
100% + 200% + 100% = 400% / 3 = 133%
Which is arithmetic mean

But apparently it should be,
100% x 200% x 100% = 2,000,000 ^ (1/3) = 126%
Which is geometric mean

https://www.youtube.com/watch?v=_UdGUULKN-E
http://www.investopedia.com/ask/answers/06/geometricmean.asp

So build 27 has the adjusted percentage calculation routines. Thanks to IngoQ for helping me solve this issue.

This build also displays the build number in the title bar. As there are a lot of versions of Gembench now it may cause confusion if results differ 
to results shown are my website for example as they were likely using a previous build.

The percentages per  individual test are not affected and will remain the same as before.

*************************************
GEMBENCH V606 B26 - BETA 18-may-2017
*************************************
Noticed a crash after about 60 full test loop passes. Took a huge epic of debugging to work out it was a bug in a hisoft function. 
Tweaked some "pause" loops to use AES event timer, rather than looping for "timer tick". 

***************************
GEMBENCH V606 B25 - BETA
***************************
The export text file the referance and system text was backwards - thanks to Ektus for spotting that! been a bug right from the start and nobody noticed, not even me!
Fixed a crash on 16M colours (colours wasn't able to calculate and gave overflow) Now over 20bit planes ?16M colours the file will report N/A. 
	Number of colours isn't used in GB6 so may be take out in the future anyway - thanks Ektus for the report. 



***************************
GEMBENCH V606 B24 - BETA
***************************

Fixed benchmarking files to include FPU & ALT-RAM tests in all files. 
***IO MAPPED FPU not running tests - Thanks Troed for the report.  NO IO MAPPED FPU ASM CODE for MSTE & STFM - simply not supported.
IO mapped FPU works different than the FPU on the 030 CPU with Falcon etc. So 2 FPU tests would need to be programmed and wouldn't have any correlation to eachother anyway. So trying to compare the same FPU at the same speed on a STFM and Falcon just wouldn't tally up as the STFM version would have more coding "overhead" and I doubt anything uses the FPU ont he STFM, or even the MSTE.  FPU on the falcon may be used more but still hardly any apps use it. So I don't see adding FPU support is worth while to anything below the Falcon.  Its debaitable if its even worth having a FPU test in GB6 at all really.  The only reason it was added was to benchmark overclocking on the Falcon FPU. Though there is a dedicated benchmark for that anyway.  If anyone wants IO MAPPED FPU support adding, then they will have to update the assembly code to support it. Nothing I have time or knowledge to do :) 

Theres a annoying title bar bug which I am not sure how to solve. on the falcon the gem window title bar is actually 4 pixels taller than on the ST. Likely because of "3D effect".
	So on the Falcon the last few pixels of the title bar were actually missing.  To fix this I made the whole window 4 pixels taller to fix the display on the falcon. 
	This has the side effect that there is now a 4pixel gap on the ST which wasn't there before.  I guess nobody is likely to notice it, aside from that, I can't be bothered to look into it :) 

Added some benchmarks for Monster alt-ram in the ST/E benchmarking files.  Not 100% sure they will report 100% exactly but its a start :) 
Finally started to code the screenshot routine which was a nightmare. Currently only Pi2 is supported and unlikely be any others since GB6 is designed to run in ST-med-res.  Thanks to Georges Kesseler for figuring out "setcolor" can actually be used to obtain the colours.  Poking the address direct $ff8240 never seemed to work right under steem , not sure why, but the bios call worked good.  Thanks also to Janez Valant for helping me get to grips with the file format. 



***************************
GEMBENCH V606 B23 - ALPHA
***************************
overflow error with stupidly fast emulators (thanks ip ) fixed. 
Should % values be greater than 99999% then it will now show "ERROR %". This is simple due to the GUI % limit being 5 numbers long. GB4 only had 3 numbers so I upped to 5 (and no im not upping them again!)
Likely previous builds would crash with a overflow error with over 32768% scores. 
Tests which run faster than 1 second are not going to be accurate. Mostly this is people running emulators which give crazyass speeds. GB6 was designed for proper hardware so shouldn't be used on emulator based systems.  


***************************
GEMBENCH V606 B22 - ALPHA
***************************
Error in int-div test fixed by dml (thanks gadgetuk for spotting it)
Added mouse off routines by dml. 




***************************
GEMBENCH V606 B21 - ALPHA
***************************
Average calculations no longer take into account zero figures (that results from benchmarking a machine against a incorrect benchmark file)


***************************
GEMBENCH V606 B20 - ALPHA
***************************
More changes by dml for the cache control code, which *should* be fixed now.
Data Cache on the 030 (stock falcon) doesn't seem to do anything much (dml reports thats normal)

*****
The d-cache on Falcon is a complicated affair but for many of the 'benchmark' style tests it won't show much of a gain and might even be slightly negative.

The d-cache only remembers the last 256 longwords read by the CPU. There's no cost for storing this data in the cache and no cost for recalling it - the process is invisible - so normally it would be free on a machine with a 32bit bus... 

On a Falcon though, reading a long takes twice the cycles for reading a word - and the d-cache only wants longs. So you read a word, and it fetches two. If you read consecutive words, then it doesn't do any harm since every 2nd word is fetched and then served by the cache. But if you read random words, then its reading 2x as much stuff from ram - not optimal.

OTOH, if you have a complex algorithm (like a depacker) which uses tables and dictionaries, and temporarily stuffs variables on the stack, the d-cache comes alive because it saves repeat access to the same longwords which the algorithm itself can't predict.

So it depends on the test - most benchmark tests are not complex, and don't re-read the same data (block copying of memory or basic arithmetic). So the d-cache won't be tested properly. 
*****

REPORTED BUGs - TOS401 - file selector box vanishes, likely only limited to TOS401 which I am unable to test.  (Thanks Atari030) 

***************************
GEMBENCH V606 B19 - ALPHA
***************************
Updated cache control code by dml.
Now using ASM code to pass timerC ticks which should improve accuracy. (99% score issues again)
Added FPU not found message
Fixed number of colours bug - thanks frank.lukas
Added fix to disable the menu during testing (thanks zogginghell)
Major recoding for the test / timer routines, now all done in assembly. 





***************************
GEMBENCH V606 B18 - ALPHA
***************************
Added sys_sleep routine by dml - should help solve those 99% score issues!
Changed timer routines so timer ticks are stored exactly with no x5 for seconds.
Fixed on screen results in seconds.
Fixed export test time in seconds.
Fixed busy bee not showing when saving defaults. 
Fixed TEST 2 text, was VDI TEST , not VDI TEXT
Fixed VDI text test 2 to 8px font (was same as VDI small text do'h!)
fixed VST EFFECTS bottom pixel clear problem (again)
Fixed VST TEXT alignment to top of window. 
Fixed VST text alignment to top of window
Removed un-necessary vst-alignment instruction
Increased VST TEXT font size
Fixed VST EFFECTS screen clear issue
Fixed VDI TEXT window not closing after test



***************************
GEMBENCH V606 B17 - ALPHA
***************************
Added timer sync routine by dml - should help solve those 99% score issues!



***************************
GEMBENCH V606 B16 - ALPHA
***************************
Fixed blitter test problem in hi-res (thanks atari030)
Fixed VDI scroll test problem in hi-res (thanks atari030)
Fixed window dimention calculation issues - now a window flashes up for a second on program load as it calculates window dimentions
      -this just saves on having to calculate window dimentions on every test and also saves on a lot of code
Added new asm routines by dml (thanks Doug!!)


***************************
GEMBENCH V606 B15 - ALPHA
***************************
Fixed background cleanup issue on first test 
Moved FUNCTIONS to top of code - changed FUNCTION's to DEF (attempted to solve darklords/atari030 cashing problems)
Fixed alt-ram detection routine for AlanH's MONSTER + future fixes for 68000 CPU
Fixed internal FPU detection for 060 CPU. 
Updated ASM routines by Rodolphe
Fixed TT/HADES CPU text issue (thanks zogginghell)
Added routines to clear keyboard buffers, disable keyboard events during FPU test.
Found bug where times on screen do not clear the background on 6 digit number, IE if 1000% was listed, then 100% after, it would show 100%%. so should be fixed now.
Graphics primitives time reduced by approx 50% (it took 90seconds on stock STFM!)
Fixed test times showing twice the length in seconds than they actually took. 
Fixed a bug where VST Effects tests would sometimes miss cleaning the bottom pixel line in the window clear. 



***************************
GEMBENCH V606 B14 - ALPHA
***************************
Fixed some minor colour problems in VDI test text.
Changed VSI effects to allow overflow of outline text
Added SAVE PI2 into MENU (not currently coded to do anything)
Added LOOP TEST into menu
End times of some tests was tweaked as it was including the time taken to close the test window. 
Blitter on/off change no longer refreshes the whole window.
Fixed bars not drawing when mouse is over them (thanks darklord)
Fixed Path problem when saving test files. 
Blitter test has been re-done as apparently here are issues with PUT&GET on some graphics cars (thanks Rajah Lone).
Fixed a bug where after saving default tests the main window would not update correctly. 
VDI TEXT test time reduced by about 50%
Fixed VDI lines test going off the edge of the window area
Integer Division recoded - now shows a more accurate 186% (195% in GB4)


***************************
GEMBENCH V605 B13- ALPHA
***************************
Fixed random crashes on ASM routines (buffer wasn't large enough)
Fixed window clear problem - Falcon TOS does not update the screen when AES calls are turned off :-\
GEM WINDOW test now shows the background colour when window closes( related to turning AES calls off)
Fixed vanishing window on "do all" question box
Fixed vanishing file selector boxes on Falcon
Fixed crash problem on exit on falcon
int-div test time increased
Fixed blitter NP message      (thanks Darklord)
Added more FPU support values 
-FPU code crashes on PAK030 and CT2 - to look into
Fixed some minor screen clipping issues.
Fixed double info window refresh when do all tests completes
Changed red box bars to fit inside the black dotted box border. 
Fixed load/save test path problem.

***************************
GEMBENCH V605 B12- ALPHA
***************************

V6 series is a total re-write of Gembench. 

The hisoft "HGK kit" has been totally removed.  There seemed to be some odd bugs which were not easy to solve as the HGK framework was so huge. While the framework makes functions easier to use, when it goes wrong, its impossible to de-bug. With so little information about how it all works, It just had to be removed. This made  a steep learning curve for learning how GEM/AES/VDI works, but in the long run it makes the new GB6 code a whole lot easier to maintain. 

All tests have been tweaked in some way. Mostly test times have increased to take into account fast boosters like the CT60.

Each test is clickable as before, and pressing "A" will run all tests, or can be selected from the menu. 

The blitter on/off has been simplified to one menu and with the addition of "system info" box it displays the current state of the system machine. 


NOTE - the blitter on/off does not work on the Falcon. This is NOT a bug. For some reason its impossible to turn off the blitter on the Falcon. So regardless of what you try and set the option as, it will always show as ON. 

Thanks go to Rodolphe Pineau for recoding RAM/ROM/INT-DIV/TT-RAM tests in assembly.  Rodolphe has also added routines so GB6 can access the instruction and data caches on later CPU models. These can also be changed in the menus. It is possible with caches on that results can vary about 2% depending on what data is "cached".

The TTRAM/ALT-RAM/FAST-RAM or whatever you want to call it, a test has been added to benchmark alt-ram. If alt-ram is not found, then no results will be displayed. 

The ROM test (actually the same test in GB5) was re-done as it wasn't accurate in GB4. 16mhz speeds showed almost zero increase in the tests. Now the ROM is read into CPU registers which makes the test generally show 170% on 16mhz speeds. 
 
Technically it should show 200%, but as the instructions are ran in ST-RAM, it slows the test loop down to 8mhz.  This results in a 30% speed drop in the test.  Running in alt-ram will effect the results.  Where 16mhz alt-ram and CPU should then show 200% speed for ROM access. Though if alt-ram is 32mhz and ROM 16mhz, then ROM access will likely show 30% higher as the instructions are ran at 32mhz. So total ROM speed would be 230%.  While this may seem complicated, it will explain to those why 16mhz ROM isn't showing 200% speeds. Technically it is, but 170% is as fast as any routine can go. 

GB6 has a new option in the file menu to benchmark your machine. This should only be used when your machine is in a "stock" condition.  For example, you could benchmark your stock STFM and that will then be used as your "stock referance". So all your scores will show 100%. Then when you enable a accelerator, you will then have a direct comparision to your own machine. 

Things like TOS versions can vary in speeds a few % and there is no guarantee that all STFM's run at exactly the same speed either. While I will provide some benchmark files of my own machines, they may not be 100% accurate for other machines. So you should always benchmark your own machine which then "calibrates" GB6 to your own machine.  


As people can benchmark their own machine, they can send me the benchmark files and I can include them in future releases of GB6.  

Quick people will notice "New dialogs" test has been removed. That test wasn't in GB3 even. The test was basically a repeat of the "GEM Dialog Box" only it used the HGK KIT's dialog functions. As nobody is likely ever going to program with the kit the whole test was pointless. More to the point, as the HGK kit was not used in GB6 the test couldn't be done anyway.  I found that using AES routines instead to do the test just made it a repeat test of "GEM Dialog Box" so in the end, "New Dialogs" test was taken out. In its place TTRAM test was added which is more useful. 


The menu system has been greatly simplified. The sub menu is gone along with all the odd icons which were hard to understand what they were all actually for. Both menus seemed to be a repeat of what was in other menus anyway. The basics are still there in the menus so really there shouldn't be anything "missing". 

The refereance and system info is now displayed on the main screen. It was mostly hidden away in a menu in GB4. This makes it a lot easier to see what your machine is being compared against. 

There is also a new "Comparison" box. This draws 3 bars based on the "Statistics" values. By default 100% scores will show a dotted area bar.  If your benchmark is 50% faster on the CPU for example, then the bar will be drawn with 50% solid black to indicate visually the speed increase.  Similar if you had 25% increase in speed, then it would show 75% dotted and 25% solid black. 

In reverse to this, if you benchmark a machine which is slower than the referance machine, they you can end up with negative values. A example would be benchmarking a STFM with a Falcon as the referance. All scores are going to show less than 100%. In which case the "drop" in speed is shown in RED. So if you are running 75% slower, then you will get a 75% RED bar and 25% dotted area. 





CURRENT BUGS
TTRAM TEST - crash on falcon with no TTRAM
First test done flashes the test on a closed window on falcon
CPU tests do not hide the main window.

Thanks go to all the people who helped me on the forum and helped with Beta testing of GB6. 

***************************
GEMBENCH V600-604  
***************************
Not Released


************************************
GEMBENCH V5 - exxos 2015 - OBSOLETE
************************************

Updates are to take out the registration stuff, so it runs as registered even without the registration files or typing in codes etc. There was some hidden features which I have enabled some. The main one which GB was crying out for was a loop test. So now you can select 1, 10, constant loop testing. So now you can leave GB cycling though all tests all day if you wish :)

Reference boxes were removed and defaults are loaded from a file instead. all the values in GB seemed to be hard coded and the blitter tests seemed to just assume its xx% faster than a stock machine. Overall none of the results were accurate. 

There have been a lot of bug fixes with various routines. Though as the code was so complex it proved impossible to reprogram it any further. So GB5 is abandoned.

A new ROM test was added - this is explained in GB6 info above. 

some more info on the forum
http://www.atari-forum.com/viewtopic.php?f=14&t=28116
 




******************************
GEMBENCH V4.03 - exxos build
******************************
Registration file was created so everyone can use the full registered version for free. GB4 source code was obtained thanks to Ofir Gal. 

More info on the forum
http://www.atari-forum.com/viewtopic.php?f=14&t=28099











******************************
BUGS / LIMITATIONS / FAQ
******************************


**** MULTITASKING ****

As for multitasking enviroments, its untested & not going to be supported. Really GB6 should be run on a vanilla machine as multitasking enviroments will effect the scores.  Similarly, GB6 should only be run in ST med-res.  While it will mostly run in ST HI-RES and even 16/256 colours on Falcon, GB6 wasn't designed to run in those resolutions. Different resolutions will vary the benchmark results to much and require even more benchmark files to cover every video mode for every machine. Overall its just too confusing. So any other resolutions then ST-MED running in anything but TOS is classed as unsupported. 

You also cannot drag the GB6 main window. It would need huge code changes and will otherwise complicate a lot of simple routines. The problem is, all the windows open up in the same place, so assumptions are made when each test is done. For example if you are in 640x200 an a window is full screen, then you have the height of the menu bar, which is about 12pixels, then about 18pixels for the window "drag/title bar" which can be 4 pixels more because of the 3D effect on the falcon. So I always assumed that about 28pixels from the top of the screen is where VDI text can be drawn.  Similar with the left side, mostly anything past 1 pixel on the left is OK in a window.  Though if the window opens up somewhere else or is moved, then it will screw up where the text is drawn.  You can't actually move a window and have its contents move with it, GEM unfortunately isn't that advanced and you have to recalculate all the locations manually and redraw them.

If you moved a window it would "pause" the test and probably timerC would still be running, so it would mess up the test in that respect. The test windows couldn't be moved anyway. That would involved more code checking if it had been moved to recalculate where stuff was drawn on the screen, that would seriously screw up the test times as its having to run more code to do the window checking stuff.  So one line to draw VDI text, then like 10 lines of code checking window locations, your not going to be benchmarking anything other than how fast the window calculations can be done. So every tests would just be benchmarking window location code, aka pointless even running the app as 90% of time would be taken up doing the same stuff each test.

Overall users shouldn't be using their machines when the tests are running anyway, moving the mouse can reduce  times by 30% easily. so they shouldn't be wanting to move windows about. Moreso, IMHO people shouldn't be benchmarking multitasking enviroments anyway, GB6 is geared up for testing hardware mods, not software. So a new benchmarking app would be better suited for multitasking (and no im not going to write one   )  So I think its official that gembench shouldn't be run in any multitasking environments.


**** COMPARISON BAR ****

This seems to be confusing everyone. The dotted area always reprisents 100% speeds. The black area shows the speed gain. 

If your benchmark is 50% faster on the CPU for example, then that bar will be drawn with 50% solid black to indicate visually the speed increase.  Similar if you had 25% increase in speed, then it would show 75% dotted and 25% solid black. 

In reverse to this, if you benchmark a machine which is slower than the referance machine, they you can end up with negative values. A example would be benchmarking a STFM with a Falcon as the referance. All scores are going to show less than 100%. In which case the "drop" in speed is shown in RED. So if you are running 75% slower, then you will get a 75% RED bar and 25% dotted area. 

I couldn't simple draw a bigger bar for higher speed, as what would be classed as maximum speed ? A 100mhz CT60 ?  If that was used for the bar to be drawn 100% in size, then the poor old ST series would likely only ever show 1 pixel line for its speed comparision.  Similar other machines may only show a couple of pixels and it would render the visual bar pretty pointless. 

After much pondering, I decided to just show the bar differently in a way which shows 2 results in 1 bar!  This way you can see easily the speed gain by just looking at the black bar size in comparison to the dotted bar, where the dotted bar always represents 100% speed. 


**** TEST SPEED DESCREPENCIES ****

People using GB4 will be confused as to why the results are different in GB6 for like tests. For example, I recoded the blitting test to give a "tougher" test on the blitter.  While copying around a black bar may have given 700%+ in GB4, Now it generally gives 600%+.  GB4 test copied a area left to right, then top to bottom. My test does both X and Y axis at the same time and copies a larger area box.  This makes the blitter work harder, so the overall test speeds are lower than in GB4.  Overall, you shouldn't compare results from GB4 to GB6 as GB6 has totally different test routines, even though the test look 99% identical to GB4. 


When you run GB6 in alt-ram the speeds will all (normally) be higher in speed.  While the ROM access time is 100% for 8mhz, in theory it should show 200% for 16mhz. Though because the test routine is normally run in ST-RAM, this is 8mhz. So while access to ROM is 16mhz, the code gets slowed down because its running from ST-RAM.  If for example alt-ram was 16mhz and ROM was 16mhz speeds, then in theory ROM access speed should then show 200% speed. However, in case of alt-ram on the CT60, ROM access can show 400%.  If we assumed for a moment that the Falcon has 16mhz access to TOS, then alt-ram runs at 66mhz, then we gain 200% speed (400% total) simple because the test routine now runs 4 times faster than the ROM access itself.   If ROM speed was also 66mhz, then we would probably show around 800% speeds. 

As you can see it gets very confusing as to why apparently ROM speed jumps in speed even though ROM itself is still running at stock speeds. In light of this, while GB6 supports being run from alt-ram. I would suggest it only be run in ST-RAM.  GB6 has a dedicated alt-ram test to test speeds so there shouldn't be much need to run GB6 in alt-ram anyway.  Similarly while atl-ram itself should show 100% speed, the test assumes it is run from ST-RAM. So alt-ram would shows higher than 100% speeds if the GB6 is ran from alt-ram as the test routine itself is now running faster.  You can of course calibrate GB6 for any hardware configuration so if ran from alt-ram you can calibrate your system to show 100% on all tests.


**** HARDWARE SPEED DESCREPANCIES ****

One thing to note is if you benchmark without a blitter, then benchmark with a blitter, the CPU tests will generally show 1% speed drop. This is normal since the CPU has extra work in programming the blitter.

I have also noticed while building the V2 series boosters that there also seems to be a variation in benchmark speeds which I have not been able to understand. After building up 5 V2 boosters, and testing in GB4, the results for integer division vary from 192%-196%.   I can only assume its tollerences in the various hardware itself.  Each booster is built with the same parts so they should all be identical, though it seems not.  It is also possible that a "cold" machine will benchmark different than one which has been turned on for some time.


**** FPU TEST NOT WORKING ****

FPU test now only tests the FPU if it is fitted. So if you benchmark a falcon with stock FPU @ 16mhz, it should show 100%. Then if its overclocked @50mhz, then it may so something around 150%.  

You also cannot compare IO mapped FPU's. After talking to dml we deciced not to support it. Basically as only custom software would use it anyway. This means "code overhead" which makes comparing a IO mapped FPU to a internal FPU like the 060 pointless. So only benchmark files such as the falcon with a 030 + FPU or 060 (internal FPU) are benchmarked and comparable to other machines.  You cannot for example compare a ST benchmark file to a falcon benchmark file and see a result on the FPU test, simply because there is nothing to compare a FPU to in the ST benchmarkign files. In such case the results will always show 0%. 

In GB3,4,5 the FPU routine was emulated and grossly inaccurate. As a ST showing FPU of 100%, then benchmarked with a FPU, the results would show something like 20,000% which is madness. When I ran the same number calculations on the CPU and FPU, the FPU code took 10 seconds, and 20mins later the CPU still had not finished calculating the numbers.  I talked to d.m.l about this, and even if the routine was programmed in assembly, it may only be 50% faster, so the CPU would still take 10mins to complete the test. Actually I gave up waiting after 20mins,  it could have been going for hours.. 

Obviously doing the FPU test on the CPU is not realistic.  In GB3,4,5 the FPU routine was likely done so the CPU would take 10 seconds. Then when a FPU was fitted, it would run thousands times faster and give a crazy ass results.   Its like trying to compare how long it takes to walk up a steep hill pushing a large boulder vs driving a ferrari.

So while the FPU test "no longer works" it really wasn't fair or accurate to compare number crunching on the CPU vs the FPU.  There are to many instructions needed to run on the CPU, at the end of it, the only thing its testing is RAM speed.  Then trying to compare RAM speed VS number cruncing on the FPU is just pointless.  So in order to correct this "bug" the FPU test only tests the actual FPU if it is fitted.  There is already a RAM speed test, so we don't need 2 tests giving the same results. 











