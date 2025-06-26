% =========================================================================
% WiFi 6/7 PHY IIR滤波器 完整设计与工程验证 (定点极点与利用率分析、可视化全流程)
% =========================================================================
clear; close all; clc;

%% 1. 设计参数
Fs = 80e6;           % 采样率
Fp = 20e6;           % 通带
Fs_stop = 25e6;      % 阻带
Rp = 0.1;            % 通带纹波
Rs = 50;             % 阻带衰减
filter_type = 'cheby1';

wl = 16; fl = 14;    % Q2.14
strict_margin = 0.96; % 工程极点模裕度

%% 2. 滤波器设计（浮点）
Wpass = Fp/(Fs/2);
Wstop = Fs_stop/(Fs/2);
[Nmin, Wn] = cheb1ord(Wpass, Wstop, Rp, Rs);
N = max(8, Nmin);
[B, A] = cheby1(N, Rp, Wn, 'low');
[sos, g] = tf2sos(B, A);

%% 3. 极点排序+均分增益
sos_poles = zeros(size(sos,1), 1);
for i = 1:size(sos,1)
    poles_i = roots([1, sos(i,5:6)]);
    sos_poles(i) = max(abs(poles_i));
end
[~, sort_idx] = sort(sos_poles, 'ascend');
sos = sos(sort_idx, :);

root_gain = g^(1/size(sos,1));
for i = 1:size(sos,1)
    sos(i,1:3) = sos(i,1:3) * root_gain;
end

%% 4. Q2.14定点化与误差分析
scale = 2^fl;
sos_fixed = round(sos * scale) / scale;
quant_err = max(abs(sos(:) - sos_fixed(:)));
mean_err = mean(abs(sos(:) - sos_fixed(:)));
max_coeff = max(abs(sos_fixed(:)));
coeff_range = 2^(wl-fl-1);  % Q2.14最大绝对值 = 2
coeff_utilization = max_coeff / coeff_range * 100; % 仅作参考

%% 5. 定点化后极点与稳定性分析
% 5.1 整体系统极点
sys_A = 1;
for i = 1:size(sos_fixed,1)
    sys_A = conv(sys_A, [1, sos_fixed(i,5:6)]);
end
poles = roots(sys_A);
max_pole_mag = max(abs(poles));
is_stable = max_pole_mag < strict_margin;

% 5.2 每一节单独极点（按你的理解，只要所有极点模<0.96即可合格，不需要再做减法）
fprintf('\n========== 单节极点模分析 ==========\n');
unstable_sections = [];
for i = 1:size(sos_fixed,1)
    poles_i = roots([1, sos_fixed(i,5:6)]);
    max_pole_i = max(abs(poles_i));
    fprintf('第%2d节最大极点模: %.6f\n', i, max_pole_i);
    if max_pole_i >= strict_margin
        warning('第%d节极点模%.6f >= 工程裕度%.3f，单节可能不稳定！', i, max_pole_i, strict_margin);
        unstable_sections(end+1) = i; %#ok<AGROW>
    end
end
if isempty(unstable_sections)
    fprintf('所有节极点均满足裕度%.3f，单节均稳定。\n', strict_margin);
else
    fprintf('存在不稳定节，工程实现需警惕！\n');
end
fprintf('====================================\n\n');

%% 6. 频率响应与群延迟、脉冲响应
N_freq = 2048;
[H, f] = freqz(sos_fixed, N_freq, Fs);
H_mag_db = 20*log10(abs(H)+eps);
[Gd, f_gd] = grpdelay(sos_fixed, N_freq, Fs);
pass_idx = f <= Fp;
pass_ripple = max(H_mag_db(pass_idx)) - min(H_mag_db(pass_idx));
stop_idx = f >= Fs_stop;
stop_atten = -max(H_mag_db(stop_idx));
pass_gd_idx = f_gd <= Fp;
group_delay_flatness = max(Gd(pass_gd_idx)) - min(Gd(pass_gd_idx));
Nh = 128;
imp = [1; zeros(Nh-1,1)];
h = imp;
for i = 1:size(sos_fixed,1)
    h = filter(sos_fixed(i,1:3), [1 sos_fixed(i,5:6)], h);
