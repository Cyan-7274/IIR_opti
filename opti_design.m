% =========================================================================
% WiFi 6/7 PHY IIR滤波器 完整设计与工程验证 (含工程拍数分析, HEX输出)
% =========================================================================
clear; clc;

%% 1. 设计参数
Fs = 80e6;           % 采样率
Fp = 20e6;           % 通带
Fs_stop = 25e6;      % 阻带
Rp = 0.1;            % 通带纹波
Rs = 60;             % 阻带衰减
filter_type = 'cheby1';

wl = 16; fl = 14;    % Q2.14
strict_margin = 0.96;

%% 2. 拍数与系统时钟工程分析
% 延迟推算
opt_multiplier_delay = 4;    % 高速优化版乘法器
std_multiplier_delay = 9;    % 标准版乘法器
iir_structure_delay  = 2;    % 结构延迟（直接二型或转置型）

optimized_latency = opt_multiplier_delay + iir_structure_delay;
standard_latency  = std_multiplier_delay + iir_structure_delay;

% 系统时钟候选
sys_clk_list = [500, 1000]; % MHz
sample_period_ns = 1e9/Fs;

fprintf('========== 工程级延迟与时序冗余分析 ==========\n');
fprintf('优化版总延迟: %d拍（乘法%d+结构%d）\n', optimized_latency, opt_multiplier_delay, iir_structure_delay);
fprintf('标准版总延迟: %d拍（乘法%d+结构%d）\n', standard_latency, std_multiplier_delay, iir_structure_delay);

for clkidx = 1:length(sys_clk_list)
    sys_clk_mhz = sys_clk_list(clkidx);
    clk_period_ns = 1000 / sys_clk_mhz;
    std_proc_time = standard_latency * clk_period_ns;
    opt_proc_time = optimized_latency * clk_period_ns;
    std_margin = (sample_period_ns - std_proc_time) / sample_period_ns * 100;
    opt_margin = (sample_period_ns - opt_proc_time) / sample_period_ns * 100;
    fprintf('\n[系统时钟 %dMHz]\n', sys_clk_mhz);
    fprintf('  标准版处理时间: %.2fns (%.1f%%余量)\n', std_proc_time, std_margin);
    fprintf('  优化版处理时间: %.2fns (%.1f%%余量)\n', opt_proc_time, opt_margin);
    if std_margin < 0
        fprintf('    ⚠️ 标准版超时，采样率下不可用\n');
    elseif std_margin < 10
        fprintf('    ⚠️ 标准版时序余量偏低，仅临界可用\n');
    else
        fprintf('    ✅ 标准版余量充足\n');
    end
    if opt_margin < 10
        fprintf('    ⚠️ 优化版时序余量偏低，仅临界可用\n');
    else
        fprintf('    ✅ 优化版余量充足\n');
    end
end

fprintf('==============================================\n\n');

%% 3. 滤波器设计
Wpass = Fp/(Fs/2);
Wstop = Fs_stop/(Fs/2);
[Nmin, Wn] = cheb1ord(Wpass, Wstop, Rp, Rs);
N = max(8, Nmin);
[B, A] = cheby1(N, Rp, Wn, 'low');
[sos, g] = tf2sos(B, A);

%% 4. 极点排序+均分增益
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

%% 5. Q2.14定点化与误差分析
scale = 2^fl;
sos_fixed = round(sos * scale) / scale;
quant_err = max(abs(sos(:) - sos_fixed(:)));
mean_err = mean(abs(sos(:) - sos_fixed(:)));
max_coeff = max(abs(sos_fixed(:)));
coeff_range = 2^(wl-fl-1);
coeff_utilization = max_coeff / coeff_range * 100;

%% 6. 极点与稳定性
sys_A = 1;
for i = 1:size(sos_fixed,1)
    sys_A = conv(sys_A, [1, sos_fixed(i,5:6)]);
end
poles = roots(sys_A);
max_pole_mag = max(abs(poles));
stability_margin = strict_margin - max_pole_mag;
is_stable = max_pole_mag < strict_margin;

%% 7. 频率响应与群延迟、脉冲响应
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
% 脉冲响应
Nh = 128;
imp = [1; zeros(Nh-1,1)];
h = imp;
for i = 1:size(sos_fixed,1)
    h = filter(sos_fixed(i,1:3), [1 sos_fixed(i,5:6)], h);
end

%% 8. HEX系数保存（分配和排序后）
sos_hex_cell = cell(size(sos_fixed));
for i = 1:numel(sos_fixed)
    val = round(sos_fixed(i)*scale);
    if val<0
        val = val + 2^wl;
    end
    sos_hex_cell{i} = upper(dec2hex(val,4)); % 16bit补码（大写）
end
fid = fopen('iir_coeffs.hex','w');
for i = 1:numel(sos_fixed)
    fprintf(fid,'%s\n',sos_hex_cell{i});
end
fclose(fid);

%% 9. 参数与系数输出
fprintf('=========== IIR滤波器设计与工程验证报告 ===========\n');
fprintf('采样率: %.2fMHz | 通带: %.2fMHz | 阻带: %.2fMHz | 阶数: %d\n', Fs/1e6, Fp/1e6, Fs_stop/1e6, N);
fprintf('通带纹波: %.3fdB (%.3fdB)\n', pass_ripple, Rp);
fprintf('阻带衰减: %.1fdB (%.0fdB)\n', stop_atten, Rs);
fprintf('通带群延迟平坦度: %.3f采样点\n', group_delay_flatness);
fprintf('最大极点模值: %.6f | 工程裕度: %.4f | 稳定性: %s\n', max_pole_mag, stability_margin, string(is_stable));
fprintf('最大定点量化误差: %.6g, 平均误差: %.6g\n', quant_err, mean_err);
fprintf('最大定点系数: %.6f | Q2.14利用率: %.1f%%\n', max_coeff, coeff_utilization);

fprintf('\n--- 分配和排序后的Q2.14 HEX系数 ---\n');
for i = 1:numel(sos_fixed)
    fprintf('%s ', sos_hex_cell{i});
    if mod(i,5)==0, fprintf('\n'); end
end
fprintf('\nHEX已保存到: iir_coeffs.hex\n');
fprintf('===================================================\n');

%% 10. 可视化（群延迟、脉冲响应、幅频、零极点）
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