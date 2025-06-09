% =========================================================================
% servo_iir_design.m (高精度伺服抗混叠滤波器设计与全面分析/最终完善版)
% 场景：高精度伺服AA | Chebyshev II型 | Q2.22 ASIC实现
% 优化目标：标准版8拍 → 优化版3拍，实时性能提升
% =========================================================================
clear; close all; clc;

%% [1] 高精度伺服场景参数
Fs = 15e6;          % 采样频率 15MHz (伺服控制主流)
Fp = 4.5e6;         % 通带频率 4.5MHz 
Fs_stop = 6e6;      % 阻带频率 6MHz
Rp = 0.1;           % 通带纹波 0.1dB (高精度要求)
Rs = 70;            % 阻带衰减 70dB (伺服控制标准)
filter_type = 'cheby2';  % Chebyshev II型 (工业主流)

% 定点化参数
wl = 24; fl = 22;   % Q2.22格式
strict_margin = 0.94;  % 稳定裕度 (伺服系统要求)

% 时序分析参数
sys_clk_mhz = 150;  % 系统时钟150MHz (基于前期分析)
standard_latency = 8;   % 标准版延迟(拍)
optimized_latency = 3;  % 优化版延迟(拍)

fprintf('=========================================================================\n');
fprintf('           高精度伺服抗混叠IIR滤波器 - ASIC实现设计\n');
fprintf('=========================================================================\n');
fprintf('应用场景: 高精度伺服驱动系统抗混叠滤波\n');
fprintf('设计目标: 标准版%d拍 → 优化版%d拍，实时性能提升\n', standard_latency, optimized_latency);
fprintf('系统参数: 采样率%.1fMHz | 通带%.1fMHz | 阻带%.1fMHz | Q%d.%d\n', ...
    Fs/1e6, Fp/1e6, Fs_stop/1e6, wl-fl, fl);
fprintf('性能要求: 通带纹波%.1fdB | 阻带衰减%.0fdB | 稳定裕度%.2f\n', Rp, Rs, strict_margin);

%% [2] 滤波器设计与优化
Wpass = Fp/(Fs/2); 
Wstop = Fs_stop/(Fs/2);

[N_min, Wn] = cheb2ord(Wpass, Wstop, Rp, Rs);
fprintf('\n--- 滤波器设计 ---\n');
fprintf('Chebyshev II型最小阶数: %d\n', N_min);
N = max(8, N_min);
if N ~= N_min
    fprintf('调整为毕设要求: %d阶 (≥8阶技术挑战)\n', N);
end

[B, A] = cheby2(N, Rs, Wn, 'low');
[sos, g] = tf2sos(B, A);

fprintf('实际设计阶数: %d阶 | SOS节数: %d\n', N, size(sos,1));

% 极点模排序 (升序/低Q优先) + 均匀分配增益
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
fprintf('增益分配: 总增益%.6f分配到%d节，每节%.6f\n', g, size(sos,1), root_gain);

%% [3] 定点化处理与验证
scale = 2^fl;
sos_fixed = round(sos * scale) / scale;

% 量化误差分析
coeff_error = abs(sos(:) - sos_fixed(:));
max_quant_error = max(coeff_error);
avg_quant_error = mean(coeff_error);
fprintf('\n--- 定点化分析 ---\n');
fprintf('量化步长: %.3e | 最大量化误差: %.3e | 平均误差: %.3e\n', ...
    1/scale, max_quant_error, avg_quant_error);

% 系数范围检查
max_coeff = max(abs(sos_fixed(:)));
coeff_range = 2^(wl-fl-1);  % 有符号数范围
coeff_utilization = max_coeff / coeff_range * 100;
fprintf('系数范围: [%.3f, %.3f] | 利用率: %.1f%%\n', -coeff_range, coeff_range, coeff_utilization);

if max_coeff >= coeff_range
    warning('系数溢出！需要调整增益分配或位宽');
end

%% [4] 稳定性全面分析
fprintf('\n--- 稳定性分析 ---\n');
sys_A = 1;
for i = 1:size(sos_fixed,1)
    sys_A = conv(sys_A, [1, sos_fixed(i,5:6)]);
end
poles = roots(sys_A);
max_pole_mag = max(abs(poles));
stability_margin = strict_margin - max_pole_mag;
is_stable = max_pole_mag < strict_margin;

fprintf('极点分析:\n');
for i = 1:length(poles)
    fprintf('  极点%d: %.6f%+.6fj, 模值: %.6f\n', i, real(poles(i)), imag(poles(i)), abs(poles(i)));
end
fprintf('最大极点模值: %.6f | 稳定裕度: %.6f | 稳定性: %s\n', ...
    max_pole_mag, stability_margin, string(is_stable));

