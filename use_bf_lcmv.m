%just source
%no oscillation

function result = use_bf_lcmv(eeg,mri,vol,grid,elec_realigned,...
    toilim_bsl,toilim_exp)

[data_bsl1,data_exp1,data_cmb1] = bf_get_data(eeg,1,1,elec_realigned,...
    toilim_bsl,toilim_exp);
[data_bsl2,data_exp2,data_cmb2] = bf_get_data(eeg,1,2,elec_realigned,...
    toilim_bsl,toilim_exp);

cfg = [];
data_cmb = ft_appenddata(cfg, data_cmb1, data_cmb2);
%not sure whether it is right
data_cmb.trialinfo = [ones(length(data_bsl1.trial), 1);...
    ones(length(data_exp1.trial), 1)+1;...
    ones(length(data_bsl2.trial), 1)+2;...
    ones(length(data_exp2.trial), 1)+3];


cfg                  = [];
cfg.covariance       = 'yes';
cfg.covariancewindow = 'all';
cfg.vartrllength     = 2;
timelock_cmb             = ft_timelockanalysis(cfg, data_cmb);

cfg                  = [];
cfg.covariance       = 'yes';
cfg.covariancewindow = 'all';
cfg.vartrllength     = 2;
timelock_bsl1             = ft_timelockanalysis(cfg, data_bsl1);

cfg                  = [];
cfg.covariance       = 'yes';
cfg.covariancewindow = 'all';
cfg.vartrllength     = 2;
timelock_exp1            = ft_timelockanalysis(cfg, data_exp1);

cfg                  = [];
cfg.covariance       = 'yes';
cfg.covariancewindow = 'all';
cfg.vartrllength     = 2;
timelock_bsl2             = ft_timelockanalysis(cfg, data_bsl2);

cfg                  = [];
cfg.covariance       = 'yes';
cfg.covariancewindow = 'all';
cfg.vartrllength     = 2;
timelock_exp2             = ft_timelockanalysis(cfg, data_exp2);


% create spatial filter using the lcmv beamformer
cfg                  = [];
cfg.method           = 'lcmv';
cfg.grid             = grid; % leadfield, which has the grid information
cfg.vol              = vol; % volume conduction model (headmodel)
cfg.keepfilter       = 'yes';
cfg.lcmv.fixedori    = 'yes'; % project on axis of most variance using SVD
source_cmb           = ft_sourceanalysis(cfg, timelock_cmb);

cfg.grid.filter  = source_cmb.avg.filter;
source_bsl1       = ft_sourceanalysis(cfg, timelock_bsl1);
source_exp1       = ft_sourceanalysis(cfg, timelock_exp1);
source_bsl2       = ft_sourceanalysis(cfg, timelock_bsl2);
source_exp2       = ft_sourceanalysis(cfg, timelock_exp2);
source_diff1 = source_exp1;
source_diff1.avg.pow = (source_exp1.avg.pow ./ source_bsl1.avg.pow) - 1;
source_diff2 = source_exp2;
source_diff2.avg.pow = (source_exp2.avg.pow ./ source_bsl2.avg.pow) - 1;
source_cond_diff = source_exp2;
source_cond_diff.avg.pow = (source_exp1.avg.pow ./ source_exp2.avg.pow) - 1;

%interpret        
cfg              = [];
cfg.voxelcoord   = 'no';
cfg.parameter    = 'avg.pow';
cfg.interpmethod = 'nearest';
%template_mri = ft_read_mri('T1.nii');
source_cond_diff_int  = ft_sourceinterpolate(cfg, source_cond_diff, mri);

upper_limit = 1;
cfg               = [];     
cfg.method        = 'ortho';
cfg.funparameter  = 'pow';
cfg.maskparameter = cfg.funparameter;
cfg.funcolorlim   = [upper_limit/2 upper_limit];
cfg.opacitylim    = [upper_limit/2 upper_limit]; 
cfg.opacitymap    = 'rampup';  
source_cond_diff_int.coordsys = mri.coordsys;
cfg.atlas = '/Users/wu/Documents/MATLAB/work/toolbox/fieldtrip/template/atlas/aal/ROI_MNI_V4.nii';
%ft_sourceplot(cfg,source_diff_int);

result.id = eeg.id;
result.category_name = eeg.category_names;
result.source_cond_diff = source_cond_diff;
result.source_cond_diff_int = source_cond_diff_int;
result.cfg = cfg;

end