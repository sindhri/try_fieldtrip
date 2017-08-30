function result = use_bf(j,eeg,mri,vol,grid,elec_realigned,foi,foilim)

[data_bsl,data_exp,data_cmb] = bf_get_data(eeg,1,j,elec_realigned);

%create frequency data

cfg=[];
cfg.method='mtmfft';
cfg.output='powandcsd';
cfg.tapsmofrq=4;
cfg.foilim=foilim;

freq_cmb = ft_freqanalysis(cfg,data_cmb);
freq_cmb.elec = data_cmb.elec;
freq_cmb.info = data_cmb.info;

freq_bsl = ft_freqanalysis(cfg,data_bsl);
freq_bsl.elec = data_bsl.elec;
freq_bsl.info = data_bsl.info;

freq_exp = ft_freqanalysis(cfg,data_exp);
freq_exp.elec = data_exp.elec;
freq_exp.info = data_exp.info;

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
source_cmb.info = freq_cmb.info;

cfg.grid.filter  = source_cmb.avg.filter;
source_bsl       = ft_sourceanalysis(cfg, freq_bsl);
source_exp       = ft_sourceanalysis(cfg, freq_exp);
source_diff = source_exp;
source_diff.avg.pow = (source_exp.avg.pow ./ source_bsl.avg.pow) - 1;
%ft_math


%interpret        
cfg              = [];
cfg.voxelcoord   = 'no';
cfg.parameter    = 'avg.pow';
cfg.interpmethod = 'nearest';
%template_mri = ft_read_mri('T1.nii');
source_diff_int  = ft_sourceinterpolate(cfg, source_diff, mri);

upper_limit = 1;
cfg               = [];     
cfg.method        = 'ortho';
cfg.funparameter  = 'pow';
cfg.maskparameter = cfg.funparameter;
cfg.funcolorlim   = [upper_limit/2 upper_limit];
cfg.opacitylim    = [upper_limit/2 upper_limit]; 
cfg.opacitymap    = 'rampup';  
source_diff_int.coordsys = mri.coordsys;
cfg.atlas = '/Users/wu/Documents/MATLAB/work/toolbox/fieldtrip/template/atlas/aal/ROI_MNI_V4.nii';
%ft_sourceplot(cfg,source_diff_int);

result.id = eeg.id;
result.category_name = eeg.category_names{j};
result.foi = foi;
result.foilim = foilim;
result.data_bsl = data_bsl;
result.data_exp = data_exp;
result.data_cmb = data_cmb;
result.freq_bsl = freq_bsl;
result.freq_exp = freq_exp;
result.freq_cmb = freq_cmb;
result.source_cmb = source_cmb;
result.source_diff = source_diff;
result.source_diff_int = source_diff_int;
result.cfg = cfg;

end