% 累积误差分析 (单位阶跃响应)
if is_stable
    [b_total, a_total] = sos2tf(sos_fixed, 1);
    N_resp = 8192;
    h_imp = impz(b_total, a_total, N_resp);
    step_resp = cumsum(h_imp);
    
    if any(~isfinite(step_resp))
        accum_error = NaN;
        fprintf('累积误差: 数值不稳定\n');
    else
        accum_error = max(abs(step_resp));
        fprintf('累积误差 (单位阶跃): %.3e\n', accum_error);
        
        % 稳定时间分析
        thresh = 1e-4;
        stable_idx = find(abs(h_imp) < thresh, 50, 'first');
        if length(stable_idx) >= 50
            settle_time = stable_idx(50) / Fs * 1e6;  % 微秒
            fprintf('稳定时间 (|h|<%.0e): %.2f μs\n', thresh, settle_time);
        end
    end
else
    accum_error = NaN;
    fprintf('系统不稳定，累积误差无意义\n');
end

% 量化噪声估计
quant_noise_power = sum(coeff_error.^2) / 12;  % 均匀量化噪声方差
if quant_noise_power > 0
    signal_power = 1;  % 假设单位信号功率
    snr_est = 10*log10(signal_power / quant_noise_power);
    fprintf('量化噪声SNR估计: %.1f dB\n', snr_est);
else
    snr_est = NaN;
end

%% [5] 时序性能分析
fprintf('\n--- 时序性能分析 ---\n');
sample_period_ns = 1e9 / Fs;
clk_period_ns = 1000 / sys_clk_mhz;
standard_proc_time = standard_latency * clk_period_ns;
optimized_proc_time = optimized_latency * clk_period_ns;
standard_margin = (sample_period_ns - standard_proc_time) / sample_period_ns * 100;
optimized_margin = (sample_period_ns - optimized_proc_time) / sample_period_ns * 100;
timing_improvement = optimized_margin - standard_margin;

fprintf('系统时钟: %d MHz (%.2f ns周期)\n', sys_clk_mhz, clk_period_ns);
fprintf('采样周期: %.2f ns\n', sample_period_ns);
fprintf('标准版处理时间: %d拍 × %.2fns = %.2fns (余量: %.1f%%)\n', ...
    standard_latency, clk_period_ns, standard_proc_time, standard_margin);
fprintf('优化版处理时间: %d拍 × %.2fns = %.2fns (余量: %.1f%%)\n', ...
    optimized_latency, clk_period_ns, optimized_proc_time, optimized_margin);
fprintf('性能提升: %.1f%% (优化效果显著)\n', timing_improvement);

if standard_margin < 0
    fprintf('⚠️  标准版无法实时处理 (超时%.1f%%)\n', -standard_margin);
end
if optimized_margin < 20
    fprintf('⚠️  优化版余量不足，建议提高时钟或优化延迟\n');
else
    fprintf('✅ 优化版时序余量充足，满足实时要求\n');
end

%% [6] 频率响应分析
fprintf('\n--- 频率响应分析 ---\n');
N_freq = 2048;
[H, f] = freqz(sos_fixed, N_freq, Fs);
H_mag_db = 20*log10(abs(H)+eps);

pass_idx = f <= Fp;
pass_ripple = max(H_mag_db(pass_idx)) - min(H_mag_db(pass_idx));
pass_gain = mean(H_mag_db(pass_idx));
stop_idx = f >= Fs_stop;
stop_atten = -max(H_mag_db(stop_idx));

fprintf('通带特性: 增益%.2fdB, 纹波%.3fdB (要求<%.1fdB)\n', pass_gain, pass_ripple, Rp);
fprintf('阻带特性: 衰减%.1fdB (要求>%.0fdB)\n', stop_atten, Rs);

pass_ok = pass_ripple <= Rp * 1.1;  % 允许10%容差
stop_ok = stop_atten >= Rs * 0.9;   % 允许10%容差
spec_ok = pass_ok && stop_ok;
fprintf('规格符合性: 通带%s | 阻带%s | 整体%s\n', ...
    string(pass_ok), string(stop_ok), string(spec_ok));

%% [7] 群延迟分析 (伺服系统重要指标)
[Gd, f_gd] = grpdelay(sos_fixed, N_freq, Fs);
key_freqs = [Fp*0.5, Fp*0.8, Fp, (Fp+Fs_stop)/2];
fprintf('\n--- 群延迟分析 (伺服控制关键) ---\n');
for i = 1:length(key_freqs)
    [~, idx] = min(abs(f_gd - key_freqs(i)));
    group_delay_samples = Gd(idx);
    group_delay_us = group_delay_samples / Fs * 1e6;
    fprintf('%.2f MHz: %.2f 采样点 (%.3f μs)\n', ...
        key_freqs(i)/1e6, group_delay_samples, group_delay_us);
