clear all
%% Options
ifverbose = false; % verbose output so we see what's going on
ifplot = false;    % make some helpful plots
ifdelete = true; % don't delete the files at the end - you may want to see what they are!
ifsave = false;

ID = 'PREM';
R_or_L = 'R';
phV_or_grV = 'ph';

swperiods = [20; 50; 100; 200];

zmax = 450;


%% grab PREM model
premmod = prem_perfect('SPVW',0.5,'ocean',false);
% write card file
write_cardfile( 'PREM_cardfile',....
                    premmod.depth,...
                    premmod.vpv,...
                    premmod.vsv,...
                    premmod.rho,...
                    premmod.qk,...
                    premmod.qu,...
                    premmod.vph,...
                    premmod.vsh,...
                    premmod.eta);

%% Do mineos
% Rayleigh waves, and phase velocity kernels
par_mineos = struct('R_or_L',R_or_L,'phV_or_grV',phV_or_grV,'ID',ID);

[phV_R1,grV_R1,eigfiles] = run_mineos('PREM_cardfile',swperiods,par_mineos,0,ifplot,ifverbose);
[K_R1] = run_kernels(swperiods,par_mineos,eigfiles,ifdelete,ifplot,ifverbose);

%% plot
figure(44); clf
subplot(131);hold on
plot(premmod.rho,premmod.depth,'g','linewidth',2)
plot(premmod.vsv,premmod.depth,'r','linewidth',2)
plot(premmod.vsh,premmod.depth,'r--','linewidth',2)
plot(premmod.vpv,premmod.depth,'b','linewidth',2)
plot(premmod.vph,premmod.depth,'b--','linewidth',2)
set(gca,'ydir','reverse','ylim',[0 zmax],'box','on','layer','top','fontsize',15,'linewidth',2);

subplot(132);hold on
for ip = 1:length(swperiods)
plot(K_R1{ip}.Vsv   ,K_R1{1}.Z/1000,'linewidth',2,'color',colour_get(ip,length(swperiods),0,winter))
end
set(gca,'ydir','reverse','ylim',[0 zmax],'box','on','layer','top','fontsize',15,'linewidth',2);


subplot(133);hold on
for ip = 1:length(swperiods)
plot(K_R1{ip}.Vpv   ,K_R1{1}.Z/1000,'linewidth',2,'color',colour_get(ip,length(swperiods),0,winter))
end
set(gca,'ydir','reverse','ylim',[0 zmax],'box','on','layer','top','fontsize',15,'linewidth',2);

if ifsave
    save2pdf(44,'PREM_example') % note - might break if you don't have this "save2pdf" function; use exportfig or whatever. 
end
