function [phV,grV] = run_mineos(model,swperiods,R_or_L,ID,ifdelete,ifplot,ifverbose)
% [phV,grV] = run_mineos(model,swperiods,R_or_L,ID,ifdelete,ifplot,ifverbose)
% 
% Function to run the MINEOS for a given model and extract the phase
% velocities at a bunch of input periods. If you keep the output files
% around (ifdelete==false) then they can be used to calculate perturbation
% kernels with the complementary run_kernelcalc.m script

tic
if nargin < 3 || isempty(R_or_L)
    R_or_L = 'R';
end
if nargin < 4 || isempty(ID)
    ID = 'eg';
end
if nargin < 5 || isempty(ifdelete)
    ifdelete = true;
end
if nargin < 6 || isempty(ifplot)
    ifplot = false;
end
if nargin < 7 || isempty(ifverbose)
    ifverbose = true;
end



%% filenames
if ~ischar(ID), ID = num2str(ID);end
ID = [ID,R_or_L(1)];
execfile = [ID,'.run_mineos'];
cardfile = [ID,'.model'];
eigfile = [ID,'.eig'];
ofile1 = [ID,'.asc1'];
qfile = [ID,'.q'];
logfile = [ID,'.log'];

% standard inputs, don't get re-written
switch R_or_L(1)
    case 'R'
        modefile = 'safekeeping/s.modefile.200mhz';
    case 'L'
        modefile = 'safekeeping/t.modefile.200mhz';
end
qmod= 'safekeeping/qmod';
%% =======================================================================
wd = pwd;
global MINEOSDIR
if isempty(MINEOSDIR)
    MINEOSDIR =  extractBefore(mfilename('fullpath'),mfilename);
end
cd(MINEOSDIR);


%% write MINEOS executable and input files format
if ischar(model) && exist(model,'file')==2
    cardfile = model;
    delcard = false;
else
    %% Radial anisotropy
    if ~isfield(model,'Sanis')
        model.Sanis = zeros(size(model.z));
    end
    if ~isfield(model,'Panis')
        model.Panis = zeros(size(model.z));
    end
    xi = 1 + model.Sanis/100;  % assumes Sanis is a percentage of anis about zero
    phi = 1 + model.Panis/100;  % assumes Panis is a percentage of anis about zero
    [ vsv,vsh ] = VsvVsh_from_VsXi( model.VS,xi );
    [ vpv,vph ] = VpvVph_from_VpPhi( model.VP,phi );

	write_cardfile(cardfile,model.z,vpv,vsv,model.rho,[],[],vph,vsh);
    delcard =true;
end

writeMINEOSexecfile( execfile,cardfile,modefile,qmod,eigfile,ofile1,qfile,logfile);
system(['chmod u+x ' execfile]);


%% do MINEOS on it
if ifverbose
    fprintf('    > Running MINEOS normal mode summation code. \n    > Will take some time...')
end
[status,cmdout] = system(['/opt/local/bin/gtimeout 100 ./',execfile]);
if ifverbose
     fprintf(' success!\n')
end
%% read modes output
if status~=124
    try
    [phV,grV] = readMINEOS_qfile(qfile,swperiods);
    catch
        error('some error - check model file layers not too thin!')        
    end
    phV = phV(:);
    grV = grV(:);
    if any(isnan(phV)) || any(isnan(grV))         
        if strcmp(R_or_L(1),'L'), copyfile(cardfile,['test_Love_pathology/fail_',cardfile]); end
        error('Some NaN data for %s',cardfile)
    else
        if strcmp(R_or_L(1),'L'), copyfile(cardfile,['test_Love_pathology/fine_',cardfile]); end
    end
else 
    error('MINEOS did not finish in 100s')
end
    


%% delete files
if ifdelete
    delete(execfile,eigfile,ofile1,qfile);
    if exist(logfile,'file')==2, delete(logfile); end
    if delcard, delete(cardfile); end
end
cd(wd);

%% plot
if ifplot
    figure(88), clf; set(gcf,'pos',[331 385 848 613]);
    ax1 = axes; hold on;
    % dispersion curves
    hd(1)=plot(ax1,swperiods,phV,'o-','linewidth',2);
    hd(2)=plot(ax1,swperiods,grV,'o-','linewidth',2);
    hl = legend(ax1,hd,{'Phase (c)','Group (U)'},'location','southeast');
    set(hl,'fontsize',16,'fontweight','bold')
    set(ax1,'fontsize',16)
    xlabel(ax1,'Period (s)','interpreter','latex','fontsize',22)
    ylabel(ax1,'Velocity (km/s)','interpreter','latex','fontsize',22)
end

if ifverbose
    fprintf('Mineos %s%s took %.5f s\n',ID,R_or_L(1),toc)
end
 