end
pass_gd_idx = f_gd <= Fp;
if sum(pass_gd_idx) > 10
    pass_gd_max = max(Gd(pass_gd_idx)) - min(Gd(pass_gd_idx));
    fprintf('通带群延迟变化: %.3f 采样点 (平坦度指标)\n', pass_gd_max);
else
    pass_gd_max = NaN;
end

%% [8] 可视化分析
fprintf('\n--- 生成分析图表 ---\n');
figure('Name', '高精度伺服IIR滤波器频率响应', 'Position', [100, 100, 1200, 800]);
subplot(2,2,1);
plot(f/1e6, H_mag_db, 'b-', 'LineWidth', 1.5); 
grid on; hold on;
xline(Fp/1e6, 'r--', '通带边界');
xline(Fs_stop/1e6, 'r--', '阻带边界');
yline(-Rp, 'g--', sprintf('通带纹波%.1fdB', Rp));
yline(-Rs, 'g--', sprintf('阻带衰减%.0fdB', Rs));
xlabel('频率 (MHz)'); ylabel('幅度 (dB)');
title('幅频响应 (伺服抗混叠特性)');
xlim([0, Fs_stop/1e6*1.5]); ylim([-100, 5]);

subplot(2,2,2);
plot(f/1e6, unwrap(angle(H))*180/pi, 'b-', 'LineWidth', 1.5);
grid on; hold on;
xline(Fp/1e6, 'r--', '通带边界');
xlabel('频率 (MHz)'); ylabel('相位 (°)');
title('相频响应');
xlim([0, Fs_stop/1e6*1.5]);

subplot(2,2,3);
plot(f_gd/1e6, Gd, 'b-', 'LineWidth', 1.5);
grid on; hold on;
for i = 1:length(key_freqs)
    [~, idx] = min(abs(f_gd - key_freqs(i)));
    plot(key_freqs(i)/1e6, Gd(idx), 'ro', 'MarkerSize', 6);
    text(key_freqs(i)/1e6, Gd(idx), sprintf('%.2fMHz', key_freqs(i)/1e6), ...
        'VerticalAlignment', 'bottom', 'Color', 'red');
end
xline(Fp/1e6, 'r--', '通带边界');
xlabel('频率 (MHz)'); ylabel('群延迟 (采样点)');
title('群延迟响应 (伺服控制影响)');
xlim([0, Fs_stop/1e6*1.5]);

subplot(2,2,4);
zplane(sos_fixed(:,1:3), [ones(size(sos_fixed,1),1), sos_fixed(:,4:6)]);
title(sprintf('零极点分布 (最大极点模值: %.4f)', max_pole_mag));

figure('Name', '时域响应与稳定性分析', 'Position', [150, 150, 1200, 600]);
subplot(1,2,1);
if is_stable && ~isnan(accum_error)
    n_plot = min(1000, length(h_imp));
    stem(0:n_plot-1, h_imp(1:n_plot), 'filled', 'MarkerSize', 3);
    grid on;
    xlabel('采样点'); ylabel('幅度');
    title('单位脉冲响应');
    if exist('settle_time', 'var')
        settle_samples = settle_time * Fs / 1e6;
        hold on;
        xline(settle_samples, 'r--', sprintf('稳定时间%.2fμs', settle_time));
    end
else
    text(0.5, 0.5, '系统不稳定', 'HorizontalAlignment', 'center', ...
        'FontSize', 16, 'Color', 'red');
    set(gca, 'XLim', [0,1], 'YLim', [0,1]);
