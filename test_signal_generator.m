clear; close all; clc
%% 基本参数与激励
load adc_cheby2_iir.mat
Fs = 80e6;
N = 2048;
x = zeros(N,1);

% [3] 正弦激励
f_sin = 10e6;
t = (0:N-1)' / Fs;
x = 0.5 * sin(2*pi* f_sin*t + 0.5);

scale = 2^22;
x_q22 = round(x * scale);
x_q22 = min(max(x_q22, -2^23), 2^23-1);
x_q22 = int32(x_q22);

%% ==== 前馈路径每一级的p理论输出（可选，已注释）====
% b0 = sos_fixed(1,1);
% b1 = sos_fixed(1,2);
% b2 = sos_fixed(1,3);
% 
% b0_p_theory = b0 * x;
% b1_p_theory = b1 * x;
% b2_p_theory = b2 * x;
% 
% b0_p_theory_q22 = round(b0_p_theory * scale);
% b0_p_theory_q22 = min(max(b0_p_theory_q22, -2^23), 2^23-1);
% b0_p_theory_q22 = double(b0_p_theory_q22) / scale;
% 
% b1_p_theory_q22 = round(b1_p_theory * scale);
% b1_p_theory_q22 = min(max(b1_p_theory_q22, -2^23), 2^23-1);
% b1_p_theory_q22 = double(b1_p_theory_q22) / scale;
% 
% b2_p_theory_q22 = round(b2_p_theory * scale);
% b2_p_theory_q22 = min(max(b2_p_theory_q22, -2^23), 2^23-1);
% b2_p_theory_q22 = double(b2_p_theory_q22) / scale;

%% ==== IIR理论输出 ====
y_ref = sosfilt(sos_fixed, x);

x_stage = double(x);
y_stage_all = zeros(length(x), size(sos_fixed,1));
for k = 1:size(sos_fixed,1)
    b = sos_fixed(k,1:3);
    a = [1 sos_fixed(k,5:6)];
    x_stage = filter(b, a, x_stage);
    x_stage = round(x_stage * scale);
    x_stage = min(max(x_stage, -2^23), 2^23-1);
    x_stage = x_stage / scale;
    y_stage_all(:,k) = x_stage;
end
y_fixed = x_stage;

y_q22 = round(y_ref * scale);
y_q22 = min(max(y_q22, -2^23), 2^23-1);
y_q22 = int32(y_q22);

y_fixed_q22 = round(y_fixed * scale);
y_fixed_q22 = min(max(y_fixed_q22, -2^23), 2^23-1);
y_fixed_q22 = int32(y_fixed_q22);

%% ==== 反馈路径a1、a2的理论乘法器输出 ====
a1 = sos_fixed(1,5);
a2 = sos_fixed(1,6);

% 推荐用浮点y_ref，也可用定点y_fixed
y_theory = y_ref;

y_n1 = [0; y_theory(1:end-1)];     % y[n-1]
y_n2 = [0; 0; y_theory(1:end-2)];  % y[n-2]

a1_p_theory = a1 * y_n1;
a2_p_theory = a2 * y_n2;

a1_p_theory_q22 = round(a1_p_theory * scale);
a1_p_theory_q22 = min(max(a1_p_theory_q22, -2^23), 2^23-1);
a1_p_theory_q22 = double(a1_p_theory_q22) / scale;

a2_p_theory_q22 = round(a2_p_theory * scale);
a2_p_theory_q22 = min(max(a2_p_theory_q22, -2^23), 2^23-1);
a2_p_theory_q22 = double(a2_p_theory_q22) / scale;

%% ==== 保存全部参考数据 ====
save('reference_data.mat', ...
    'x', 'x_q22', ...
    ... % 'b0_p_theory', 'b1_p_theory', 'b2_p_theory', ...
    ... % 'b0_p_theory_q22', 'b1_p_theory_q22', 'b2_p_theory_q22', ...
    'y_ref', 'y_q22', ...
    'y_fixed', 'y_fixed_q22', ...
    'y_stage_all', 'sos_fixed', 'scale', ...
    'a1', 'a2', ...
    'a1_p_theory', 'a2_p_theory', ...
    'a1_p_theory_q22', 'a2_p_theory_q22');

