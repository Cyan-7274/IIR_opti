%% 1. 加载滤波器系数
load adc_cheby2_iir.mat  % 必须有sos_fixed, wl, fl

Fs = 80e6;

%% 2. 生成测试信号（幅值安全）
N = 2048;
t = (0:N-1)'/Fs;
f1 = 10e6; f2 = 18e6; f3 = 28e6;

sig1 = 0.2*sin(2*pi*f1*t);      % 通带内
sig2 = 0.2*sin(2*pi*f2*t);      % 阻带边缘
sig3 = 0.1*sin(2*pi*f3*t);      % 阻带外
step = [zeros(200,1); 0.3*ones(N-200,1)];
noise = 0.01*randn(N,1);

x = sig1 + sig2 + sig3 + step + noise;

% 自动幅值归一化（可选，强制不超1）
if max(abs(x)) > 1
    x = x / max(abs(x));
end

fprintf('最大幅值: %.5f\n', max(abs(x)));

%% 3. Q2.22定点量化（输入/输出），并饱和
scale = 2^22;
x_q22 = round(x * scale);
x_q22 = min(max(x_q22, -2^23), 2^23-1);  % 饱和到Q2.22范围
x_q22 = int32(x_q22);

y_ref = sosfilt(sos_fixed, x);
y_q22 = round(y_ref * scale);
y_q22 = min(max(y_q22, -2^23), 2^23-1);
y_q22 = int32(y_q22);

%% 4. HEX文件输出（24bit补码，6位HEX, 大写）
fid = fopen('test_signal.hex','w');
for k = 1:N
    val = uint32(typecast(x_q22(k),'uint32'));  % 处理负数补码
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

%% 5. 可选：直接显示前10个输入/输出样本的十进制与HEX
disp('样本点预览（十进制/HEX）：');
for k = 1:10
    fprintf('IN[%d]: %10d  0x%06X | OUT[%d]: %10d  0x%06X\n', ...
        k, x_q22(k), bitand(typecast(x_q22(k),'uint32'),hex2dec('FFFFFF')), ...
        k, y_q22(k), bitand(typecast(y_q22(k),'uint32'),hex2dec('FFFFFF')));
end