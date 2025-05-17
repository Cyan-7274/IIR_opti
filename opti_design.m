clear
close all
clc
%% 高速ADC低通IIR椭圆型滤波器设计、定点实现、响应分析与系数排序
Fs = 80e6;
Wp = 10e6/(Fs/2);
Ws = 15e6/(Fs/2);
Rp = 1;
Rs = 40;
wl = 16; fl = 14; % Q1.14
strict_margin = 0.93;

% 1. 设计
[N, Wn] = ellipord(Wp, Ws, Rp, Rs);
[B, A] = ellip(N, Rp, Rs, Wn, 'low');
[sos, g] = tf2sos(B, A);

% 2. 按极点模值排序
sos_poles = cellfun(@(a) max(abs(roots([1 a(5:6)]))), num2cell(sos,2));
[~, idx] = sort(sos_poles, 'descend');
sos = sos(idx,:);

% 3. 均匀分配增益
root_gain = g^(1/size(sos,1));
for i=1:size(sos,1)
    sos(i,1:3) = sos(i,1:3) * root_gain;
end

% 4. 定点量化
scale = 2^fl;
sos_fixed = round(sos * scale) / scale;

% 5. 稳定性分析
sysA = 1;
for i=1:size(sos_fixed,1)
    sysA = conv(sysA, [1, sos_fixed(i,5:6)]);
end
poles = roots(sysA);
maxpole = max(abs(poles));
is_stable = maxpole < strict_margin;

% 6. 响应分析
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

% 脉冲响应
imp = [1; zeros(127,1)];
x = imp;
for k = 1:size(sos_fixed,1)
    b = sos_fixed(k,1:3);
    a = [1 sos_fixed(k,5:6)];
    x = filter(b, a, x);
end
resp = x;

% --- 稳定时间估算 ---
thresh = 1e-3;        % 阈值，可根据工程需求调整
min_hold = 10;        % 连续10点低于阈值才算稳定
abs_resp = abs(resp);
below = abs_resp < thresh;
stable_idx = find(movsum(below, min_hold) >= min_hold, 1); % 首次出现连续10点均低于阈值的位置

if isempty(stable_idx)
    fprintf('脉冲响应未在分析窗口内收敛到阈值。\n');
    stable_idx = NaN;
else
    fprintf('脉冲响应在第 %d 个采样点后收敛到 |幅值| < %.1e。\n', stable_idx, thresh);
end

% 绘图标注
figure('Name','单位脉冲响应');
stem(0:length(resp)-1, resp, 'filled');
if ~isnan(stable_idx)
    hold on;
    xline(stable_idx-1, 'r--', sprintf('稳定点%d',stable_idx-1));
    hold off;
end
xlabel('采样点'); ylabel('幅度'); title('单位脉冲响应（含稳定时间标注）'); grid on;


% 7. 输出关键信息
fprintf('\n=== 高速ADC低通IIR滤波器 Q1.14 ===\n');
fprintf('采样率: %.2f MHz\n', Fs/1e6);
fprintf('通带: %.2f MHz, 阻带: %.2f MHz\n', 10, 15);
fprintf('类型: 椭圆型 | 阶数: %d | 定点格式: Q1.14\n', N);
fprintf('极点最大值: %.5f | 是否稳定: %s\n', maxpole, tf(is_stable));
fprintf('分段(SOS)数: %d\n', size(sos_fixed,1));
disp('Q1.14定点系数（已排序，每行：[b0 b1 b2 a1 a2]）：');
disp(sos_fixed(:,[1 2 3 5 6]));

% 8. Verilog hex导出
coeff_list = reshape(sos_fixed(:,[1 2 3 5 6])', [], 1);
coeff_int = int16(round(coeff_list * scale));
fid = fopen('adc_lowpass_coeffs_hex.txt','w');
for i = 1:length(coeff_int)
    hexstr = dec2hex(typecast(coeff_int(i),'uint16'),4);
    fprintf(fid, "16'h%s // %d\n", hexstr, coeff_int(i));
end
fclose(fid);

function s = tf(cond)
if cond, s='✅'; else, s='❌'; end
end


scale = 2^14;
for i = 1:size(coeffs,1)
    ci = int16(round(coeffs(i,:) * scale));
    hexstr = dec2hex(typecast(ci,'uint16'),4);
    disp(['b0: 16''sh' hexstr(1,:) ', b1: 16''sh' hexstr(2,:) ', b2: 16''sh' hexstr(3,:) , ...
          ', a1: 16''sh' hexstr(4,:) ', a2: 16''sh' hexstr(5,:)]);
end