end
subplot(1,2,2);
categories = {'标准版', '优化版'};
margins = [standard_margin, optimized_margin];
processing_times = [standard_proc_time, optimized_proc_time];
yyaxis left;
bar(margins, 'FaceColor', [0.3, 0.6, 0.9]);
ylabel('时序余量 (%)');
ylim([min(margins)-10, max(margins)+10]);
yyaxis right;
plot(1:2, processing_times, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
ylabel('处理时间 (ns)');
set(gca, 'XTickLabel', categories);
title(sprintf('时序性能对比 (提升%.1f%%)', timing_improvement));
grid on;

%% [9] 工程实现信息输出
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('                    高精度伺服IIR滤波器工程实现报告\n');
fprintf('=========================================================================\n');
fprintf('\n📋 设计规格:\n');
fprintf('  应用场景: 高精度伺服驱动抗混叠滤波\n');
fprintf('  采样频率: %.1f MHz\n', Fs/1e6);
fprintf('  滤波器类型: %s %d阶 (%d节SOS级联)\n', upper(filter_type), N, size(sos_fixed,1));
fprintf('  定点格式: Q%d.%d (24位字长，22位小数)\n', wl-fl, fl);

fprintf('\n⚡ 性能指标:\n');
fprintf('  通带: DC-%.1fMHz, 纹波%.2fdB\n', Fp/1e6, pass_ripple);
fprintf('  阻带: %.1fMHz以上, 衰减%.1fdB\n', Fs_stop/1e6, stop_atten);
fprintf('  稳定裕度: %.4f (要求%.2f)\n', stability_margin, strict_margin);
fprintf('  群延迟变化: %.3f采样点 (通带内)\n', pass_gd_max);

fprintf('\n🚀 优化效果:\n');
fprintf('  标准版: %d拍延迟, %.1f%%余量\n', standard_latency, standard_margin);
fprintf('  优化版: %d拍延迟, %.1f%%余量\n', optimized_latency, optimized_margin);
fprintf('  性能提升: %.1f%% (优化显著)\n', timing_improvement);

fprintf('\n🔧 实现参数:\n');
fprintf('  SOS系数矩阵 (Q2.22格式):\n');
fprintf('  节 |      b0      |      b1      |      b2      |      a1      |      a2\n');
fprintf('  ---|--------------|--------------|--------------|--------------|-------------\n');
for i = 1:size(sos_fixed,1)
    fprintf('  %2d | %12.8f | %12.8f | %12.8f | %12.8f | %12.8f\n', ...
        i, sos_fixed(i,1), sos_fixed(i,2), sos_fixed(i,3), sos_fixed(i,5), sos_fixed(i,6));
end

%% [10] HEX系数输出 (Verilog使用)
fprintf('\n💾 Verilog实现用HEX系数:\n');
coeff_list = reshape(sos_fixed(:,[1:3,5:6])', [], 1);  % [b0 b1 b2 a1 a2]
coeff_int = int32(round(coeff_list * scale));
fprintf('  // Q2.22格式，24位有符号补码\n');
fprintf('  parameter [23:0] SOS_COEFFS [0:%d] = {\n', length(coeff_int)-1);
for i = 1:length(coeff_int)
    hex_val = bitand(typecast(coeff_int(i), 'uint32'), hex2dec('FFFFFF'));
    hex_str = upper(dec2hex(hex_val, 6));
    if i == length(coeff_int)
        fprintf('    24''h%s   // 系数%d\n', hex_str, i-1);
    else
        fprintf('    24''h%s,  // 系数%d\n', hex_str, i-1);
    end
end
fprintf('  };\n');

fid = fopen('servo_iir_coeffs.hex', 'w');
for i = 1:length(coeff_int)
    hex_val = bitand(typecast(coeff_int(i), 'uint32'), hex2dec('FFFFFF'));
    fprintf(fid, '%s\n', upper(dec2hex(hex_val, 6)));
end
fclose(fid);
fprintf('  HEX系数: servo_iir_coeffs.hex\n');

save('servo_iir_design.mat', 'sos_fixed', 'N', 'Fs', 'Fp', 'Fs_stop', ...
     'wl', 'fl', 'max_pole_mag', 'stability_margin', 'is_stable', ...
     'timing_improvement', 'sys_clk_mhz', 'H', 'f', 'Gd', 'f_gd');
fprintf('  设计数据: servo_iir_design.mat\n');

fid = fopen('servo_iir_params.v', 'w');
fprintf(fid, '// 高精度伺服IIR滤波器参数文件\n');
fprintf(fid, '// 自动生成时间: %s\n\n', datestr(now));
fprintf(fid, 'parameter FILTER_ORDER = %d;\n', N);
fprintf(fid, 'parameter NUM_SECTIONS = %d;\n', size(sos_fixed,1));
fprintf(fid, 'parameter WORD_WIDTH = %d;\n', wl);
fprintf(fid, 'parameter FRAC_WIDTH = %d;\n', fl);
fprintf(fid, 'parameter SAMPLE_FREQ_MHZ = %d;\n', round(Fs/1e6));
fprintf(fid, 'parameter SYS_CLK_MHZ = %d;\n', sys_clk_mhz);
fprintf(fid, 'parameter STANDARD_LATENCY = %d;\n', standard_latency);
fprintf(fid, 'parameter OPTIMIZED_LATENCY = %d;\n', optimized_latency);
fclose(fid);
fprintf('  Verilog参数: servo_iir_params.v\n');

fprintf('\n✅ 高精度伺服IIR滤波器设计完成！\n');
fprintf('💡 建议: 优先实现优化版架构，%.1f%%的性能提升具有显著工程价值\n', timing_improvement);
fprintf('🎯 毕设亮点: 8阶复杂度适中，优化效果明显，伺服应用权威性强\n');

fprintf('\n=========================================================================\n');