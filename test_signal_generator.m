% 测试信号生成+ADC抗混叠低通定点IIR滤波器功能验证（Q2.22/80MHz版本）
clear; clc;
load adc_cheby2_iir.mat  % 加载Q2.22系数和参数
Fs = 80e6;

%% 1. 测试信号：多频正弦+阶跃+噪声
N = 2048;
t = (0:N-1)'/Fs;
f1 = 10e6; f2 = 18e6; f3 = 28e6;
sig1 = 0.7*sin(2*pi*f1*t);      % 通带内
sig2 = 0.8*sin(2*pi*f2*t);      % 阻带边缘
sig3 = 0.5*sin(2*pi*f3*t);      % 阻带外
step = [zeros(200,1); ones(N-200,1)];
noise = 0.02*randn(N,1);

x = sig1 + sig2 + sig3 + step + noise;

%% 2. 定点量化（Q2.22输入格式，溢出/饱和处理）
x_q22 = max(min(round(x*2^22), 2^23-1), -2^23); % Q2.22有符号补码
x_q22 = int32(x_q22);

%% 3. 浮点/定点滤波器参考
y_ref = sosfilt(sos_fixed, x);
y_q22 = max(min(round(y_ref*2^22), 2^23-1), -2^23);
y_q22 = int32(y_q22);

%% 4. HEX文件输出
fid = fopen('test_signal.hex','w');  % 输入激励
for k = 1:N
    val = bitand(x_q22(k), hex2dec('FFFFFF')); % Q2.22补码，24bit
    fprintf(fid, '%06X\n', val);
end
fclose(fid);

fid = fopen('reference_output.hex','w'); % 参考输出
for k = 1:N
    val = bitand(y_q22(k), hex2dec('FFFFFF'));
    fprintf(fid, '%06X\n', val);
end
fclose(fid);

%% 5. 绘图对比
figure('Name','ADC抗混叠IIR测试信号滤波效果');
subplot(3,1,1);
plot(t*1e6, x); grid on; title('输入信号');
xlabel('时间(μs)'); ylabel('幅度');

subplot(3,1,2);
plot(t*1e6, y_ref, 'b', 'LineWidth',1.1); hold on;
plot(t*1e6, double(y_q22)/2^22, 'r--');
title('滤波输出：定点实现(红虚线) vs 浮点理论(蓝)');
legend('浮点实现','定点实现');
xlabel('时间(μs)'); ylabel('幅度'); grid on;

subplot(3,1,3);
plot(t*1e6, y_ref - double(y_q22)/2^22, 'k');
title('定点实现与浮点理论误差');
xlabel('时间(μs)'); ylabel('误差'); grid on;

%% 6. 频谱分析
figure('Name','滤波器输入/输出频谱');
nfft = 4096;
f_axis = Fs*(0:(nfft/2))/nfft/1e6;
X = fft(x,nfft); Y = fft(y_ref,nfft);
plot(f_axis,20*log10(abs(X(1:nfft/2+1))/max(abs(X))));
hold on;
plot(f_axis,20*log10(abs(Y(1:nfft/2+1))/max(abs(Y))));
xlabel('频率(MHz)'); ylabel('幅度(dB)'); grid on;
legend('输入','滤波输出');
title('滤波器输入/输出幅频特性');

% ------ END ------