:: set paths
set ffmpeg=C:\FFmpeg\bin\ffmpeg.exe

@echo off
echo Hi there, 
echo please make sure that the input files (max 2) have left and right in their name (e.g. left_raw.mp4)
SET base=%~dp0
SET initDir=%base%\Input
SET subID=
SET /P subID=What is the subjects acronym: %=%
SET /p BODY=Which body side was affected (left/right)?

IF DEFINED subID (
:: create folder structure
 echo creating folders for %subID% with the  %BODY% body side being affected
 MD %base%\temp
 MD %base%\Output\%subID%\raw
 MD %base%\Output\%subID%\processed\hand\left
 MD %base%\Output\%subID%\processed\hand\right
 MD %base%\Output\%subID%\processed\side\affected
 MD %base%\Output\%subID%\processed\side\non_affected

:: move input files to raw
 echo moving input files for %subID% to raw folder
 if exist %base%\Input\*left*.mp4 move %base%\Input\*left*.mp4 %base%\Output\%subID%\raw\left_raw.mp4
 if exist %base%\Input\*right*.mp4 move %base%\Input\*right*.mp4 %base%\Output\%subID%\raw\right_raw.mp4
 echo subjectID: %subID% > %base%\Output\%subID%\raw\info.txt
 echo affected body side: %BODY% >> %base%\Output\%subID%\raw\info.txt

:: copy raw files to respective subfolder
 if exist %base%\Output\%subID%\raw\left_raw.mp4 copy %base%\Output\%subID%\raw\left_raw.mp4 %base%\Output\%subID%\processed\hand\left\left_raw.mp4
 if exist %base%\Output\%subID%\raw\right_raw.mp4 copy %base%\Output\%subID%\raw\right_raw.mp4 %base%\Output\%subID%\processed\hand\right\right_raw.mp4

:: run ffmpeg to extract audio file 
 echo extracting the audio file from the video of the left hand
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\left\left_raw.mp4" -vn ^
	-acodec copy "%base%\Output\%subID%\processed\hand\left\left_audio.aac"
 echo extracting the audio file from the video of the right hand
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\right\right_raw.mp4" -vn ^
	-acodec copy "%base%\Output\%subID%\processed\hand\right\right_audio.aac"

:: filter audio
  echo the audio is being filtered (highpass 2000 and lowpass 900)
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\left\left_audio.aac" ^
	-af highpass=2000,lowpass=900 "%base%\Output\%subID%\processed\hand\left\left_audio_filtered.aac"
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\right\right_audio.aac" -af highpass=2000,lowpass=900 "%base%\Output\%subID%\processed\hand\right\right_audio_filtered.aac"
:: reject some frequency bands and make it a mono wav file
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\left\left_audio_filtered.aac" -af "bandreject=f=500:width_type=h:w=9999,bandreject=f=500:width_type=h:w=9999" -ac 1 "%base%\Output\%subID%\processed\hand\left\left_audio_filtered_bandreject.wav" -y
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\right\right_audio_filtered.aac" -af "bandreject=f=500:width_type=h:w=9999,bandreject=f=500:width_type=h:w=9999" -ac 1 "%base%\Output\%subID%\processed\hand\right\right_audio_filtered_bandreject.wav" -y
:: create spectrogram
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\left\left_audio.aac" ^
	-lavfi showspectrumpic=s=1024x1024 "%base%\Output\%subID%\processed\hand\left\left_audio_spectrogram.png" 
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\left\left_audio_filtered_bandreject.wav" ^
	-lavfi showspectrumpic=s=1024x1024 "%base%\Output\%subID%\processed\hand\left\left_audio_filt_bandrej_spectrogram.png" 
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\right\right_audio.aac" ^
	-lavfi showspectrumpic=s=1024x1024 "%base%\Output\%subID%\processed\hand\right\right_audio_spectrogram.png" 
	%ffmpeg% -y ^
	-hide_banner ^
	-i "%base%\Output\%subID%\processed\hand\right\right_audio_filtered_bandreject.wav" ^
	-lavfi showspectrumpic=s=1024x1024 "%base%\Output\%subID%\processed\hand\right\right_audio_filt_bandrej_spectrogram.png" 
echo processing the left hand
echo check out the spectrograms in the folder
::pause>nul
::timeout 5 > NUL

:: process further with octave | left hand
 echo continuing the processing with octave 
:: octave --persist extract_timepoints.m %base%\Output\%subID%\processed\hand\left\left_audio_filtered_bandreject.wav
start cmd /C octave --no-gui extract_timepoints.m %base%\Output\%subID%\processed\hand\left\left_audio_filtered_bandreject.wav

pause
:: this timeout is needed for octave to process and save the file for the commands below.
::timeout 5 > NUL
 :: these options work from commmand line 
   :: extract_timepoints('F:\Output\test005\processed\hand\right\right_audio_filtered_bandreject.wav').m
   :: octave extract_timepoints.m F:\Output\test005\processed\hand\right\right_audio_filtered_bandreject.wav

:: reading in data from octave | left
 echo reading in local files from octave
 setlocal enabledelayedexpansion 
 set /p start_times=<%base%\Output\%subID%\processed\hand\left\beep_start.dat
 set /p end_times=<%base%\Output\%subID%\processed\hand\left\blob_start.dat
 echo start times left hand: %start_times%
 echo end times left hand: %end_times%

:: checking the number of videos that are burried in one file | left
set /a counter_left=0
set /a coun=1
for %%a in (%start_times%) do (
   set /a counter_left+=1
 )
echo there are %counter_left% videos burried in the original

:: creating an array | left
set start_end=%start_times%%end_times%
echo %start_end%
set /a count=1
for %%b in (%start_end%) do (
   echo iteration !count!
   if !count! LEQ !counter_left! (
	 set start[!count!]=%%b
	 echo start loop,  current value %%b  
   ) else (
	 set /a coun=!count!-%counter_left%
	 set end[!coun!]=%%b
	 echo !coun!
	 echo end loop current value %%b 
	)
 set /a count+=1
)

:: just checking
:: echo start[1] 2.94: %start[1]%  
:: echo start[2] 12.37: %start[2]% 
:: echo start[3] 27.78: %start[3]% 
:: echo end[1] 7.08: %end[1]%
:: echo end[2] 15.69: %end[2]%
:: echo end[3] 29.91: %end[3]%

:: loop through arrays for cutting times & send the times to ffmpeg (https://github.com/mifi/lossless-cut/pull/13)
for /l %%n in (1,1,%counter_left%) do ( 
   echo iteration %%n, start: !start[%%n]! , end: !end[%%n]! asking ffmpeg to cut accordingly
	%ffmpeg% -y ^
	-hide_banner ^
	-noaccurate_seek ^
	-i "%base%\Output\%subID%\processed\hand\left\left_raw.mp4" ^
	-ss !start[%%n]! ^
	-to !end[%%n]! ^
	-avoid_negative_ts make_zero ^
	-c copy "%base%\Output\%subID%\processed\hand\left\left_cut_%%n.mp4"
)
:: clean up | remove many raw and subprocessed files | left (somehow I cannot delete the file in the subdirectory)

if exist %base%\Output\%subID%\processed\hand\left\left_raw.mp4 move %base%\Output\%subID%\processed\hand\left\left_raw.mp4  %base%\temp\left_raw.mp4
if exist %base%\Output\%subID%\processed\hand\left\left_audio_filtered.aac move %base%\Output\%subID%\processed\hand\left\left_audio_filtered.aac %base%\temp\left_audio_filtered.aac
if exist %base%\Output\%subID%\processed\hand\left\left_audio.aac move %base%\Output\%subID%\processed\hand\left\left_audio.aac %base%\temp\left_audio.aac

:: if exist "%base%\Output\%subID%\processed\hand\left\left_audio.aac" del /f "%base%\Output\%subID%\processed\hand\left\left_audio.aac"

echo processing the right hand
:: process further with octave | right hand
::octave --no-gui extract_timepoints.m %base%\Output\%subID%\processed\hand\right\right_audio_filtered_bandreject.wav
start cmd /C octave --no-gui extract_timepoints.m %base%\Output\%subID%\processed\hand\right\right_audio_filtered_bandreject.wav
pause
:: this timeout is needed for octave to process and save the file for the commands below.
::timeout 5 > NUL
:: reading in data from octave | right
 echo reading in local files from octave
 setlocal enabledelayedexpansion 
 set /p start_times=<%base%\Output\%subID%\processed\hand\right\beep_start.dat
 set /p end_times=<%base%\Output\%subID%\processed\hand\right\blob_start.dat
 echo start times: %start_times%
 echo end times: %end_times%

:: checking the number of videos that are burried in one file
set /a counter_right=0
set /a coun=1
for %%a in (%start_times%) do (
   set /a counter_right+=1
 )
echo there are %counter% videos burried in the original

:: creating an array
set start_end=%start_times%%end_times%
echo %start_end%
set /a count=1
for %%b in (%start_end%) do (
   echo iteration !count!
   if !count! LEQ !counter_right! (
	 set start[!count!]=%%b
	 echo start loop,  current value %%b  
   ) else (
	 set /a coun=!count!-%counter_right%
	 set end[!coun!]=%%b
	 echo !coun!
	 echo end loop current value %%b 
	)
 set /a count+=1
)

:: just checking
:: echo start[1] 2.94: %start[1]%  
:: echo start[2] 12.37: %start[2]% 
:: echo start[3] 27.78: %start[3]% 
:: echo end[1] 7.08: %end[1]%
:: echo end[2] 15.69: %end[2]%
:: echo end[3] 29.91: %end[3]%

:: loop through arrays for cutting times & send the times to ffmpeg (https://github.com/mifi/lossless-cut/pull/13)
for /l %%n in (1,1,%counter_right%) do ( 
   echo iteration %%n, start: !start[%%n]! , end: !end[%%n]! asking ffmpeg to cut accordingly
	%ffmpeg% -y ^
	-hide_banner ^
	-noaccurate_seek ^
	-i "%base%\Output\%subID%\processed\hand\right\right_raw.mp4" ^
	-ss !start[%%n]! ^
	-to !end[%%n]! ^
	-avoid_negative_ts make_zero ^
	-c copy "%base%\Output\%subID%\processed\hand\right\right_cut_%%n.mp4"
)

:: clean up | remove many raw and subprocessed files | right (somehow I cannot delete the file within the subdirectory)

if exist %base%\Output\%subID%\processed\hand\right\right_raw.mp4 move %base%\Output\%subID%\processed\hand\right\right_raw.mp4 %base%\temp\right_raw.mp4
if exist %base%\Output\%subID%\processed\hand\right\right_audio_filtered.aac move %base%\Output\%subID%\processed\hand\right\right_audio_filtered.aac %base%\temp\right_audio_filtered.aac
if exist %base%\Output\%subID%\processed\hand\right\right_audio.aac move %base%\Output\%subID%\processed\hand\right\right_audio.aac %base%\temp\right_audio.aac

::if exist %base%\Output\%subID%\processed\hand\right\right_raw.mp4 del /f %base%\Output\%subID%\processed\hand\right\right_raw.mp4
::if exist %base%\Output\%subID%\processed\hand\right\right_audio_filtered.aac del /F %base%\Output\%subID%\processed\hand\right\right_audio_filtered.aac
::if exist %base%\Output\%subID%\processed\hand\right\right_audio.aac del /f %base%\Output\%subID%\processed\hand\right\right_audio.aac

rmdir /s /q %base%\temp\
echo deleted the temporary folder

:: copy processed files from left right to affected non_affected according to BODY input
	IF "%BODY%"=="left" robocopy %base%\Output\%subID%\processed\hand\left %base%\Output\%subID%\processed\side\affected /E
	IF "%BODY%"=="left" robocopy %base%\Output\%subID%\processed\hand\right %base%\Output\%subID%\processed\side\non_affected /E
	IF "%BODY%"=="right" robocopy %base%\Output\%subID%\processed\hand\right %base%\Output\%subID%\processed\side\affected /E
	IF "%BODY%"=="right" robocopy %base%\Output\%subID%\processed\hand\left %base%\Output\%subID%\processed\side\non_affected /E



echo finished processing %subID%


)
echo finished processing 
echo I cut %counter_left% videos out of the original left video and
echo %counter_right% videos out of the original right video
echo thank you for your time - hope the results are as you wished  :)
pause
cls