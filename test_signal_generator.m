%% 高速定点IIR滤波器测试信号生成脚本
% 适用于80MHz采样、低通IIR（10MHz/15MHz），Q2.14
% 依赖opti_design.m导出的opti_filter.mat

close all; clc;

fprintf('==============================\n');
fprintf(' 高速IIR测试信号生成工具 v2025\n');
fprintf('==============================\n\n');

%% Step 1: 加载滤波器设计结果
fprintf('>> 步骤1: 加载滤波器数据\n');
if ~exist('opti_filter.mat', 'file')
    error('找不到opti_filter.mat，请先运行opti_design.m并加保存。');
end
load('opti_filter.mat', 'sos_fixed', 'wl', 'fl', 'scale');
fprintf('已加载 %d 阶SOS，Q%d.%d\n', size(sos_fixed,1), wl-fl-1, fl);

%% Step 2: 设置测试参数
Fs = 80e6;
num_samples = 2048;
t = (0:num_samples-1) / Fs;

% 典型低通频率点
f_pass1 = 6e6;    % 通带内
f_pass2 = 9e6;    % 通带边缘
f_stop1 = 16e6;   % 阻带内
f_stop2 = 32e6;   % 更高阻带

fprintf('采样率: %.2f MHz\n', Fs/1e6);
fprintf('样本数: %d\n', num_samples);

%% Step 3: 生成测试信号
test_signal = 0.2*( ...
    sin(2*pi*f_pass1*t) + ...
    sin(2*pi*f_pass2*t) ...
    ) ...
    + 0.15*( sin(2*pi*f_stop1*t) + sin(2*pi*f_stop2*t) ) ...
    + 0.01*randn(size(t));

% 避免溢出 [-0.95, 0.95]
max_amp = max(abs(test_signal));
if max_amp > 0.95
    test_signal = test_signal * (0.95/max_amp);
end

fprintf('测试信号频率: %.2f/%.2f MHz(通带)  %.2f/%.2f MHz(阻带)\n', ...
    f_pass1/1e6, f_pass2/1e6, f_stop1/1e6, f_stop2/1e6);
fprintf('信号最大幅度: %.3f\n', max(abs(test_signal)));

figure; plot(t(1:500)*1e6, test_signal(1:500)); grid on;
title('测试信号前500点'); xlabel('时间(μs)'); ylabel('幅值');

%% Step 4: 定点化
scale = 2^fl;
test_signal_fixed = round(test_signal * scale);
test_signal_fixed = max(min(test_signal_fixed, 2^(wl-1)-1), -2^(wl-1));
if any(abs(test_signal_fixed) >= 2^(wl-1))
    warning('定点数据有溢出！');
end
fprintf('定点化: Q%d.%d, 缩放因子%d\n', wl-fl-1, fl, scale);

%% Step 5: 定点转置二型滤波仿真（RTL一致结构）
ref_output = zeros(size(test_signal_fixed), 'int32');
states = zeros(size(sos_fixed,1),2, 'int32'); % s1,s2 per节
for n = 1:num_samples
    x = int32(test_signal_fixed(n));
    for s = 1:size(sos_fixed,1)
        b0 = int32(round(sos_fixed(s,1)*scale));
        b1 = int32(round(sos_fixed(s,2)*scale));
        b2 = int32(round(sos_fixed(s,3)*scale));
        a1 = int32(round(sos_fixed(s,4)*scale));
        a2 = int32(round(sos_fixed(s,5)*scale));
        % 转置二型核心
        y = b0*x + states(s,1);
        y = min(max(y, -2^31), 2^31-1); % 防溢出
        y_q = bitshift(y, -fl); % Q4.28->Q2.14
        y_q = min(max(y_q, -2^(wl-1)), 2^(wl-1)-1);
        s1_new = b1*x - a1*y_q + states(s,2);
        s1_new = min(max(s1_new, -2^31), 2^31-1);
        s2_new = b2*x - a2*y_q;
        s2_new = min(max(s2_new, -2^31), 2^31-1);
        states(s,1) = s1_new;
        states(s,2) = s2_new;
        x = y_q;
    end
    ref_output(n) = x;
end

%% Step 6: 保存HEX文件（16bit补码）
% 保存测试信号
fid = fopen('test_signal.hex','w');
for i = 1:num_samples
    v = test_signal_fixed(i);
    if v < 0, v = v + 2^wl; end
    fprintf(fid, '%04X\n', v);
end
fclose(fid);

% 保存参考输出
fid = fopen('reference_output.hex','w');
for i = 1:num_samples
    v = ref_output(i);
    if v < 0, v = v + 2^wl; end
    fprintf(fid, '%04X\n', v);
end
fclose(fid);

save('test_data.mat', 'test_signal', 'test_signal_fixed', 'ref_output', 't', 'Fs');

fprintf('已生成 test_signal.hex, reference_output.hex, test_data.mat\n');

%% Step 7: 可选摘要
fprintf('信号/输出统计:\n');
fprintf('  输入最大/最小: %.4f / %.4f\n', max(test_signal), min(test_signal));
fprintf('  参考最大/最小: %.4f / %.4f\n', max(ref_output/scale), min(ref_output/scale));