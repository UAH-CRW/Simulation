function motor = getmotorbyname(name)
%Must populate Eng.thrustcurve with properties:
%   - thrustcurve: nx2 matrix, with times (s) in the first column and thrust
%   (N) in the second
%   - minitial: wet motor mass (kg)
%   - mfinal: post-burn motor mass (kg)
%   - burntime: motor burn time (s)
engsuffix = '';
if ~endsWith(name, '.eng')
    engsuffix = '.eng';
end
fileloc = fullfile('Motors', strcat(name, engsuffix));

%https://www.mathworks.com/matlabcentral/answers/71374-how-to-read-a-text-file-line-by-line
fid = fopen(fileloc);
line = 'dummy data';

data = [];
motor = [];
while 1
    line = fgetl(fid);
    if ~ischar(line)
        break;
    end
    line = strtrim(string(line));
    chartypes = isstrprop(line, 'alpha');
    if startsWith(line, ';')
        continue;
    elseif chartypes(1)
        %parse metadata
        meta = strsplit(line);
        if length(meta) >= 6 %Required data is present
            motor.minitial = str2double(meta{6});
            motor.mprop = str2double(meta{5});
            motor.mfinal = motor.minitial - motor.mprop;
        end
        continue;
    else
        row = cell2mat(textscan(line, '%f %f'));
        if isempty(data)
            data = row;
        else
            data = [data; row];
        end
    end
end
fclose(fid);
motor.thrustcurve = data;
motor.burntime = data(end, 1); %Last time in the data
end