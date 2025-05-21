% ADC抗混叠低通IIR-Chebyshev II型滤波器设计与定点实现（Q2.22/24bit）
clear; close all; clc;
%% [1] 滤波器规格与主参数
Fs = 100e6;              % 采样率
Fp = 20e6;               % 通带截止
Fs1 = 25e6;              % 阻带起始
Rp = 1;                  % 通带波纹(dB)
Rs = 60;                 % 阻带衰减(dB)
Wpass = Fp/(Fs/2);       % 归一化通带
Wstop = Fs1/(Fs/2);      % 归一化阻带

% 定点格式（可选Q2.22, Q1.14等）
wl = 24; fl = 22;        % Q2.22
strict_margin = 0.93;    % 工程极点裕度

fprintf('>> 设计规格：采样率%.2fMHz，通带%.2fMHz，阻带%.2fMHz，Q%d_%d\n', ...
    Fs/1e6, Fp/1e6, Fs1/1e6, wl, fl);

%% [2] 滤波器最小阶数计算与设计
[N, Wn] = cheb2ord(Wpass, Wstop, Rp, Rs); % 自动最小阶
fprintf('>> Chebyshev II型最小阶数: %d\n', N);
[B, A] = cheby2(N, Rs, Wn, 'low');
[sos, g] = tf2sos(B, A);

%% [3] 按极点模值排序并均匀分配增益
sos_poles = cellfun(@(a) max(abs(roots([1 a(5:6)]))), num2cell(sos,2));
[~, idx] = sort(sos_poles, 'descend');
sos = sos(idx,:);

root_gain = g^(1/size(sos,1));
for i=1:size(sos,1)
    sos(i,1:3) = sos(i,1:3) * root_gain;
end

%% [4] 定点量化
scale = 2^fl;
sos_fixed = round(sos * scale) / scale;

%% [5] 稳定性验证
sysA = 1;
for i=1:size(sos_fixed,1)
    sysA = conv(sysA, [1, sos_fixed(i,5:6)]);
end
poles = roots(sysA);
maxpole = max(abs(poles));
is_stable = maxpole < strict_margin;

%% [6] 累计误差分析（单位阶跃响应累计误差）
[b1, a1] = sos2tf(sos_fixed, 1);
Nresp = 4096;
h = impz(b1, a1, Nresp);
step_resp = cumsum(h);
if any(isnan(step_resp)) || any(isinf(step_resp)) || ~is_stable
    accum_err = NaN;
    fprintf('>> 失稳，累计误差无意义。\n');
else
    accum_err = max(abs(step_resp));
    fprintf('>> 累计误差(单位阶跃): %.2e\n', accum_err);
end

%% [7] 脉冲响应与稳定时间估算
imp = [1; zeros(511,1)];
x = imp;
for k = 1:size(sos_fixed,1)
    b = sos_fixed(k,1:3);
    a = [1 sos_fixed(k,5:6)];
    x = filter(b, a, x);
end
resp = x;

thresh = 1e-3;       % 稳定阈值
min_hold = 10;       % 连续10点低于阈值才算稳定
abs_resp = abs(resp);
below = abs_resp < thresh;
stable_idx = find(movsum(below, min_hold) >= min_hold, 1);

if isempty(stable_idx)
    fprintf('>> 脉冲响应未在分析窗口内收敛到阈值。\n');
    stable_idx = NaN;
else
    fprintf('>> 脉冲响应稳定点（|幅值|<%.1e）: %d\n',thresh,stable_idx-1);
end

%% [8] 画图
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

%% [9] 输出关键信息到命令行
fprintf('\n=== ADC抗混叠低通IIR滤波器 Q2.22 ===\n');
fprintf('采样率: %.2f MHz\n', Fs/1e6);
fprintf('通带: %.2f MHz, 阻带: %.2f MHz\n', Fp/1e6, Fs1/1e6);
fprintf('类型: 切比雪夫II型 | 阶数: %d | 定点格式: Q2.22\n', N);
fprintf('极点最大值: %.5f | 是否稳定: %s\n', maxpole, string(is_stable));
fprintf('分段(SOS)数: %d\n', size(sos_fixed,1));
fprintf('累计误差: ');
if isnan(accum_err), fprintf('失稳/无意义\n');
else, fprintf('%.2e\n',accum_err); end
fprintf('Q2.22定点系数（已排序，每行：[b0 b1 b2 a1 a2]）：\n');
disp(sos_fixed(:,[1 2 3 5 6]));

%% [10] 以HEX格式输出到命令行（Verilog接口专用）
coeff_list = reshape(sos_fixed(:,[1 2 3 5 6])', [], 1);
coeff_int = int32(round(coeff_list * scale)); % Q2.22是24bit，int32覆盖
fprintf('Q2.22 HEX系数输出（顺序：[b0 b1 b2 a1 a2]，每行一组）：\n');
for i = 1:length(coeff_int)/5
    idx = (i-1)*5 + (1:5);
    % 6位大写，不带0x
    hexstrs = dec2hex(typecast(int32(coeff_int(idx)),'uint32'),6);
    fprintf('%s %s %s %s %s\n', hexstrs(1,:), hexstrs(2,:), hexstrs(3,:), hexstrs(4,:), hexstrs(5,:));
end

% 保存为iir_coeffs.hex
fid = fopen('iir_coeffs.hex','w');
for i = 1:length(coeff_int)
    hexstr = dec2hex(typecast(int32(coeff_int(i)),'uint32'),6);
    fprintf(fid, '%s\n', upper(hexstr));
end
fclose(fid);

save('adc_cheby2_iir.mat', 'sos_fixed', 'wl', 'fl', 'scale', 'N', 'maxpole', 'accum_err');

% ------ END ------