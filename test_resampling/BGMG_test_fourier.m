% Simulate bivariate associateion stats, given counts of potential causal SNPs across different LD r^2 bins

min_r2 = 0.05^2; nbins_r2 = 20;
%min_r2 = 0.1; nbins_r2 = 20; % Try higher minimum -- seems to reduce ringing / "foothills"
edges_r2 = [1 linspace(1,min_r2,nbins_r2)]; vals_r2 = (edges_r2(1:end-1)+edges_r2(2:end))/2;

%hist_r2 = zeros(size(vals_r2)); hist_r2(1) = 1;    % Assume perfect LD with all causal SNPs
%hist_r2 = zeros(size(vals_r2)); hist_r2(end) = 1;   % Assume same weak LD with all causal SNPs
hist_r2 = -diff(expcdf(sqrt(edges_r2)));             % Assume exponential decay of LD r, with uniform sampling of SNPs by position
hist_r2 = hist_r2 / sum(hist_r2);

nsnp = 100;
count_r2 = round(nsnp*hist_r2);

clear params
%params.pi_1 = 1e-4; params.pi_2 = 1e-4; params.pi_3 = 0; params.sigb_1 = 3.0; params.sigb_2 = 1.5; params.sig0_1 = 1; params.sig0_2 = 1; params.rhob = 0; params.rho0 = 0; % Low polygenisity for both
%params.pi_1 = 1e-2; params.pi_2 = 1e-2; params.pi_3 = 0; params.sigb_1 = 3.0; params.sigb_2 = 1.5; params.sig0_1 = 1; params.sig0_2 = 1; params.rhob = 0; params.rho0 = 0; % Uneven polygenisities
params.pi_1 = 1e-2; params.pi_2 = 1e-3; params.pi_3 = 1e-2; params.sigb_1 = 3.0; params.sigb_2 = 1.5; params.sig0_1 = 1; params.sig0_2 = 1; params.rhob = 0.7; params.rho0 = 0; % Including pleiotropic comp

delvals = linspace(-21,21,2^9+1); delstep = delvals(2)-delvals(1); 
tickvals = 5*[-10:10]; ticks = interp1(delvals,1:length(delvals),tickvals); tickvals = tickvals(isfinite(ticks)); ticks = ticks(isfinite(ticks));
if mod(length(delvals),2)~=0, delvals = delvals(1:end-1); end % Make sure there's an even number of zbins (for fft/fftshift)

% Generate synthesized / empirical stats
niter = 1000;
hc_z = 0; hc_total = 0; hc_indep = 0; hc_pleio = 0; 
tic;
then = now;
for iter = 1:niter
  [zmat delmat_total delmat_indep delmat_pleio] = BGMG_generate_random_stats(params,vals_r2,count_r2,1e6);
  hc_z = hc_z + hist3(zmat,{delvals delvals}); pdfmat_z_obs = hc_z/(sum(hc_z(:))*delstep^2);
  hc_total = hc_total + hist3(delmat_total,{delvals delvals});
  hc_indep = hc_indep + hist3(delmat_indep,{delvals delvals});
  hc_pleio = hc_pleio + hist3(delmat_pleio,{delvals delvals});
  fprintf(1,'iter = %d of %d (now:%s done:%s)\n',iter,niter,datestr(now,'HH:MM:SS'),datestr(then+(now-then)*niter/iter,'HH:MM:SS'));
end
toc;
pdfmat_total_obs = hc_total/(sum(hc_total(:))*delstep^2);
pdfmat_indep_obs = hc_indep/(sum(hc_indep(:))*delstep^2);
pdfmat_pleio_obs = hc_pleio/(sum(hc_pleio(:))*delstep^2);

% Compute predicted / theoretical PDFs
tic
[delvals_pred Fpdfmat_z Fpdfmat_total Fpdfmat_indep Fpdfmat_pleio pdfmat_z pdfmat_total pdfmat_indep pdfmat_pleio] = BGMG_predict_pdfs(params,vals_r2,count_r2,delvals);
toc

tickvals_pred = tickvals; ticks_pred = interp1(delvals_pred,1:length(delvals_pred),tickvals_pred,'linear','extrap');

