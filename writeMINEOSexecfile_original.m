function writeMINEOSexecfile( execfile,cardfile,modefile,qmod,eigfile,ofile1,qfile,logfile)
% writeMINEOSexecfile( execfile,cardfile,modefile,qmod,eigfile,ofile1,ofile2,logfile)
%   
% Function to write execution file for MINEOS code
% 
% INPUTS:
%  execfile  - name of execution file to write
%  cardfile  - name of card file with model description
%  modefile  - name of mode file (standard input)
%  qmod      - name of qmod file with details about (unused) Q model
%  eigfile   - name of eigenfunctions output binary file
%  ofile1    - name of output file 1 (just repeats input model)
%  qfile     - name of output q file, with Qs and group + phase velocities
%  logfile   - name of file to print screen output to



if exist(execfile,'file')==2
    delete(execfile); % kill if it is there 
end

%% write synth.in parameter file
fid = fopen(execfile,'w');
fprintf(fid,'#!/bin/csh\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'echo "Calculating eigenfunctions with MINEOS"\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'set xdir=/Users/zeilon/Work/codes/CADMINEOS/bin\n');
fprintf(fid,'$xdir/mineos_nohang << ! > %s\n',logfile);
fprintf(fid,'%s\n',cardfile);
fprintf(fid,'%s\n',ofile1);
fprintf(fid,'%s\n',eigfile);
fprintf(fid,'%s\n',modefile);
fprintf(fid,'!\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'echo "Done eigenfunctions"\n');
fprintf(fid,'echo "Q-correcting velocities"\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'$xdir/mineos_q << ! >> %s\n',logfile);
fprintf(fid,'%s\n',qmod);
fprintf(fid,'%s\n',qfile);
fprintf(fid,'%s\n',eigfile);
fprintf(fid,'\n');
fprintf(fid,'!\n');
%
fprintf(fid,'echo "Done velocity calculation, cleaning up..."\n');
%
% fprintf(fid,'rm synth.out3*\n');
fprintf(fid,'rm %s\n',logfile);

fclose(fid);

end




