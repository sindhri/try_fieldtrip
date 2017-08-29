addpath(genpath('/Users/wu/Documents/MATLAB/work/toolbox/eeglab14_0_0b/functions/'));
addpath('/Users/wu/Documents/MATLAB/work/toolbox/eeglab14_0_0b/');
addpath('/Users/wu/Documents/MATLAB/work/toolbox/fieldtrip/');
ft_defaults;
%an adolescent brain, then reconstruct vol, headmodel
mri = ft_read_mri('/Users/wu/Documents/MATLAB/work/toolbox/fieldtrip/template/headmodel/standard_mri.mat');
vol = ft_read_vol('/Users/wu/Documents/MATLAB/work/toolbox/fieldtrip/template/headmodel/standard_bem.mat');
load('/Users/wu/Documents/MATLAB/work/toolbox/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat');
load('elec_realigned.mat');
elec_realigned.label{132}='E129';
sourcemodel = ft_convert_units(sourcemodel,'mm');
%%check alignment
%figure;
%hold;
%ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.4;
%ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
%ft_plot_sens(elec_realigned, 'style', '*g');

baseline=700;
category_names={'lose','win'};
group_name = '';
id_type = 1;
net_type=1;

[~,pathname] = uigetfile('*.raw',pwd);
file_list = dir(pathname);
m = 1;
for i = 1:length(file_list)
    temp = file_list(i).name;
    if strcmp(temp(1),'.')~=1 && strcmp(temp(length(temp)-3:length(temp)),'.raw')
            filename_list{m} = temp;
            m = m + 1;
    end
end

foi = [3,7];
foilim = [3,30];
for i = 1:length(filename_list)
    filename = filename_list{i};
    eeg=ITC_read_egi_individual(category_names,baseline,...
        group_name,id_type,net_type,pathname,filename);
        for j = 1:length(category_names)
        %get only one condition from one subject
            result(i,j) = use_bf(j,eeg,mri,vol,sourcemodel,elec_realigned,foi,foilim);
        end
end

for i=1:size(result,1)
    for j = 1:size(result,2)
        cfg = result(i,j).cfg;
        source_diff_int = result(i,j).source_diff_int;
        ft_sourceplot(cfg,source_diff_int);
    end
end



