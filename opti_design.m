% =========================================================================
% opti_design.m (增强版)
% Chebyshev II型8阶 | Q2.22 Verilog工程定点设计
% =========================================================================
clear; close all; clc;

%% [1] 设计参数
Fs = 80e6; Fp = 15e6; Fs1 = 20e6; Rp = 0.5; Rs = 50;
Wpass = Fp/(Fs/2); Wstop = Fs1/(Fs/2);
wl = 24; fl = 22;
strict_margin = 0.93;

fprintf('>> 工程场景：ADC抗混叠低通 | 采样率%.2fMHz | 通带%.2fMHz | 阻带%.2fMHz | Q%d_%d\n', Fs/1e6, Fp/1e6, Fs1/1e6, wl, fl);

%% [2] Chebyshev II型设计
[N, Wn] = cheb2ord(Wpass, Wstop, Rp, Rs);
fprintf('>> Chebyshev II型理论最小阶: %d\n', N);
[B, A] = cheby2(N, Rs, Wn, 'low');
[sos, g] = tf2sos(B, A);

% 极点模排序+均匀分配增益
sos_poles = cellfun(@(a) max(abs(roots([1 a(5:6)]))), num2cell(sos,2));
[~, idx] = sort(sos_poles, 'descend');
sos = sos(idx,:);
root_gain = g^(1/size(sos,1));
for i=1:size(sos,1), sos(i,1:3) = sos(i,1:3)*root_gain; end

%% [3] 定点量化
scale = 2^fl;
sos_fixed = round(sos * scale) / scale;

% 增加：定点系数与浮点的误差统计
coef_err = max(abs(sos(:) - sos_fixed(:)));
fprintf('>> 定点系数最大量化误差: %.3e\n', coef_err);

%% [4] 稳定性与累计误差
sysA = 1;
for i=1:size(sos_fixed,1), sysA = conv(sysA, [1, sos_fixed(i,5:6)]); end
poles = roots(sysA); maxpole = max(abs(poles));
is_stable = maxpole < strict_margin;

[b1, a1] = sos2tf(sos_fixed, 1);
Nresp = 4096; h = impz(b1, a1, Nresp); step_resp = cumsum(h);
if any(isnan(step_resp))||any(isinf(step_resp))||~is_stable
    accum_err = NaN;
    fprintf('>> 失稳，累计误差无意义。\n');
else
    accum_err = max(abs(step_resp));
    fprintf('>> 累计误差(单位阶跃): %.2e\n', accum_err);
end

%% [5] 脉冲响应与稳定时间估算
imp = [1; zeros(511,1)];
x = imp;
for k = 1:size(sos_fixed,1)
    b = sos_fixed(k,1:3);
    a = [1 sos_fixed(k,5:6)];
    x = filter(b, a, x);
end
resp = x;

thresh = 1e-3; min_hold = 10;
abs_resp = abs(resp);
below = abs_resp < thresh;
stable_idx = find(movsum(below, min_hold) >= min_hold, 1);
if isempty(stable_idx)
    fprintf('>> 脉冲响应未在分析窗口内收敛到阈值。\n');
    stable_idx = NaN;
else
    fprintf('>> 脉冲响应稳定点（|幅值|<%.1e）: %d\n',thresh,stable_idx-1);
end

%% [6] 画图（同原版）

figure('Name','滤波器响应分析');
subplot(2,2,1);
[H, f] = freqz(sos_fixed, 1024, Fs);
plot(f/1e6, 20*log10(abs(H))); grid on;
xlabel('频率 (MHz)'); ylabel('幅度 (dB)'); title('幅频响应');
subplot(2,2,2);
plot(f/1e6, unwrap(angle(H))*180/pi); grid on;
xlabel('频率 (MHz)'); ylabel('相位 (°)'); title('相频响应');
subplot(2,2,3);
grpdelay(sos_fixed, 1024, Fs);
xlabel('频率 (MHz)'); ylabel('群时延 (点)'); title('群延迟');
subplot(2,2,4);
zplane(sos_fixed(:,1:3), [ones(size(sos_fixed,1),1) sos_fixed(:,4:5)]);
title('零极点图');

figure('Name','单位脉冲响应');
stem(0:length(resp)-1, resp, 'filled');
if ~isnan(stable_idx)
    hold on; xline(stable_idx-1, 'r--', sprintf('稳定点%d',stable_idx-1));
    hold off;
end
xlabel('采样点'); ylabel('幅度'); title('单位脉冲响应（含稳定时间标注）'); grid on;

%% [7] 工程信息输出（同原版）

fprintf('\n=== ADC抗混叠低通IIR滤波器 Q2.22 工程实现 ===\n');
fprintf('采样率: %.2f MHz\n', Fs/1e6);
fprintf('通带: %.2f MHz, 阻带: %.2f MHz\n', Fp/1e6, Fs1/1e6);
fprintf('类型: Chebyshev II | 阶数: %d | 定点格式: Q2.22\n', N);
fprintf('极点最大值: %.5f | 是否稳定: %s\n', maxpole, string(is_stable));
fprintf('分段(SOS)数: %d\n', size(sos_fixed,1));
fprintf('累计误差: ');
if isnan(accum_err), fprintf('失稳/无意义\n');
else, fprintf('%.2e\n',accum_err); end
fprintf('Q2.22定点系数（已排序，每行：[b0 b1 b2 a1 a2]）：\n');
disp(sos_fixed(:,[1 2 3 5 6]));

%% [8] HEX输出
coeff_list = reshape(sos_fixed(:,[1 2 3 5 6])', [], 1);
coeff_int = int32(round(coeff_list * scale)); % Q2.22有符号补码
fprintf('Q2.22 HEX系数输出（顺序：[b0 b1 b2 a1 a2]，每行一组）：\n');
num_group = length(coeff_int)/5;
for i = 1:num_group
    idx = (i-1)*5 + (1:5);
    for k = 1:5
        hex_str = upper(dec2hex(bitand(typecast(int32(coeff_int(idx(k))), 'uint32'), hex2dec('FFFFFF')), 6));
        hex_arr{k} = hex_str;
    end
    fprintf('%s %s %s %s %s\n', hex_arr{1}, hex_arr{2}, hex_arr{3}, hex_arr{4}, hex_arr{5});
end

fid = fopen('iir_coeffs.hex','w');
for i = 1:length(coeff_int)
    hex_str = upper(dec2hex(bitand(typecast(int32(coeff_int(i)), 'uint32'), hex2dec('FFFFFF')), 6));
    fprintf(fid, '%s\n', hex_str);
end
fclose(fid);

save('adc_cheby2_iir.mat', 'sos_fixed', 'wl', 'fl', 'scale', 'N', 'maxpole', 'accum_err');

% ------ END ------