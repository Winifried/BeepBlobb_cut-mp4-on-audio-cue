# BeepBlobb
Cut video (mp4) on recorded audio cue

This code was originally created to retrospectively cut videos to the same length as simultaneously acquired kinematic recordings (Vicon motion capture system 3D). The original recording-start sound "capture started" was replaced by a "beep" and the original recording-stop stound "capture completed" was replaced by a "blobb" sound. After setting up additional cameras which captured the motion of the individual (here: left and right arm seperately) the bat script (windows) can retrospectively cut the video into the correct single trial files. For best results, it is important to have the sound of the vicon system close to the capturing camera. Or you can use different sounds, depending on the sound spectrum in the recording room. 

This is what the .bat file does: <br>
0 searches the input folder for up to 2 mp4s which have left or right in their name (e.g. left_raw.mp4) <br>
1 Checks the subject ID and the affected body side and creates a folder structure <br>
2 moves the input files to a new folder <br>
3 ffmpeg: extracts the audio file from the video, filters it (highpass 2000 & lowpass 900), creates a spectrogram  <br>
4 octave: extracts start and end times from spectrogram and saves them to file <br>
5 ffmpeg: cuts the video respective to time from latter file <br>

requires: ffmpeg, octave, Input and Outputfolder
