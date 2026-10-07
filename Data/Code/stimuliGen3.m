function [gaps, onsetTimes,stddev] = stimuliGen3(filepath,nameOut,targetIOI,type,stimDur, minStdDevSec, varargin)
%% Version 3 (added filtered noise to gaps instead of silence)
%% Creates rhythmic or arrhythmic stimuli from a sound file
% filepath      path to target sound
% nameOut       destination name for stimulus file
% stimDur       desired length of resulting stimulus, in s
% targetIOI     desired IOI, in s
% type          'reg', 'irreg', 'unevenplus', 'unevenminus'
% minStdDevSec  minimum gap std
% 
% Optional arguments:
% maxLoops      limits how many attempts the script will make to generate 
%               a set of intervals that match input parameters (default is
%               1000)
% count         fixes the number of sounds in the loop to a set number
% maxIOI        fixes the maximum IOI to specified ratio of input file length (default
%               is 1.5 times the target IOI)
%               OR set to 'gap' to have max IOI set to same interval as
%               target IOI - file length
% lengthFlex    allowable ratio range around stimDur that resulting stimulus can
%               be when using specific element count (default is 0.875, or
%               +/- 12.5%)
% noisePath     path to noise file (*.wav) for inserting noise between
%               elements (default is none, which means silence in gaps)
% exact         forces duration of irregular stimulus to be set to duration
%               of regular stimulus with same settings
% skip          adds randomly skipped elements
% 
% Calculations are done in samples to make gap length as precise as 
%   possible (and minimize rounding error from math)
% IOIs are calculated as length of sound + gap

maxLoops = 10000;
maxGenLoops = 5000000;
fixedSoundCount = 0;
maxIOIratio = 1.5;
fileLengthRange = 0.875;
gapNoise = 0;   % flag variable for using noise in gaps instead of silence
exactLength = 0;
skipElements = 0;
skipNumber = 0;

for v = 1:length(varargin)
    temp = varargin{v};
    if ischar(temp) && strcmpi(temp, 'maxLoops')
        maxLoops = varargin{v+1};
    elseif ischar(temp) && strcmpi(temp,'count')
        fixedSoundCount = varargin{v+1};
    elseif ischar(temp) && strcmpi(temp,'maxIOI')
        maxIOIratio = varargin{v+1};
    elseif ischar(temp) && strcmpi(temp,'lengthFlex')
        fileLengthRange = varargin{v+1};
    elseif ischar(temp) && strcmpi(temp,'exact')
        exactLength = 1;
    elseif ischar(temp) && strcmpi(temp,'noisePath')
        noisepath = varargin{v+1};
        gapNoise = 1;
    elseif ischar(temp) && strcmpi(temp,'skip')
        skipElements = 1;
        skipNumber = varargin{v+1};
    end
end

if gapNoise ==1
    % max number of loops defaults to 1000 if not defined
    [noisedata] = audioread(noisepath);
end 


[data,fs] = audioread(filepath);
n = 0; % number of tries
m = 0; % number rejected for average too far from target
p = 0; % number rejected for std dev too small
q = 0; % number rejected for incorrect element count

inputLength = length(data); % in samples
targetIOIsamp = round(targetIOI*fs); % target IOI, in samples

% Error catching
if targetIOIsamp < inputLength % target IOI is shorter than input file
    error('Error: Input file is longer than target IOI (input file is %3.4f s, target IOI is %3.4f s)\n',inputLength/fs,targetIOI);
end

if strcmpi(maxIOIratio,'gap')
    maxIOI = targetIOIsamp + (targetIOIsamp - inputLength);
else
    maxIOI = round(targetIOIsamp*maxIOIratio);
end

fileLengthRatio = abs(1-fileLengthRange);




meanRates = [];
stdevRates = [];
stimLength = stimDur*fs; % in samples

if exactLength == 1
    % based on length, how many sounds should the file contain?
    fixedSoundCount = floor(stimLength/targetIOIsamp);
end

% error catch if target duration, IOI, and element count are incompatible
if fixedSoundCount > 0
    idealLength = targetIOI*(fixedSoundCount);
    minFileLength = stimDur*(1-fileLengthRatio);
    maxFileLength = stimDur*(1+fileLengthRatio);
    
    if idealLength > maxFileLength
        error('Error: Specified element count (%i) at specified IOI (%g s) will produce a stimulus with a much longer duration than target length (%g s). \nProjected length: %g s\n',fixedSoundCount,targetIOI,stimDur,idealLength);
    elseif idealLength < minFileLength
        error('Error: Specified element count (%i) at specified IOI (%g s) will produce a stimulus with a much shorter duration than target length (%g s). \nProjected length: %g s\n',fixedSoundCount,targetIOI,stimDur,idealLength);
    end
