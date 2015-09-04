function [source,sourceInt,data,freq]=run_data_sample_sent(data_no_elec)

[elec,grid,vol,mri] = bf_config;

%check alignment
figure;
hold;
%ft_plot_mesh(vol.bnd(3),'facecolor','none'); %scalp
ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.4;
ft_plot_mesh(grid.pos(grid.inside,:));
ft_plot_sens(elec, 'style', '*g');


foilim = [4,30];
foi = [4,8];


data = data_no_elec;
data.elec = elec;
freq = bf_create_freq(data,foilim);
[source,sourceInt]= bf_source_int_write(foi,grid,vol,mri,freq,'output_elec_aligned');

end


%foilim: [4,30]
function freq = bf_create_freq(d,foilim)
cfg=[];
cfg.method='mtmfft';
cfg.output='powandcsd';
cfg.tapsmofrq=4;
cfg.foilim=foilim;

freq = ft_freqanalysis(cfg,d);
freq.elec = d.elec;
freq.info = d.info;
end

%foi: [4,8]
function [source, sourceInt] = bf_source_int_write(foi,grid,vol,mri,freq,filename)

%create source
cfg              = []; 
cfg.method       = 'dics';
cfg.frequency    = foi;  
cfg.grid         = grid; 
%cfg.vol          = vol;
cfg.headmodel = vol;
cfg.dics.projectnoise = 'yes';
cfg.dics.lambda       = 0;
source = ft_sourceanalysis(cfg, freq);
source.info = freq.info;

%interpolate
cfg            = [];
cfg.downsample = 2;
cfg.parameter = 'pow';
sourceInt  = ft_sourceinterpolate(cfg, source, mri);
sourceInt.info = source.info;

%write file
cfg=[];
cfg.filename  = filename;
cfg.filetype  = 'nifti';
cfg.parameter = 'pow';
ft_sourcewrite(cfg, sourceInt);

end

function [elec,grid,vol,mri] = bf_config()

%load mri
mri = ft_read_mri('Subject01/Subject01.mri');
%%mri = ft_volumereslice([], mri);

%cfg           = [];
%cfg.output    = {'brain','skull','scalp'};
%segmentedmri  = ft_volumesegment(cfg, mri);

%save segmentedmri segmentedmri;

%cfg=[];
%cfg.tissue={'brain','skull','scalp'};
%cfg.numvertices = [3000 2000 1000];
%bnd=ft_prepare_mesh(cfg,segmentedmri);

%save bnd bnd;

%cfg        = [];
%cfg.method ='dipoli';
%vol        = ft_prepare_headmodel(cfg, bnd);
%save vol vol;

load vol;

%get elec
%elec = ft_read_sens('fieldtrip/template/electrode/GSN-HydroCel-129.sfp');  
%elec.label{132}='E129';
%elec = align_elec2(elec,mri,vol);

load elec_aligned_manual;
elec.label{132}='E129';

%create grid
grid = create_grid(elec,vol);
grid = ft_convert_units(grid, 'mm');

end

function grid = create_grid(elec, vol)
cfg                 = [];
cfg.elec            = elec;
cfg.headmodel       = vol;
cfg.reducerank      = 1;
cfg.channel         = {'all','-FidNz','-FidT9','-FidT10'};
cfg.grid.resolution = 1;   % use a 3-D grid with a 1 cm resolution
%cfg.grid.resolution = 0.2;   % use a 3-D grid with a 1 cm resolution
cfg.grid.unit       = 'cm';
[grid] = ft_prepare_leadfield(cfg);
end
