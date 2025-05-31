clear; close all; clc
%% === 加载滤波器参数 ===
load adc_cheby2_iir.mat

N = 2048;
Fs = double(Fs);  % 确保变量类型一致
f_sin = 8e6;      % 激励频率
phi = 0.3;        % 可调信号初相位
t = (0:N-1)' / Fs;
x = 0.5 * sin(2*pi* f_sin*t + phi);

scale = 2^22;
x_q22 = round(x * scale);
x_q22 = min(max(x_q22, -2^23), 2^23-1);
x_q22 = int32(x_q22);

%% === 保存输入激励为hex文件，供Verilog testbench读取 ===
hexfile = 'D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex';
fid = fopen(hexfile, 'w');
for ii = 1:N
    val = mod(double(x_q22(ii)), 2^24); 
    fprintf(fid, '%06x\n', val);
end
fclose(fid);

disp(['输入激励已保存为HEX文件: ', hexfile]);

%% ==== IIR理论输出及各级节点 ====
% 解析各级中间信号
y_ref = sosfilt(sos_fixed, x);
y_q22 = round(y_ref * scale);
y_q22 = min(max(y_q22, -2^23), 2^23-1);
y_q22 = int32(y_q22);

% 中间节点信号
x_sos = zeros(N, 5); % 输入+4级输出
x_sos(:,1) = x;
x_sos_q22 = zeros(N, 5, 'int32');
x_sos_q22(:,1) = x_q22;

x_stage = x;
x_stage_q22 = x_q22;
for k = 1:4
    x_stage = sosfilt(sos_fixed(k,:), x_stage);
    x_stage_q22 = round(x_stage * scale);
    x_stage_q22 = min(max(x_stage_q22, -2^23), 2^23-1);
    x_stage_q22 = int32(x_stage_q22);
    x_sos(:,k+1) = x_stage;
    x_sos_q22(:,k+1) = x_stage_q22;
end

%% ==== 自动分析激励频率下的群延迟 ====
[~, idx_delay] = min(abs(f_gd - f_sin));
group_delay = round(Gd(idx_delay)); % 采样点

fprintf('激励频率%.2fMHz下群延迟为%d点。\n', f_sin/1e6, group_delay);

%% ==== 保存全部参考数据 ====
csvfile = 'reference_data.csv';
T = table((0:N-1)', x, x_q22, ...
    x_sos(:,2), x_sos_q22(:,2), ... % sos0输出
    x_sos(:,3), x_sos_q22(:,3), ... % sos1输出
    x_sos(:,4), x_sos_q22(:,4), ... % sos2输出
    x_sos(:,5), x_sos_q22(:,5), ... % sos3输出
    y_ref, y_q22, ...
    'VariableNames', {'cycle','x','x_q22', ...
    'sos0_out','sos0_out_q22', ...
    'sos1_out','sos1_out_q22', ...
    'sos2_out','sos2_out_q22', ...
    'sos3_out','sos3_out_q22', ...
    'y_ref','y_q22'});
writetable(T, csvfile);
disp(['理论参考数据已保存为: ', csvfile]);

%% === 保存mat文件（含群延迟信息、各中间信号）===
save('reference_data.mat', ...
    'x', 'x_q22', ...
    'x_sos', 'x_sos_q22', ...
    'y_ref', 'y_q22', ...
    'sos_fixed', 'scale', 'f_sin', 'group_delay');