end

maxDevSec = 0.05; %Max number of seconds average IOI of whole stimulus can deviate from target IOI
maxDeviation = maxDevSec*fs;
% minStdDevSec = 0.05; % Minimum standard deviation of IOIs of whole stimulus
minStdDev = minStdDevSec*fs;



if strcmpi(type,'reg')
    % Regularly-spaced intervals
    if fixedSoundCount > 0
        % Fixed element count
        intervals = [];
        elementCount = 0;
%         totalDur = fileLength; % set to start the file with a sound, so start time of first gap is at end of sound
        
        while elementCount < fixedSoundCount+1
            intervals(end+1) = targetIOIsamp; %#ok<*AGROW> %interval is length of sound + gap
%             totalDur = sum(intervals)+fileLength; %include last sound in total duration
            elementCount = length(intervals)+1;
        end
    else
        % no fixed element count
        intervals = [];
        %totalDur = fileLength; % set to start the file with a sound, so start time of first gap is at end of sound
        totalDur = 0;
        while totalDur < stimLength
            intervals(end+1) = targetIOIsamp;  %interval is length of sound + gap
            totalDur = sum(intervals)+inputLength; %include last sound in total duration
        end
        
    end
    meanIOI = mean(intervals); % For reporting in txt file
elseif strcmpi(type,'irreg')
    % irregular stimulus, variable gaps
    while n < maxLoops %loop until gaps meet criteria
        regDur = floor(stimLength/targetIOIsamp)*targetIOIsamp+inputLength;  % Length of isochronous version of stimulus
        totalDur = 0;
        intervals = [];
        if exactLength == 1
            x = 0;
            y = 0;
            while sum(intervals)+inputLength+1 < regDur || regDur < sum(intervals)+inputLength-1
            %while regDur ~= sum(intervals)+fileLength
                intervals = randi([inputLength,maxIOI],fixedSoundCount,1);
                if(sum(intervals)+inputLength) > regDur
                    y = y+1;
                else
                    x = x+1;
                end
                if x > maxGenLoops || y > maxGenLoops    %only let run 5000000 times
                    n = 1e10;
                    break
                end
                
            end
        elseif fixedSoundCount > 0
            intervals = randi([inputLength,maxIOI],fixedSoundCount,1);
        else
            % Generate one at a time because final n isn't known
            while totalDur < stimLength
                intervals(end+1) = inputLength+round(rand()*(maxIOI-inputLength)); %interval is length of sound + gap
                totalDur = sum(intervals)+inputLength; %include last sound in total duration
            end
        end
        
        % Validation
        meanIOI = mean(intervals);
        meanRates(end+1) = meanIOI;
        
        % nIntervals = length(intervals);
        stdDevIOI = std(intervals);
        stdevRates(end+1)=stdDevIOI;
        
        absDiff = abs(meanIOI-targetIOIsamp);
        
        if absDiff < maxDeviation   % check average tempo vs target
            if stdDevIOI > minStdDev    % check actual stdDev against target
                if fixedSoundCount > 0 && length(intervals) == fixedSoundCount  % check sound count vs target
                    break
                else
                    q = q+1; % reject for element count different from target number
                end
            else
                p = p+1;    % reject for stdDev too low
            end
        else
            m = m+1;    % reject for tempo too far from center
        end
        
        n = n+1;
        if floor(n/500) == n/500    % print update every 500 loops
            fprintf(' Loop %f, m = %f, p = %f, q = %f\n',n,m,p,q);
        end
    end
elseif strcmpi(type,'unevenplus') || strcmpi(type,'unevenminus')
    % Regularly-spaced intervals with every other twice as long
    if fixedSoundCount > 0
        % Fixed element count
        intervals = [];
        elementCount = 0;
%         totalDur = fileLength; % set to start the file with a sound, so start time of first gap is at end of sound
        
        while elementCount < fixedSoundCount+1
            if mod(elementCount,2) == 1
                intervals(end+1) = targetIOIsamp*2; %#ok<*AGROW> %Every other is double the length to make a silent third beat
            else
                intervals(end+1) = targetIOIsamp; %#ok<*AGROW> %interval is length of sound + gap
            end
            