end

%% 7. HEX系数保存
sos_hex_cell = cell(size(sos_fixed));
for i = 1:numel(sos_fixed)
    val = round(sos_fixed(i)*scale);
    if val<0
        val = val + 2^wl;
    end
    sos_hex_cell{i} = upper(dec2hex(val,4)); % 16bit补码
end
fid = fopen('iir_coeffs.hex','w');
for i = 1:numel(sos_fixed)
    fprintf(fid,'%s\n',sos_hex_cell{i});
end
fclose(fid);

%% 8. 参数与系数输出
fprintf('=========== IIR滤波器设计与工程验证报告 ===========\n');
fprintf('采样率: %.2fMHz | 通带: %.2fMHz | 阻带: %.2fMHz | 阶数: %d\n', Fs/1e6, Fp/1e6, Fs_stop/1e6, N);
fprintf('通带纹波: %.3fdB (%.3fdB)\n', pass_ripple, Rp);
fprintf('阻带衰减: %.1fdB (%.0fdB)\n', stop_atten, Rs);
fprintf('最大极点模值: %.6f | 工程裕度: %.4f | 稳定性: %s\n', max_pole_mag, strict_margin, string(is_stable));
fprintf('最大定点量化误差: %.6g, 平均误差: %.6g\n', quant_err, mean_err);
fprintf('最大定点系数: %.6f | Q2.14利用率(仅参考): %.1f%%\n', max_coeff, coeff_utilization);

fprintf('\n--- 分配和排序后的Q2.14 HEX系数 ---\n');
for i = 1:numel(sos_fixed)
    fprintf('%s ', sos_hex_cell{i});
    if mod(i,5)==0, fprintf('\n'); end
end
fprintf('\nHEX已保存到: iir_coeffs.hex\n');
fprintf('===================================================\n');

%% 9. 可视化
figure('Name','IIR设计全流程验证','Position',[50,100,1400,800]);
subplot(2,2,1);
plot(f/1e6, H_mag_db, 'b-', 'LineWidth',1.5); grid on;
xlabel('频率 (MHz)'); ylabel('幅度 (dB)'); title('幅频响应');
xline(Fp/1e6,'r--','通带边界'); xline(Fs_stop/1e6,'r--','阻带边界'); ylim([-100,5]);

subplot(2,2,2);
plot(f_gd/1e6, Gd, 'b-', 'LineWidth',1.5); grid on;
xlabel('频率 (MHz)'); ylabel('群延迟 (采样点)'); title('群延迟');
xline(Fp/1e6,'r--','通带边界');

subplot(2,2,3);
zplane(sos_fixed(:,1:3), [ones(size(sos_fixed,1),1), sos_fixed(:,4:6)]);
title(sprintf('零极点分布 (max|p|=%.4f)', max_pole_mag));

subplot(2,2,4);
stem(0:Nh-1, h, 'filled');
xlabel('n'); ylabel('幅值'); title('脉冲响应（稳定点应收敛）'); grid on;

%% 10. 工程主频/延迟对比
num_stage = size(sos_fixed,1);    % SOS节数
latency_per_stage = 4;            % 每节sos延迟（优化版，单位：拍）
sys_delay = num_stage * latency_per_stage; % 滤波器总延迟，单位：拍
sample_period_ns = 1e9/Fs;        % 采样周期，单位ns
min_clk_MHz = Fs * latency_per_stage / 1e6; % 主频必须是采样率的n倍

fprintf('\n========== 工程流水线时序分析 ==========\n');
fprintf('关键路径延迟: %d拍，总延迟: %d拍，sos节数: %d\n', latency_per_stage, sys_delay, num_stage);
fprintf('采样率: %.2f MHz，采样周期: %.2f ns，最低主频: %.2f MHz\n', Fs/1e6, sample_period_ns, min_clk_MHz);
fprintf('建议主频: %.2f MHz（留裕度）\n', min_clk_MHz * 1.25);
fprintf('========================================\n');