clear all;

% Parameters used as example

% Mitral: "SA_MitralVolunteer.mp4"
% Papilary: "SA_PapilaryVolunteer.mp4"
% Apex: "SA_ApexVolunteer.mp4"
% Apical: "Apical4chVolunteer.mp4"

% Frame number
% Mitral: ED = 29; ES = 41
% Papilary: ED = 34; ES = 46
% Apex: ED = 36; ES = 48
% Apical: ED = 33; ES = 42

%% Main routine
% Ask users enter the video file names
% uncomment them if you want to input the video file names manually

% Input the video file names
% disp(" ") % Separation Line
% disp(strcat("Please enter the video name including ' ", '""', " '!"));
% disp("(They must be .mp4 files!)");
% disp(" ") % Separation Line
% 
% video_name_mitral = input("Please enter the video name of mitral: ");
% video_name_papilary = input("Please enter the video name of papilary: ");
% video_name_apex = input("Please enter the video name of apex: ");
% video_name_apical = input("Please enter the video name of apical: ");

% Delete four lines codes below and uncomment the codes above if you want to input other video file names
video_name_mitral = "SA_MitralVolunteer.mp4";
video_name_papilary = "SA_PapilaryVolunteer.mp4";
video_name_apex = "SA_ApexVolunteer.mp4";
video_name_apical = "Apical4chVolunteer.mp4";

% Cast the function to calculate stroke volume
[SV, EDV, ESV, EF, CO] = STROKE_VOLUME(video_name_mitral, video_name_papilary, video_name_apex, video_name_apical);

% Display the results
disp(" ");
disp(strcat("The stroke volume is ", string(SV)));
disp(strcat("The end diastolic volume is ", string(EDV)));
disp(strcat("The end systolic volume is ", string(ESV)));
disp(strcat("The ejection fraction is ", string(EF)));
disp(strcat("The cardiac output is ", string(CO)));

%% Function
function [SV, EDV, ESV, EF, CO] = STROKE_VOLUME(video_name_mitral, video_name_papilary, video_name_apex, video_name_apical)

    % Import video files
    mitral = VideoReader(video_name_mitral);
    papilary = VideoReader(video_name_papilary);
    apex = VideoReader(video_name_apex);
    apical = VideoReader(video_name_apical);
    
    videofiles = {mitral, papilary, apex, apical};
    
    % Frame Names
    filenames = {};
    muscle_names = {'Mitral', 'Papilary','Apex', 'Apical'};
    state_names = {' (ED)', ' (ES)'};
    st = '.jpg';
    for m = 1 : 4
        for n = 1 : 2
            filenames{end + 1} = strcat(muscle_names{m}, state_names{n}, st);
        end
    end
    
    
    % Read video files
    vid_list = cell(1, 4);
    
    for i = 1 : length(videofiles)
        vid_list{i} = read(videofiles{i});
    end
    
    
    
    % Extract and save the ED and ES frames in a certain fold
    mkdir extract_frames
    cd extract_frames
   
    % Input frame numbers
    framenums = zeros(4,2);
    disp(" ") % Separation Line
    for i = 1: 4
        for j = 1 : 2
            if(mod(j, 2)==0)
                framenums(i,j) = input(strcat("Please enter the end-systole frame for ", muscle_names{i},": "));
            else
                framenums(i,j) = input(strcat("Please enter the end-diastole frame for ", muscle_names{i} ,": "));
            end
        end
    end
    
    % Save certain frames
    numfilename = 0;
    for n = 1 : length(vid_list)
        for m = 1 : 2
            numfilename = numfilename + 1;
            Vid = vid_list{n}(:,:,:,framenums(n, m));
            imwrite(Vid, string(filenames{numfilename}));
        end
    end
    
    SCALER = 24; % Scaler, converting pixels to centimeters
    
    % Choose ED and ES
    distance = zeros(1, 8);
    for z = 1 : length(filenames)
        imshow(imread(string(filenames{z})));
        coor = ginput(2);
        distance(z) = sqrt((coor(1,1) - coor(2,1))^2 + (coor(1,2) - coor(2,2))^2) / SCALER;
    end
    close all;  

    cd .. 
      
    % Calculate SV, EDV, ESV
    D = distance(1:6); % Short axis (ED & ES)
    L = distance(7:8); % Long axis (ED & ES)
    
    A = zeros(1,6); % Area
    for i = 1 : 6  
        A(i) = (pi * D(i) ^ 2) / 4;
    end
    
    % End Diastolic Volume
    EDV = (A(1) + A(3)) * L(1) / 3 + A(5) * L(1) / 6 + pi * (L(1)/3)^3 / 6;
    
    % End Systolic Volume
    ESV = (A(2) + A(4)) * L(2) / 3 + A(6) * L(2) / 6 + pi * (L(2)/3)^3 / 6;
    
    SV = EDV - ESV; % Stroke Volume
    EF = SV / EDV; % Ejection Fraction
    HR = 60; % Heart Rate
    CO = SV * HR; % Cardiac Output
end