figure(1); clf;  crange = [-5 2];
subplot(2,3,1); plot(delvals,log10(sum(pdfmat_indep_obs,2)),delvals_pred,log10(sum(pdfmat_indep,2)),'LineWidth',2); ylim(crange); xlim([delvals(1) delvals(end)]); title('Trait 1 Indep')
subplot(2,3,2); plot(delvals,log10(sum(pdfmat_pleio_obs,2)),delvals_pred,log10(sum(pdfmat_pleio,2)),'LineWidth',2); ylim(crange); xlim([delvals(1) delvals(end)]); title('Trait 1 Pleio')
subplot(2,3,3); plot(delvals,log10(sum(pdfmat_total_obs,2)),delvals_pred,log10(sum(pdfmat_total,2)),'LineWidth',2); ylim(crange); xlim([delvals(1) delvals(end)]); title('Trait 1 Total')
subplot(2,3,4); plot(delvals,log10(sum(pdfmat_indep_obs,1)),delvals_pred,log10(sum(pdfmat_indep,1)),'LineWidth',2); ylim(crange); xlim([delvals(1) delvals(end)]); title('Trait 2 Indep')
subplot(2,3,5); plot(delvals,log10(sum(pdfmat_pleio_obs,1)),delvals_pred,log10(sum(pdfmat_pleio,1)),'LineWidth',2); ylim(crange); xlim([delvals(1) delvals(end)]); title('Trait 2 Pleio')
subplot(2,3,6); plot(delvals,log10(sum(pdfmat_total_obs,1)),delvals_pred,log10(sum(pdfmat_total,1)),'LineWidth',2); ylim(crange); xlim([delvals(1) delvals(end)]); title('Trait 2 Total')
legend({'Simulated' 'Model'},'Location','NE');

figure(2); clf; cm = fire;
subplot(2,3,1); imagesc(log10(pdfmat_indep_obs),crange); axis equal tight xy; colormap(cm); set(gca,'XTick',ticks,'XTickLabel',tickvals,'YTick',ticks,'YTickLabel',tickvals); title('Indep Simulated');
subplot(2,3,2); imagesc(log10(pdfmat_pleio_obs),crange); axis equal tight xy; colormap(cm); set(gca,'XTick',ticks,'XTickLabel',tickvals,'YTick',ticks,'YTickLabel',tickvals); title('Pleio Simulated');
subplot(2,3,3); imagesc(log10(pdfmat_total_obs),crange); axis equal tight xy; colormap(cm); set(gca,'XTick',ticks,'XTickLabel',tickvals,'YTick',ticks,'YTickLabel',tickvals); title('Total Simulated');
subplot(2,3,4); imagesc(log10(pdfmat_indep),crange); axis equal tight xy; colormap(cm); set(gca,'XTick',ticks_pred,'XTickLabel',tickvals_pred,'YTick',ticks_pred,'YTickLabel',tickvals_pred); title('Indep Model');
subplot(2,3,5); imagesc(log10(pdfmat_pleio),crange); axis equal tight xy; colormap(cm); set(gca,'XTick',ticks_pred,'XTickLabel',tickvals_pred,'YTick',ticks_pred,'YTickLabel',tickvals_pred); title('Pleio Model');
subplot(2,3,6); imagesc(log10(pdfmat_total),crange); axis equal tight xy; colormap(cm); set(gca,'XTick',ticks_pred,'XTickLabel',tickvals_pred,'YTick',ticks_pred,'YTickLabel',tickvals_pred); title('Total Model');

[qqvec1_obs qqvec2_obs logpvals_qq zvals_qq] = BGMG_compute_qq(pdfmat_z_obs,delvals);
[qqvec1_pred qqvec2_pred logpvals_qq zvals_qq] = BGMG_compute_qq(pdfmat_z,delvals);

figure(11); plot(logpvals_qq,logpvals_qq,'k--',-log10(qqvec1_obs),logpvals_qq,-log10(qqvec1_pred),logpvals_qq,'LineWidth',2); xlim([0 6]);
h=title('Q-Q Plot Trait 1'); set(h,'FontSize',18);
h=ylabel(sprintf('Nominal -log_1_0(p)')); set(h,'FontSize',18);
h=xlabel(sprintf('Empirical -log_1_0(q)')); set(h,'FontSize',18);
h=legend({'Expected' 'Simulated' 'Model'},'Location','NW'); set(h,'FontSize',18);

figure(12); plot(logpvals_qq,logpvals_qq,'k--',-log10(qqvec2_obs),logpvals_qq,-log10(qqvec2_pred),logpvals_qq,'LineWidth',2); xlim([0 6]);
h=title('Q-Q Plot Trait 2'); set(h,'FontSize',18);
h=ylabel(sprintf('Nominal -log_1_0(p)')); set(h,'FontSize',18);
h=xlabel(sprintf('Empirical -log_1_0(q)')); set(h,'FontSize',18);
h=legend({'Expected' 'Simulated' 'Model'},'Location','NW'); set(h,'FontSize',18);

% ToDo
%   Compare against Dominic and Alex model predictions vs. sims
%   Write wrapper to compute annotation-weighted bivariate pdf by multiplying Fpdfmat_indep and Fpdfmat_pleio across annotation categories, each with own histogram, params
%   Look into better apodizing filter (minimizing sidelobes)

