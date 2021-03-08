%function [y1,y2]=extract_timepoints(x)

if length(argv()) > 0
  x = argv(){1};
else
  x = "";
endif
x
% x would be the source of the wav sound
% y1 would be start
% y2 would be the end

% load the signal package
pkg load signal

% read in the file 
[X, FS]=audioread(x); % X= samples FS=sampling frequency
%specgram(X)
[S, F, T] = specgram (X);
	% S is the complex output of the FFT, one row per slice
	% F is the frequency indices corresponding to the rows of S
	% T is the time indices corresponding to the columns of S.

% beeps are the starting point	
% beeps are F ~ 0.115
	%find(F <= 0.12 & F >=0.1) %column 16 =~ row 16  | 14 15 16
	%[r,c]=find(F <= 0.12 & F >=0.1)
S_beeps=[S(median(find(F <= 0.12 & F >=0.1)),:)];
%figure; plot(T,S_beeps);
beeps=S_beeps > 0.003;      % & S_beeps > 0.030  
%max(beeps)  % should be 1, otherwise use real(S_beeps)>0.003
beeps=[beeps;T];
%figure;  plot(beeps(2,:),beeps(1,:));

beep_start=[]
beep_end=[]
for i=2:length(beeps),
  if (beeps(1,i) == 1 && beeps(1,i-1) == 0);
  disp("beep start");
  beep_start=[beep_start, beeps(2,i)];
  elseif (beeps(1,i) == 0 && beeps(1,i-1) == 1);
  disp("beep end");
  beep_end=[beep_end, beeps(2,i)];
  end;
end;

% I resampled it to mono so I might need to multiply it again to have the seconds
% the bitrate for the wav file is: sample rate (FS) × sample size (X) × number of channels (2)
% which is why I will multiply it with 2 in one of the last steps
beep_start=beep_start/FS
beep_end=beep_end/FS

% check if the length of the sound is correct
remove=[];
for i=1:length(beep_start),
	dur=beep_end(i)-beep_start(i);
	disp(dur);
	if (dur<0.25 || dur > 0.35);
	remove=[remove, i];
	end;
end;

beep_start(remove)=[];
beep_end(remove)=[];

	

% blobs are F ~ 0.04
%find(F <= 0.045 & F >=0.035)  |6
S_blobs=[S(find(F <= 0.045 & F >=0.035),:)];
%figure; plot(T,S_blobs);
blobs=S_blobs > 0.001 ;
%max(blobs)
blobs=[blobs; T];
%figure;  plot(blobs(2,:),blobs(1,:));

blob_start=[]
blob_end=[]
for i=2:length(blobs),
  if (blobs(1,i) == 1 && blobs(1,i-1) == 0);
  %disp("blob start");
  blob_start=[blob_start, blobs(2,i)];
  elseif (blobs(1,i) == 0 && blobs(1,i-1) == 1);
  %disp("blob end");
  blob_end=[blob_end, blobs(2,i)];
  end;
end;
blob_start=blob_start/FS;
blob_end=blob_end/FS;

% check if the length of the sound is correct (blobs are longer)
remove=[];
for i=1:length(blob_start),
	dur=blob_end(i)-blob_start(i);
	%disp(dur);
	if (dur<0.68 || dur > 0.8);
	remove=[remove, i];
	end;
end;

blob_start(remove)=[];
blob_end(remove)=[];


% subtract the file name from the source to save things there
[filepath,name,ext]=fileparts(x)

%save 'filepath/beep_start.csv' beep_start 
%save 'filepath/beep_end.csv' beep_end 
output_precision(2)
save_precision(2)
beep_start=beep_start*2
beep_end=beep_end*2
%beep_start= round(beep_start .* 100) ./ 100
fileandpath=[filepath,'\beep_start.dat']
dlmwrite(fileandpath ,beep_start ,'delimiter',' ','precision','%10.4g');
%dlmwrite('F:/Output/beep_start.dat' ,beep_start ,'delimiter',' ','precision','%10.4g');
%save beep_start.dat beep_start -ascii 
fileandpath=[filepath,'\beep_end.dat']
dlmwrite(fileandpath ,beep_end ,'delimiter',' ','precision','%10.4g');
%save filepath/beep_end.dat beep_end -ascii

blob_start=blob_start*2
blob_end=blob_end*2
%blob_start= round(blob_start .* 100) ./ 100
fileandpath=[filepath,'\blob_start.dat']
dlmwrite(fileandpath ,blob_start ,'delimiter',' ','precision','%10.4g');
fileandpath=[filepath,'\blob_end.dat']
dlmwrite(fileandpath ,blob_end ,'delimiter',' ','precision','%10.4g');

%y1=beep_start';
%y2=blob_start';
%endfunction