function result = use_bf_2cond(eeg,mri,vol,grid,elec_realigned,foi,...
foilim,toilim_bsl,toilim_exp)

[data_bsl1,data_exp1,data_cmb1] = bf_get_data(eeg,1,1,elec_realigned,...
    toilim_bsl,toilim_exp);
[data_bsl2,data_exp2,data_cmb2] = bf_get_data(eeg,1,2,elec_realigned,...
    toilim_bsl,toilim_exp);

cfg = [];
data_cmb = ft_appenddata(cfg, data_cmb1, data_cmb2);
%not sure whether it is right
data_cmb.trialinfo = [zeros(length(data_cmb2.trial), 1); ones(length(data_cmb2.trial), 1)];


%create frequency data

cfg=[];
cfg.method='mtmfft';
cfg.output='powandcsd';
cfg.tapsmofrq=4;
cfg.foilim=foilim;

freq_cmb = ft_freqanalysis(cfg,data_cmb);
freq_cmb.elec = data_cmb.elec;
%freq_cmb.info = data_cmb.info;

freq_bsl1 = ft_freqanalysis(cfg,data_bsl1);
freq_bsl1.elec = data_bsl1.elec;
%freq_bsl1.info = data_bsl1.info;

freq_exp1 = ft_freqanalysis(cfg,data_exp1);
freq_exp1.elec = data_exp1.elec;
%freq_exp1.info = data_exp1.info;


freq_bsl2 = ft_freqanalysis(cfg,data_bsl2);
freq_bsl2.elec = data_bsl2.elec;
%freq_bsl2.info = data_bsl2.info;

freq_exp2 = ft_freqanalysis(cfg,data_exp2);
freq_exp2.elec = data_exp2.elec;
%freq_exp2.info = data_exp2.info;

%source estimate
cfg              = []; 
cfg.method       = 'dics';
cfg.dics.keepfilter='yes';
cfg.frequency    = foi;  
cfg.grid         = grid; 
cfg.headmodel          = vol;
cfg.dics.projectnoise = 'yes';
cfg.dics.lambda       = 0;
source_cmb = ft_sourceanalysis(cfg, freq_cmb);
%source_cmb.info = freq_cmb.info;

cfg.grid.filter  = source_cmb.avg.filter;
source_bsl1       = ft_sourceanalysis(cfg, freq_bsl1);
source_exp1       = ft_sourceanalysis(cfg, freq_exp1);
source_bsl2       = ft_sourceanalysis(cfg, freq_bsl2);
source_exp2       = ft_sourceanalysis(cfg, freq_exp2);
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
result.foi = foi;
result.foilim = foilim;
result.toilim_bsl = toilim_bsl;
result.toilim_exp = toilim_exp;
result.source_cmb = source_cmb;
result.source_cond_diff = source_cond_diff;
result.source_cond_diff_int = source_cond_diff_int;
result.cfg = cfg;

end