% =========================================================================
% test_signal_generator.m (适配新版伺服IIR设计，调试用正弦激励/HEX输入)
% =========================================================================
clear; close all; clc

%% === 加载最新版滤波器设计参数 ===
matfile = 'servo_iir_design.mat';   % 必须与设计脚本保存一致
if exist(matfile, 'file')
    load(matfile);                  % 变量: Fs, fl, sos_fixed 等
else
    error('找不到滤波器设计参数文件: %s，请先运行设计脚本生成！', matfile);
end

%% === 信号参数 (可调试) ===
N = 2048;           % 信号长度(缩小窗口，便于观测)
Fs = double(Fs);   % 采样率（Hz）
f_sin = 4e6;       % 正弦频率，建议设在通带内（如4MHz），阻带可试6~7MHz
phi = 0.3;           % 初相位

t = (0:N-1)' / Fs;
x = 0.5 * sin(2*pi*f_sin*t + phi);   % 幅度0.5，避免溢出

scale = 2^fl;      % Q2.22缩放，自动与设计参数一致
x_q22 = round(x * scale);
x_q22 = min(max(x_q22, -2^23), 2^23-1);  % 饱和到Q2.22范围
x_q22 = int32(x_q22)

%% === 保存HEX激励 ===
hexfile = 'test_signal.hex';
fid = fopen(hexfile, 'w');
for ii = 1:N
    val = double(x_q22(ii));
    if val < 0
        val = val + 2^24; % 负数转补码
    end
    fprintf(fid, '%06x\n', val);
end
fclose(fid);
fprintf('输入正弦已保存: %s, 频率: %.2f MHz\n', hexfile, f_sin/1e6);

%% === 可视化检查 ===
figure;
subplot(2,1,1); plot(t*1e6, x, 'b'); grid on;
xlabel('时间 (\mus)'); ylabel('幅度');
title(sprintf('输入正弦波, f=%.2f MHz', f_sin/1e6));
xlim([0, max(t)*1e6]); % 缩小窗口

subplot(2,1,2); plot(t*1e6, double(x_q22)/scale, 'r');
xlabel('时间 (\mus)'); ylabel('Q2.22定点值');
title('Q2.22定点激励信号');
xlim([0, max(t)*1e6]); % 缩小窗口