%             totalDur = sum(intervals)+fileLength; %include last sound in total duration
            elementCount = length(intervals)+1;
        end
        
    else
        % no fixed element count
        intervals = [];
        elementCount = 0;
        
        totalDur = 0;
        while totalDur < stimLength
            if mod(elementCount,2) == 1
                intervals(end+1) = targetIOIsamp*2; %#ok<*AGROW> %Every other is double the length to make a silent third beat
            else
                intervals(end+1) = targetIOIsamp; %#ok<*AGROW> %interval is length of sound + gap
            end
            elementCount = length(intervals)+1;
            totalDur = sum(intervals)+inputLength; %include last sound in total duration
        end
        
    end
    meanIOI = mean(intervals)*2/3; % For reporting in txt file, multiplied by 2/3 to account for gaps
end

%% Make sound and data file
if n >= maxLoops     % nothing matched input criteria, so display error messages
    fprintf('%s \n',nameOut(end-16:end));
    fprintf('  %5.0f loops reached with no good sequences\n',n);
    fprintf('  %5.0f reject from stdDev\n',p);
    if p > maxLoops*.25
        fprintf('    Standard deviation too strict\n');
        fprintf('    Average std dev: %f\n', mean(stdevRates));
    end
    
    fprintf('  %5.0f reject from average\n',m);
    if m > .75*maxLoops
        fprintf('    Average not getting close often enough\n');
        fprintf('    Average mean rate: %f\n', mean(meanRates));
    end
    
    if exactLength == 1
        if n > 500000
            fprintf('  No sequence match\n');
            fprintf('    %i too long\n',y);
            fprintf('    %i too short\n',x);
        end
    end
    % Set outputs
    gaps = [];
    onsetTimes = [];
    stddev =[];
