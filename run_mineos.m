function [phV,grV,eigfiles_fix] = run_mineos(model,swperiods,R_or_L,ID,ifdelete,ifplot,ifverbose)
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

l_increment_standard = 2;
l_increment_failed = 5;



%% filenames
if ~ischar(ID), ID = num2str(ID);end
ID = [ID,R_or_L(1)];
cardfile = [ID,'.model'];

switch R_or_L(1)
    case 'R'
        modetype = 'S';
    case 'L'
        modetype = 'T';
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
    delcard = true;
end

% count lines in cardfile
[ model_info ] = read_cardfile( cardfile );
skiplines = model_info.nlay + 6;

% compute max frequency (mHz)
fmax = 1000./min(swperiods)+0.1;
fmax = 200.05;
%% do MINEOS on it
if ifverbose
    fprintf('    > Running MINEOS normal mode summation code. \n    > Will take some time...')
end

%% Run mineos once by default
lrun = 0; lrunstr = num2str(lrun);

execfile = [ID,'_',lrunstr,'.run_mineos'];
ascfile =  [ID,'_',lrunstr,'.asc'];
eigfile =  [ID,'_',lrunstr,'.eig'];
modefile = [ID,'_',lrunstr,'.mode'];

writeMINEOSmodefile( modefile, modetype,[],[],[],fmax )
writeMINEOSexecfile( execfile,cardfile,modefile,eigfile,ascfile,[ID,'.log']);

system(['chmod u+x ' execfile]); % change execfile permissions
[status,cmdout] = system(['/opt/local/bin/gtimeout 100 ./',execfile]); % run execfile

delete(execfile,modefile); % kill files we don't need

% read prelim output
[~,llast,lfirst,Tmin] = readMINEOS_ascfile(ascfile,0,skiplines);
 
ascfiles = {ascfile};
eigfiles = {eigfile};
llasts = llast; lrunstrs = {lrunstr};


%% Re-start iteratively on higher modes if necessary
% Tmin = max(swperiods);
while Tmin > min(swperiods)

lrun = lrun + 1; lrunstr = num2str(lrun);
lmin = llast + l_increment_standard;

if ifverbose
    fprintf('\n        %4u modes done, failed after mode %u... restarting at %u',max(round(llast-lfirst+1)),llast,lmin)
end

execfile = [ID,'_',lrunstr,'.run_mineos'];
ascfile =  [ID,'_',lrunstr,'.asc'];
eigfile =  [ID,'_',lrunstr,'.eig'];
modefile = [ID,'_',lrunstr,'.mode'];

writeMINEOSmodefile( modefile, modetype,lmin,[],[],fmax )
writeMINEOSexecfile( execfile,cardfile,modefile,eigfile,ascfile,[ID,'.log']);

system(['chmod u+x ' execfile]); % change execfile permissions
[status,cmdout] = system(['/opt/local/bin/gtimeout 100 ./',execfile]); % run execfile

delete(execfile,modefile); % kill files we don't need

% read asc output
[~,llast,lfirst,Tmin] = readMINEOS_ascfile(ascfile,0,skiplines);

if isempty(llast) % what if that run produced nothing?
    llast=lmin + l_increment_failed;
    Tmin = max(swperiods);
    lfirst = llast+1;
    delete(ascfile,eigfile); % kill files we don't need
    continue
end

% save eigfiles and ascfiles for stitching together later
ascfiles{length(ascfiles)+1} = ascfile;
eigfiles{length(eigfiles)+1} = eigfile;
llasts(length(eigfiles)) = llast;
lrunstrs{length(eigfiles)} = lrunstr;

end % on while not reached low period

if ifplot
    readMINEOS_ascfile(ascfiles,ifplot,skiplines);
end

if ifverbose
     fprintf(' success!\n')
end

%% Do eig_file fixing
eigfiles_fix = eigfiles;
for ief = 1:length(eigfiles)-1
    execfile = [ID,'_',lrunstrs{ief},'.eig_recover'];
    writeMINEOSeig_recover( execfile,eigfiles{ief},llasts(ief) )
    
    system(['chmod u+x ' execfile]); % change execfile permissions
    [status,cmdout] = system(['/opt/local/bin/gtimeout 100 ./',execfile]); % run execfile
    
    eigfiles_fix{ief} = [eigfiles{ief},'_fix'];
    delete(execfile);
end

%% Do Q-correction
qexecfile = [ID,'.run_mineosq'];
writeMINEOS_Qexecfile( qexecfile,eigfiles_fix,qmod,[ID,'.q'],[ID,'.log'] )

system(['chmod u+x ' qexecfile]); % change qexecfile permissions
[status,cmdout] = system(['/opt/local/bin/gtimeout 100 ./',qexecfile]); % run qexecfile

delete(qexecfile);

%% Read phase and group velocities
try
    [phV,grV] = readMINEOS_qfile([ID,'.q'],swperiods);
catch
    error('some error with extracting phV and grV from q-file')        
end
  
phV = phV(:);
grV = grV(:);
if any(isnan(phV)) || any(isnan(grV))         
	error('Some NaN data for %s',cardfile)
end

%% delete files
if ifdelete
    delete([ID,'_*.asc'])
    delete([ID,'.q'])
    delete([ID,'_*.eig'])
    delete([ID,'_*.eig_fix'])
    if exist([ID,'.log'],'file')==2, delete([ID,'.log']); end
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
 