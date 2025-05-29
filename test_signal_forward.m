clear; close all; clc
%% 多段激励信号（脉冲/阶跃/正弦）- 扩展版
load adc_cheby2_iir.mat
Fs = 80e6;
N = 2048;
x = zeros(N,1);

% [3] 正弦
f_sin = 10e6;
t = (0:N-1)' / Fs;
x = 0.5 * sin(2*pi* f_sin*t + 0.5);

scale = 2^22;
x_q22 = round(x * scale);
x_q22 = min(max(x_q22, -2^23), 2^23-1);
x_q22 = int32(x_q22);

% ==== 新增：前馈路径每一级的p理论输出 ====
b0 = sos_fixed(1,1);
b1 = sos_fixed(1,2);
b2 = sos_fixed(1,3);

b0_p_theory = b0 * x;
b1_p_theory = b1 * x;
b2_p_theory = b2 * x;

b0_p_theory_q22 = round(b0_p_theory * scale);
b0_p_theory_q22 = min(max(b0_p_theory_q22, -2^23), 2^23-1);
b0_p_theory_q22 = double(b0_p_theory_q22) / scale;

b1_p_theory_q22 = round(b1_p_theory * scale);
b1_p_theory_q22 = min(max(b1_p_theory_q22, -2^23), 2^23-1);
b1_p_theory_q22 = double(b1_p_theory_q22) / scale;

b2_p_theory_q22 = round(b2_p_theory * scale);
b2_p_theory_q22 = min(max(b2_p_theory_q22, -2^23), 2^23-1);
b2_p_theory_q22 = double(b2_p_theory_q22) / scale;

% 其余部分保持不变
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

fid = fopen('test_signal.hex','w');
for k = 1:N
    val = uint32(typecast(x_q22(k),'uint32'));
    val = bitand(val, hex2dec('FFFFFF'));
    fprintf(fid, '%06X\n', val);
end
fclose(fid);

fid = fopen('reference_output.hex','w');
for k = 1:N
    val = uint32(typecast(y_q22(k),'uint32'));
    val = bitand(val, hex2dec('FFFFFF'));
    fprintf(fid, '%06X\n', val);
end
fclose(fid);

fid = fopen('fixedpoint_output.hex','w');
for k = 1:N
    val = uint32(typecast(y_fixed_q22(k),'uint32'));
    val = bitand(val, hex2dec('FFFFFF'));
    fprintf(fid, '%06X\n', val);
end
fclose(fid);

% 逐级HEX
for k = 1:size(y_stage_all,2)
    fname = sprintf('stage%d_output.hex', k);
    fid = fopen(fname, 'w');
    y_stage_q22 = round(y_stage_all(:,k) * scale);
    y_stage_q22 = min(max(y_stage_q22, -2^23), 2^23-1);
    y_stage_q22 = int32(y_stage_q22);
    for n = 1:N
        val = uint32(typecast(y_stage_q22(n),'uint32'));
        val = bitand(val, hex2dec('FFFFFF'));
        fprintf(fid, '%06X\n', val);
    end
    fclose(fid);
end

disp('前20数据');
disp(x(1:20));

% ==== 新增：保存所有参考信号为mat文件（供调试分析用） ====
save('reference_data.mat', ...
    'x', 'x_q22', ...
    'b0_p_theory', 'b1_p_theory', 'b2_p_theory', ...
    'b0_p_theory_q22', 'b1_p_theory_q22', 'b2_p_theory_q22', ...
    'y_ref', 'y_q22', ...
    'y_fixed', 'y_fixed_q22', ...
    'y_stage_all', 'sos_fixed', 'scale');