else
    %      if gapNoise == 1
    %          % Read noise file, get fft, make filter
    %          length_y=length(noisedata);
    %          NFFT = 2^nextpow2(length_y); % Next power of 2 from length of y
    %          fft_y=fft(noisedata,NFFT)/length_y;
    %          freqfft = noisefs/2*linspace(0,1,NFFT/2+1);
    %          noisefft = abs(fft_y(1:length(freqfft)));
    %          if mod(length(freqfft),2) == 1
    %              freqfft = freqfft(1:end-1); % truncate last point to make even length
    %              noisefft = noisefft(1:end-1); % truncate last point to make even length
    %          end
    %
    %          d = fdesign.arbmag('N,F,A',length(freqfft),freqfft./max(freqfft),noisefft);
    %          Hd = design(d,'freqsamp','SystemObject',true);
    %
    %      end
    %
    
    % set up array of skip flags
    skips = zeros(length(intervals),1);
    if skipElements == 1
        % https://www.mathworks.com/matlabcentral/answers/71181-how-to-generate-non-repeating-random-numbers-from-1-to-49
        skipIndices = randperm(length(intervals),skipNumber);
        fprintf('Sounds skipped:\n');
        fprintf('  %d\n',skipIndices);
        for i = skipIndices
            skips(i) = 1; 
        end
        
    end
    
    
    % start with first sound
    if strcmpi(type,'unevenplus') || strcmpi(type,'unevenminus')

    else
       wholeSound = data; 
    end
    for i = 1:length(intervals)
        
        gapLength = intervals(i)-inputLength;
        if gapNoise == 1
            % Generate background noise here
            %              noiseRaw = wgn(gapLength,1,0); % generate gaussian white noise of gap length
            %              noiseRawScale = noiseRaw./max(abs(noiseRaw)); % scale white noise to -1 to 1
            %              filteredNoise = step(Hd,noiseRawScale);
            %              release(Hd);
            %              gapSound = filteredNoise;
            noiseLength = length(noisedata);
            useChunk = 1;  % use a section of the noise file
            if gapLength > noiseLength-500
                %length of noise file is too small to get a random chunk of noise
                error('Desired length is too long for input file')
            else
                if useChunk == 1
                    noiseChunki = randi(noiseLength-gapLength); % get random starting point in input waveform
                    noiseChunk = noisedata(noiseChunki:noiseChunki+gapLength);
                    noisedataChunk = noiseChunk;
                end
                
                fftNoise = fftn(double(noisedataChunk));
                noiseSize = size(noisedataChunk);
                mag = real(fftNoise);
                phi= imag(fftNoise);
                
                env = max(abs(phi))/max(abs(smooth(abs(phi),.001,'loess')))*smooth(abs(phi),.001,'loess');
                
                randList = (rand(noiseSize(1),noiseSize(2))-0.5);
                
                %env = 0.5*ones(noiseSize(1),noiseSize(2)); % 0.5 is to cancel the doubling in next step
                
                randList = randList.*env;
                rand_phase= 4*pi*(randList./max(randList));
                newfft = mag.*exp(1i*rand_phase);
                gapSound = real(ifft2(newfft));
                gapSound = gapSound(1:end-1);
                %gapSound = gapSound.*(max(gapSound)/max(noisedata));
            end
        else
            % Silence between elements
            gapSound = zeros(gapLength,1);
        end
        
        % replace certain element with noise or silence
        if skips(i) == 1
            % get noise to replace sound element
            
            noiseChunki = randi(noiseLength-inputLength); % get random starting point in input waveform
            noiseChunk = noisedata(noiseChunki:noiseChunki+inputLength);
            noisedataChunk = noiseChunk;
            
            fftNoise = fftn(double(noisedataChunk));
            noiseSize = size(noisedataChunk);
            mag = real(fftNoise);
            phi= imag(fftNoise);
            
            env = max(abs(phi))/max(abs(smooth(abs(phi),.001,'loess')))*smooth(abs(phi),.001,'loess');
            
            randList = (rand(noiseSize(1),noiseSize(2))-0.5);
            
            %env = 0.5*ones(noiseSize(1),noiseSize(2)); % 0.5 is to cancel the doubling in next step
            
            randList = randList.*env;
            rand_phase= 4*pi*(randList./max(randList));
            newfft = mag.*exp(1i*rand_phase);
            gapSoundRep = real(ifft2(newfft));
            gapSoundRep = gapSoundRep(1:end-1);
            
            wholeSound = [wholeSound;gapSound;gapSoundRep];
        else
            if strcmpi(type,'unevenplus') 
                if mod(i,2) == 1
                    wholeSound = [wholeSound;gapSound;data];  % first sound
                else
                    % wholeSound = [wholeSound;gapSound;data];  % second sound
                end
            elseif strcmpi(type,'unevenminus')
                wholeSound = [wholeSound;gapSound;data];
            else
                wholeSound = [wholeSound;gapSound;data];
            end
            
        end
        
    end
    
    waveform = wholeSound;
    
    % Normalize waveform amplitude to 0.75
    maxAmp = max(abs(waveform));
    waveform = 0.75*waveform/maxAmp;
    
    
    %% Write wav file
    %make sure nameOut has extension
    [pathOut,fileOut,extOut] = fileparts(nameOut);
    if isempty(extOut)
        destPath = fullfile(pathOut,'Stim Files',[fileOut,'.wav']);
    else
        destPath = fullfile(pathOut,'Stim Files',[fileOut,extOut]);
    end
    audiowrite(destPath,waveform,fs);
    
    gaps = intervals/fs;
    onsetTimes = [];
    for j = 1:length(gaps)
        onsetTimes(end+1) = sum(gaps(1:j));
    end
    stddev = std(intervals);
    
    % Write txt with onset times and parameters
    textPath = fullfile(pathOut,'File Data',[fileOut,'.txt']);
    
    fileID = fopen(textPath,'w');
    % header
    fprintf(fileID,'Input file: %s\tStim Type: %s\tInput length: %i samples\tTarget IOI: %.4f s\tActual Avg IOI: %6.5f s (%6.5f samp)\r\n',filepath,type,inputLength,targetIOI,meanIOI/fs,meanIOI);
    fprintf(fileID,'Interval StdDev: %6.5f s (%6.5f samp)\tMax deviation: %1.4f s\tMin std dev: %1.4f s\r\n',stddev/fs,stddev,maxDevSec,minStdDevSec);
    % fprintf(fileID,'Gap Noise: %s\r\n\r\n',noisepath);
    fprintf(fileID,'Interval (samp)\tInterval (s)\tStart Time (s)\tSkipped?\r\n');
    for j = 1:length(gaps)
        fprintf(fileID,'%12d\t%5.8f\t%5.8f\t%1d\r\n',intervals(j),gaps(j),onsetTimes(j),skips(j));
    end
%     fprintf(fileID,'Skipped elements:\r\n\r\n');
%     for j = 1:length(gaps)
%         fprintf(fileID,'%12d\t%5.8f\t%5.8f\r\n',intervals(j),gaps(j),onsetTimes(j));
%     end
    fclose(fileID);
    
    fprintf('File created: %s\n', nameOut(end-15:end));
end
