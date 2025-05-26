clear; close all; clc
%% 多段激励信号（脉冲/阶跃/正弦）- 扩展版
load adc_cheby2_iir.mat
Fs = 80e6;
N = 2048;
x = zeros(N,1);

% % [1] 单位脉冲
% x(1) = 1.0;

% % [2] 单位阶跃
% x(101:250) = 1.0;

% [3] 正弦
f_sin = 10e6;
t = (0:N-1)' / Fs;
x = 0.5 * sin(2*pi* f_sin*t + 0.5);

% Q2.22量化和输出部分同前...
scale = 2^22;
x_q22 = round(x * scale);
x_q22 = min(max(x_q22, -2^23), 2^23-1);
x_q22 = int32(x_q22);

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