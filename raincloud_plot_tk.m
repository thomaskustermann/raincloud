%% raincloud_plot - plots a combination of half-violin, boxplot,  and raw
% datapoints (1d scatter).
% Use as [h,leg] = raincloud_plot(X,varargin), where X is a data vector or a cell
% array (each containing one data series).
% Optional arguments (key-value):
% 'color': m x n matrix where where each row is one data set and columns represent R G B
%       values (default is "cbrewer('qual','Set3', No of Data Sets,'pchip'"). 
% 'density_type': either 'ks' or 'RASH' (default is 'ks', 2nd optionrequires Cyril
%       Pernet's robust statistics toolbox (which must be on the matlab path)
% 'box_on': 1 or 0 (plot box over raincloud, default = 1)
% 'alpha': transparency of distrubtions (default: 0.5)
% 'xlim': requested xlimits (defaults to data dependent selection)
% 'ylim': requested ylimits (defaults to data dependent selection)
% 'legend': 'on' or 'off'
% 'legend_label': cell-array of legend strings
% Based on https://micahallen.org/2018/03/15/introducing-raincloud-plots/
% Inspired by https://m.xkcd.com/1967/
% Written by Tom Marshall. www.tomrmarshall.com
% Thanks to Jacob Bellmund for some improvements

% X=dat.auc_cl_coef(strcmp(dat.grp_l,'survivors'))
% X={dat.auc_cl_coef(strcmp(dat.grp_l,'survivors')),dat.auc_cl_coef(strcmp(dat.grp_l,'non-survivors'))}


function [h,leg] = raincloud_plot_tk_test(X, varargin)%, density_type, box_on, ylim, xlim, alpha)

if ~iscell(X)
    X{1} = X;
end

cb = cbrewer('qual','Set3',numel(X),'pchip');
default_cl = cb(1:numel(X),:);
default_dens = 'ks';
default_box = 1;
default_alpha = 0.5;
default_xlim=[];
default_ylim=[];
default_leg='no';
default_leg_label=strcat(repmat('Data ',numel(X),1),cellstr(num2str([1:numel(X)]')));

p = inputParser;
addParameter(p,'color',default_cl,@isnumeric);
addParameter(p,'density_type',default_dens,@ischar);
addParameter(p,'box_on',default_box,@isnumeric);
addParameter(p,'alpha',default_alpha,@isnumeric);
addParameter(p,'xlim',default_xlim);
addParameter(p,'ylim',default_ylim);
addParameter(p,'legend',default_leg,@ischar);
addParameter(p,'legend_labels',default_leg_label);
parse(p,varargin{:});

cl = p.Results.color;
density_type=p.Results.density_type;
box_on = p.Results.box_on;
alpha = p.Results.alpha;
xlim = p.Results.xlim;
ylim = p.Results.ylim;
leg_plt=p.Results.legend;
leg_str = p.Results.legend_labels;

% calculate kernel density
switch density_type
    case 'ks'
        [f,Xi]=cellfun(@(x) ksdensity(x),X,'UniformOutput',false);
    case 'rash'
        try            
            [f,Xi]=cellfun(@(x) rst_RASH(x),X,'UniformOutput',false);
        catch
            disp('you''ve specified density_type = ''RASH'', but something''s gone wrong.')
            disp('Have you downloaded Cyril Pernet''s robust stats toolbox?');
        end
end

% density plot
for i = 1:numel(Xi)
    h{1}{i} = area(Xi{i}, f{i}); hold on
    set(h{1}{i}, 'FaceColor', cl(i,:));
    set(h{1}{i}, 'EdgeColor', [0.1 0.1 0.1]);
    set(h{1}{i}, 'LineWidth', 2);
    set(h{1}{i}, 'FaceAlpha', alpha);
end

% set xlim if defined
if ~isempty(xlim)
   set(gca, 'XLim', xlim)
end

% make some space under the density plot for the boxplot
if isempty(ylim)
    yl = get(gca, 'YLim');
    set(gca, 'YLim', [(-yl(2)*numel(X))/2 yl(2)]);
    yl = get(gca, 'YLim');
else
    set(gca, 'YLim', ylim);
    yl = get(gca, 'YLim');
end



% remove negative YTicks
gca_tmp = gca;
gca_tmp.YTick = gca_tmp.YTick(gca_tmp.YTick >= 0);


% width of boxplot
wdth = (yl(2)*0.5)/numel(X);

for i=1:numel(X)
    % jitter for raindrops
    jit{i} = (rand(size(X{i})) - 0.5) * wdth;
    % info for making boxplot
    Y{i} = quantile(X{i}, [0.25 0.75 0.5 0.02 0.98]);
end

% raindrops
ylim_div = yl(1)*-1/numel(X);
for i=1:numel(X)
    y_pos{i}=(yl(1)+ylim_div*i-ylim_div+ylim_div*0.5);
    h{2}{i} = scatter(X{i}, jit{i} + y_pos{i});
%     hold on
%     h{2}{i} = scatter(X{i}, jitX{i} - yl(2)/2);
    h{2}{i}.SizeData = 10;
    h{2}{i}.MarkerFaceColor = cl(i,:);
    h{2}{i}.MarkerEdgeColor = 'none';
end

if box_on
    for i = 1:numel(X)
        % 'box' of 'boxplot'
        h{3}{i} = rectangle('Position', [Y{i}(1) y_pos{i}(1)-(wdth*0.5) Y{i}(2)-Y{i}(1) wdth]);
        set(h{3}{i}, 'EdgeColor', 'k')
        set(h{3}{i}, 'LineWidth', 2);
        % could also set 'FaceColor' here as Micah does, but I prefer without
        
        % mean line
        h{4}{i} = line([Y{i}(3) Y{i}(3)], [y_pos{i}-(wdth*0.5) y_pos{i}+(wdth*0.5)], 'col', 'k', 'LineWidth', 2);
        
        % whiskers
        h{5}{i} = line([Y{i}(2) Y{i}(5)], [y_pos{i} y_pos{i}], 'col', 'k', 'LineWidth', 2);
        h{6}{i} = line([Y{i}(1) Y{i}(4)], [y_pos{i} y_pos{i}], 'col', 'k', 'LineWidth', 2);
    end
end

if strcmp(leg_plt,'on')
    leg = legend([h{1}{:}],leg_str);
end
