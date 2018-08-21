function writeMINEOS_Qexecfile( execfile,eigfiles,qmod,qfile,logfile,n_eig_loop )
% writeMINEOS_Qexecfile( execfile,n_eig_loop,eigfiles,qmod,qfile,logfile )
%   
% Function to write execution file for MINEOS_Q function (to q-correct phase velocities)
% 
% INPUTS:
%  execfile  - name of execution file to write
%  n_eig_loop- number of eigenfunctions files (includes zeroth file)
%  eigfiles  - name(s) of eigenfunctions output binary files 
%                 can be several of these if the mineos calculation stopped
%                 multiple times before reaching its desired frequency
%  qmod      - name of qmod file with details about (unused) Q model
%  qfile     - name of output q file, with Qs and group + phase velocities
%  logfile   - name of file to print screen output to



if exist(execfile,'file')==2
    delete(execfile); % kill if it is there 
end

if nargin<6 || isempty(n_eig_loop)
    n_eig_loop = 1;
end

if isstring(eigfiles)
    eigfiles = {eigfiles};
end

%% write synth.in parameter file
fid = fopen(execfile,'w');
fprintf(fid,'#!/bin/csh\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'echo "Q-correcting velocities"\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'$xdir/mineos_q << ! >> %s\n',logfile);
fprintf(fid,'%s\n',qmod);
fprintf(fid,'%s\n',qfile);
for i = 1:n_eig_loop
    fprintf(fid,'%s\n',eigfiles{i});
end
fprintf(fid,'\n');
fprintf(fid,'!\n');
%
fprintf(fid,'echo "Done velocity calculation, cleaning up..."\n');
%
% fprintf(fid,'rm synth.out3*\n');
fprintf(fid,'rm %s\n',logfile);

fclose(fid);

end




