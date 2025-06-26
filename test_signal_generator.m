% =========================================================================
% test_signal_generator.m (适配Q2.14输入，便于RTL对齐，多频激励/阻带分析)
% =========================================================================
clear; close all; clc

%% === 加载滤波器设计参数 ===
matfile = 'opti_design.mat';   % 必须与设计脚本保存一致
if exist(matfile, 'file')
    load(matfile);                  % 变量: Fs, fl, sos_fixed 等
else
    error('找不到滤波器设计参数文件: %s，请先运行设计脚本生成！', matfile);
end

%% === 信号参数 (可调试) ===
N = 2048;           % 信号长度
Fs = double(Fs);    % 采样率（Hz）

% === 激励频率设置 ===
f_pass = 12e6;   % 通带内
f_stop = 27e6;   % 阻带内
f_mix = [f_pass, f_stop];   % 组合信号

phi = 0.3;       % 初相位
amp = 0.5;       % 单频幅度，防止溢出
t = (0:N-1)' / Fs;

% === 组合信号生成 ===
x = zeros(N,1);
for k = 1:length(f_mix)
    x = x + amp * sin(2*pi*f_mix(k)*t + phi*k);
end
x = x / max(abs(x)) * 0.5;  % 保证峰值不过0.5

% 可选：叠加噪声/阶跃
% x = x + 0.05*randn(N,1);    % 白噪声
% x = x + [zeros(N/2,1); 0.3*ones(N/2,1)]; % 加阶跃

scale = 2^14;      % Q2.14缩放
x_q14 = round(x * scale);
x_q14 = min(max(x_q14, -2^15), 2^15-1); % 饱和到Q2.14范围
x_q14 = int16(x_q14);

%% === Matlab参考输出（Q2.14定点） ===
x_fix = double(x_q14) / scale;
y_ref = x_fix;
for i = 1:size(sos_fixed,1)
    y_ref = filter(sos_fixed(i,1:3), [1 sos_fixed(i,5:6)], y_ref);
end
y_q14 = round(y_ref * scale);
y_q14 = min(max(y_q14, -2^15), 2^15-1);
y_q14 = int16(y_q14);

%% === 保存HEX激励和Matlab参考输出 ===
hexfile = 'test_signal.hex';
fid = fopen(hexfile, 'w');
for ii = 1:N
    val = double(x_q14(ii));
    if val < 0
        val = val + 2^16; % 负数转补码
    end
    fprintf(fid, '%04x\n', val);
end
fclose(fid);

reffile = 'ref_output.hex';
fid = fopen(reffile, 'w');
for ii = 1:N
    val = double(y_q14(ii));
    if val < 0
        val = val + 2^16;
    end
    fprintf(fid, '%04x\n', val);
end
fclose(fid);

fprintf('多频激励Q2.14已保存: %s, Matlab参考输出已保存: %s\n', hexfile, reffile);

% 可视化检查（改进版：只显示前200点）
show_N = 200;  % 显示多少个采样点
if N < show_N, show_N = N; end

figure('Name','多频激励信号与滤波器响应');
subplot(3,1,1); plot(t(1:show_N)*1e6, x(1:show_N), 'b'); grid on;
xlabel('时间 (\mus)'); ylabel('幅度');
title('输入多频激励信号');
xlim([t(1)*1e6, t(show_N)*1e6]);

subplot(3,1,2); plot(t(1:show_N)*1e6, double(x_q14(1:show_N))/scale, 'r');
xlabel('时间 (\mus)'); ylabel('Q2.14定点值');
title('Q2.14定点激励信号');
xlim([t(1)*1e6, t(show_N)*1e6]);

subplot(3,1,3); plot(t(1:show_N)*1e6, double(y_q14(1:show_N))/scale, 'k');
xlabel('时间 (\mus)'); ylabel('滤波器输出Q2.14');
title('Matlab滤波器Q2.14输出');
xlim([t(1)*1e6, t(show_N)*1e6]);