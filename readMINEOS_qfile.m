function [phV,grV] = readMINEOS_qfile(qfile,swperiods)
% [phV,grV] = readMINEOS_qfile(qfile,swperiods)
%  
%  Function to read MINEOS qfile file (qfile) with the fundamental mode
%  phase (and group) velocities listed by period, and then interpolate to
%  get velocities at the desired periods (swperiods).

fid = fopen(qfile,'r');
line=fgetl(fid); % read line with # of lines in q model
dum=str2num(line); %#ok<ST2NM>
nQline=dum(1); % will skip this many lines
C = textscan(fid,'%d %d %f %f %f %f %f','Headerlines',nQline); % n,l,omega,Q,?,c,U
fclose(fid);

l = C{2}; % mode degree
freq_all = C{3}/2/pi; % all the frequencies
Q = C{4}; % Q at each frequency
phV_all = C{6}; % phase velocity at each frequency
grV_all = C{7}; % group velocity at each frequency

% desired frequencies
freq_want = 1./swperiods;

% interpolate to get velocities
phV = interp1(freq_all,phV_all,freq_want);
grV = interp1(freq_all,grV_all,freq_want);


end

