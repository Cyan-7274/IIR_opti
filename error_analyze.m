clear; close all; clc

N = 2048;
Fs = 80e6;

% ====== 数据加载（请根据实际路径调整） ======
fid = fopen('ref_output.hex','r');
y_ref_hex = textscan(fid, '%4s'); fclose(fid);
y_ref = hex2dec(char(y_ref_hex{1}));
y_ref(y_ref >= 2^15) = y_ref(y_ref >= 2^15) - 2^16;
y_ref = double(y_ref) / 2^14;

fid = fopen('D:\A_Hesper\IIRfilter\qts\tb\rtl_output.hex','r');
y_rtl_hex = textscan(fid, '%4s'); fclose(fid);
y_rtl = hex2dec(char(y_rtl_hex{1}));
y_rtl(y_rtl >= 2^15) = y_rtl(y_rtl >= 2^15) - 2^16;
y_rtl = double(y_rtl) / 2^14;

err = y_ref - y_rtl;
thresh = 1e-3;
rel_err = nan(size(err));
valid_idx = abs(y_ref) > thresh;
rel_err(valid_idx) = err(valid_idx) ./ abs(y_ref(valid_idx));
mask_idx = find(~valid_idx);

% ====== 自动获取y轴范围 ======
yrange1 = [min([y_ref; y_rtl]), max([y_ref; y_rtl])];
yrange2 = [0, max(abs(err))];
yrange3 = [-1, 1] * max(abs(rel_err(~isnan(rel_err)))) * 1.1 * 100; % 百分比

% ====== 作图 ======
figure('Name','RTL与Matlab定点输出与误差分析（x可缩放y固定）','Position',[100,80,1400,900]);
ax1 = subplot(3,1,1);
plot(y_ref,'b','LineWidth',1.2); hold on;
plot(y_rtl,'r--','LineWidth',1.2);
legend('Matlab定点','RTL','Location','Best');
title('IIR滤波器输出对比（全程）');
ylabel('幅度'); xlabel('采样点'); grid on;
ylim(yrange1);

ax2 = subplot(3,1,2);
plot(abs(err),'k','LineWidth',1.1);
title('Matlab输出 - RTL输出（绝对误差，全程）');
ylabel('绝对误差'); xlabel('采样点'); grid on;
ylim(yrange2);

ax3 = subplot(3,1,3);
plot(rel_err*100,'m','LineWidth',1.1); hold on;
if any(mask_idx)
    plot(mask_idx, zeros(size(mask_idx)), 'ro','MarkerSize',4);
end
title(sprintf('相对误差百分比（全程, Matlab输出<%.1e屏蔽）',thresh));
ylabel('相对误差(%%)'); xlabel('采样点'); grid on;
ylim(yrange3);

linkaxes([ax1 ax2 ax3],'x'); % x轴缩放同步

sgtitle('RTL与Matlab定点滤波器输出与误差分析（x自由缩放，y轴固定）');


% ====== 可选：自动锁定y轴范围回调（防止误操作时y轴被改动） ======
hZoom = zoom(gcf);
setAxesYLim = @(~,~) set([ax1 ax2 ax3],{'YLim'},{yrange1;yrange2;yrange3});
set(hZoom,'ActionPostCallback',setAxesYLim);
% 可选：同理加pan的回调
hPan = pan(gcf);
set(hPan,'ActionPostCallback',setAxesYLim);

