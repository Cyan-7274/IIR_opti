%% IIR滤波器仿真结果验证脚本 (3_compare_results.m)
% 功能：比较RTL仿真输出与MATLAB参考输出，进行误差分析
% 这个脚本依赖于前两个脚本已经运行生成的文件

close all;
clc;

fprintf('====================================================\n');
fprintf('       IIR滤波器仿真结果验证工具 v1.0              \n');
fprintf('====================================================\n\n');

%% Step 1: 加载参考输出和测试数据
fprintf('===== 步骤1: 加载参考数据 =====\n');

% 检查必要的文件是否存在
if ~exist('filter_analysis.mat', 'file') || ~exist('test_data.mat', 'file')
    error('找不到必要的数据文件。请先运行1_filter_design.m和2_test_signal_gen.m');
end

% 加载滤波器设计结果
load('filter_analysis.mat', 'word_length', 'frac_length');
% 加载测试数据
load('test_data.mat', 'test_signal', 'test_signal_fixed', 'ref_output', ...
     'ref_output_float', 'ref_output_fixed_float', 't', 'Fs');

% 定义缩放因子
scale_factor = 2^frac_length;

fprintf('成功加载参考数据\n');
fprintf('测试信号长度: %d 样本\n', length(test_signal));
fprintf('定点化格式: Q%d.%d (总位数: %d)\n', word_length-frac_length-1, frac_length, word_length);

%% Step 2: 读取RTL仿真结果
fprintf('\n===== 步骤2: 读取RTL仿真结果 =====\n');

% 提示用户输入RTL仿真结果文件路径
rtl_output_file = input('请输入RTL仿真结果文件路径 (按回车使用默认值"simulation_output.txt"): ', 's');
if isempty(rtl_output_file)
    rtl_output_file = 'simulation_output.txt';
end

% 检查文件是否存在
if ~exist(rtl_output_file, 'file')
    error('找不到RTL仿真输出文件: %s', rtl_output_file);
end

% 读取RTL仿真输出
try
    % 尝试使用textscan读取文件
    fid = fopen(rtl_output_file, 'r');
    sim_output_raw = textscan(fid, '%s');
    fclose(fid);
    sim_output_raw = sim_output_raw{1};
    
    % 移除可能存在的注释行或空行
    sim_output_hex = {};
    for i = 1:length(sim_output_raw)
        line = strtrim(sim_output_raw{i});
        % 跳过空行和注释行
        if ~isempty(line) && line(1) ~= '/' && line(1) ~= '#'
            % 提取十六进制值（如果行包含额外信息，假设前4-8个字符是十六进制值）
            if length(line) >= 4
                % 匹配行中的十六进制格式
                matches = regexp(line, '[0-9A-Fa-f]{4,8}', 'match');
                if ~isempty(matches)
                    % 只取第一个匹配的十六进制数
                    sim_output_hex{end+1} = matches{1};
                end
            end
        end
    end
    
    fprintf('成功从文件读取 %d 个RTL仿真输出样本\n', length(sim_output_hex));
catch
    error('读取RTL仿真输出文件失败: %s', lasterr);
end

%% Step 3: 将十六进制RTL输出转换为数值
fprintf('\n===== 步骤3: 处理RTL仿真输出 =====\n');

% 初始化RTL仿真结果数组
rtl_output = zeros(length(sim_output_hex), 1);

% 转换十六进制到定点数值
for i = 1:length(sim_output_hex)
    % 从十六进制字符串转换为整数
    val = hex2dec(sim_output_hex{i});
    
    % 进行二进制补码转换
    if val >= 2^(word_length-1)
        val = val - 2^word_length;
    end
    
    % 存储值
    rtl_output(i) = val;
end

% 将定点结果转回浮点以便比较
rtl_output_float = rtl_output / scale_factor;

% 检查值的范围
fprintf('RTL输出值范围:\n');
fprintf('  最小值: %d (%.6f)\n', min(rtl_output), min(rtl_output_float));
fprintf('  最大值: %d (%.6f)\n', max(rtl_output), max(rtl_output_float));
fprintf('  平均值: %.2f (%.6f)\n', mean(rtl_output), mean(rtl_output_float));

%% Step 4: 比较参考输出和RTL仿真输出
fprintf('\n===== 步骤4: 比较参考输出和RTL仿真输出 =====\n');

% 确定可用的比较样本数
num_compare = min(length(ref_output), length(rtl_output));
fprintf('将比较 %d 个样本\n', num_compare);

% 截取相同长度的段用于比较
ref_compare = ref_output(1:num_compare);
rtl_compare = rtl_output(1:num_compare);
ref_float_compare = ref_output_fixed_float(1:num_compare);
rtl_float_compare = rtl_output_float(1:num_compare);

% 计算误差 (定点值)
error_fixed = ref_compare - rtl_compare;
% 计算误差 (浮点值)
error_float = ref_float_compare - rtl_float_compare;

% 计算误差指标
max_abs_error_fixed = max(abs(error_fixed));
mean_abs_error_fixed = mean(abs(error_fixed));
rms_error_fixed = sqrt(mean(error_fixed.^2));

max_abs_error_float = max(abs(error_float));
mean_abs_error_float = mean(abs(error_float));
rms_error_float = sqrt(mean(error_float.^2));

% 计算信噪比 (SNR)
signal_power = mean(ref_float_compare.^2);
noise_power = mean(error_float.^2);
snr_db = 10*log10(signal_power/noise_power);

% 计算准确匹配的样本百分比
exact_match_count = sum(error_fixed == 0);
exact_match_percent = 100 * exact_match_count / num_compare;

% 计算在±1LSB误差范围内的样本百分比
within_1lsb_count = sum(abs(error_fixed) <= 1);
within_1lsb_percent = 100 * within_1lsb_count / num_compare;

% 输出误差统计
fprintf('误差统计 (定点值):\n');
fprintf('  最大绝对误差: %d\n', max_abs_error_fixed);
fprintf('  平均绝对误差: %.2f\n', mean_abs_error_fixed);
fprintf('  均方根误差 (RMS): %.2f\n', rms_error_fixed);
fprintf('  精确匹配样本: %d (%.2f%%)\n', exact_match_count, exact_match_percent);
fprintf('  ±1 LSB内样本: %d (%.2f%%)\n', within_1lsb_count, within_1lsb_percent);

fprintf('\n误差统计 (浮点等效值):\n');
fprintf('  最大绝对误差: %.10f\n', max_abs_error_float);
fprintf('  平均绝对误差: %.10f\n', mean_abs_error_float);
fprintf('  均方根误差 (RMS): %.10f\n', rms_error_float);
fprintf('  信噪比 (SNR): %.2f dB\n', snr_db);

% 确定验证结果
if exact_match_percent >= 99
    fprintf('\n✅ 验证结果: 优秀 (99%%以上样本完全匹配)\n');
elseif within_1lsb_percent >= 99
    fprintf('\n✅ 验证结果: 良好 (99%%以上样本在±1 LSB误差范围内)\n');
elseif within_1lsb_percent >= 95
    fprintf('\n✅ 验证结果: 合格 (95%%以上样本在±1 LSB误差范围内)\n');
elseif snr_db >= 40
    fprintf('\n🟡 验证结果: 需要调查 (SNR > 40dB，但精确匹配率较低)\n');
else
    fprintf('\n❌ 验证结果: 需要修正 (误差较大)\n');
end

%% Step 5: 可视化比较结果
fprintf('\n===== 步骤5: 可视化比较结果 =====\n');

% 创建时间向量用于绘图
if length(t) >= num_compare
    t_compare = t(1:num_compare);
else
    t_compare = (0:num_compare-1)/Fs;
end

% 绘制输出信号比较
figure('Name', '输出信号比较', 'Position', [100, 100, 900, 700]);

% 绘制前100个样本的详细比较
subplot(3, 1, 1);
samples_to_plot = min(100, num_compare);
plot(t_compare(1:samples_to_plot)*1e6, ref_float_compare(1:samples_to_plot), 'b.-', 'LineWidth', 1);
hold on;
plot(t_compare(1:samples_to_plot)*1e6, rtl_float_compare(1:samples_to_plot), 'r.-', 'LineWidth', 1);
title('参考输出 vs RTL输出 (前100个样本)');
xlabel('时间 (μs)');
ylabel('幅度');
legend('参考输出', 'RTL输出');
grid on;

% 绘制全部样本的概览
subplot(3, 1, 2);
plot(t_compare*1e6, ref_float_compare, 'b', 'LineWidth', 1);
hold on;
plot(t_compare*1e6, rtl_float_compare, 'r--', 'LineWidth', 1);
title(sprintf('参考输出 vs RTL输出 (全部%d个样本)', num_compare));
xlabel('时间 (μs)');
ylabel('幅度');
legend('参考输出', 'RTL输出');
grid on;

% 绘制误差
subplot(3, 1, 3);
plot(t_compare*1e6, error_float, 'k');
title('误差 (参考输出 - RTL输出)');
xlabel('时间 (μs)');
ylabel('误差幅度');
grid on;

% 添加误差范围辅助线 (±1 LSB)
hold on;
yline(1/scale_factor, 'r--', '+1 LSB');
yline(-1/scale_factor, 'r--', '-1 LSB');
ylim([-5/scale_factor, 5/scale_factor]);  % 限制Y轴范围以便观察

% 绘制频谱比较
figure('Name', '频谱比较', 'Position', [100, 100, 900, 500]);

% 计算功率谱密度
window = hann(min(1024, num_compare));
nfft = max(1024, 2^nextpow2(length(window)));
[pxx_ref, f] = pwelch(ref_float_compare, window, round(length(window)/2), nfft, Fs);
[pxx_rtl, ~] = pwelch(rtl_float_compare, window, round(length(window)/2), nfft, Fs);

% 绘制线性频率刻度的频谱
subplot(2, 1, 1);
plot(f/1e6, 10*log10(pxx_ref), 'b', 'LineWidth', 1.5);
hold on;
plot(f/1e6, 10*log10(pxx_rtl), 'r--', 'LineWidth', 1.5);
title('功率谱密度比较');
xlabel('频率 (MHz)');
ylabel('功率/频率 (dB/Hz)');
legend('参考输出', 'RTL输出', 'Location', 'best');
grid on;

% 绘制对数频率刻度的频谱（更容易观察低频部分）
subplot(2, 1, 2);
semilogx(f/1e6, 10*log10(pxx_ref), 'b', 'LineWidth', 1.5);
hold on;
semilogx(f/1e6, 10*log10(pxx_rtl), 'r--', 'LineWidth', 1.5);
title('功率谱密度比较 (对数频率刻度)');
xlabel('频率 (MHz)');
ylabel('功率/频率 (dB/Hz)');
legend('参考输出', 'RTL输出', 'Location', 'best');
grid on;
xlim([0.01, Fs/2/1e6]); % 设置X轴范围从0.01MHz到奈奎斯特频率

%% Step 6: 误差分布分析
fprintf('\n===== 步骤6: 误差分布分析 =====\n');

% 分析误差的分布
figure('Name', '误差分布分析', 'Position', [100, 100, 900, 400]);

% 计算误差直方图
subplot(1, 2, 1);
histogram(error_fixed, min(-10, max(-10, floor(min(error_fixed)))):1:max(10, ceil(max(error_fixed))));
title('误差直方图（定点值）');
xlabel('误差 (定点单位)');
ylabel('样本数');
grid on;

% 计算误差累积分布
subplot(1, 2, 2);
[counts, edges] = histcounts(abs(error_fixed), 0:1:max(20, ceil(max(abs(error_fixed)))));
cumulative = cumsum(counts) / sum(counts) * 100;
bar(edges(1:end-1), cumulative, 1);
title('累积误差分布');
xlabel('绝对误差 (定点单位)');
ylabel('样本百分比 (%)');
grid on;
ylim([0, 100]);

% 分析误差是否与输入信号或输出信号幅度相关
figure('Name', '误差相关性分析', 'Position', [100, 100, 900, 400]);

% 误差与输出幅度的关系
subplot(1, 2, 1);
scatter(abs(ref_float_compare), abs(error_float), 2, 'filled', 'MarkerFaceAlpha', 0.3);
title('误差与参考输出幅度关系');
xlabel('参考输出幅度（绝对值）');
ylabel('误差幅度（绝对值）');
grid on;

% 计算误差与参考输出幅度的相关性
correlation = corrcoef(abs(ref_float_compare), abs(error_float));
fprintf('误差与参考输出幅度的相关系数: %.4f\n', correlation(1,2));

% 误差自相关分析
subplot(1, 2, 2);
[autocorr_vals, lags] = xcorr(error_float, 50, 'coeff');
stem(lags, autocorr_vals);
title('误差自相关');
xlabel('延迟 (样本)');
ylabel('相关系数');
grid on;
xlim([-50, 50]);

%% Step 7: 稳定时间分析
fprintf('\n===== 步骤7: 稳定时间分析 =====\n');

% 分析系统达到稳定状态所需的时间
% 计算滑动窗口均方误差
window_size = 20;  % 滑动窗口大小
sliding_mse = zeros(num_compare-window_size+1, 1);

for i = 1:length(sliding_mse)
    window_error = error_float(i:i+window_size-1);
    sliding_mse(i) = mean(window_error.^2);
end

% 寻找误差稳定的点（定义为MSE降低到稳态值的105%以内）
stable_mse = mean(sliding_mse(end-min(100, length(sliding_mse)/5):end));  % 使用最后部分的平均MSE作为稳态参考
threshold = 1.05 * stable_mse;

% 从头开始找到第一个低于阈值的点
settling_idx = 1;
for i = 1:length(sliding_mse)
    if sliding_mse(i) <= threshold
        settling_idx = i;
        break;
    end
end

% 绘制滑动MSE和稳定时间点
figure('Name', '稳定时间分析', 'Position', [100, 100, 900, 400]);
plot((window_size:num_compare)*1e6/Fs, sliding_mse);
hold on;
yline(threshold, 'r--', '稳定阈值');
xline(settling_idx*1e6/Fs, 'g--', '稳定时间点');
title('滑动窗口均方误差 (MSE)');
xlabel('时间 (μs)');
ylabel('MSE');
grid on;
set(gca, 'YScale', 'log');  % 使用对数刻度以便更好地观察误差变化

fprintf('稳定时间分析结果:\n');
fprintf('  稳态MSE: %.10f\n', stable_mse);
fprintf('  稳定阈值 (1.05 × 稳态MSE): %.10f\n', threshold);
fprintf('  稳定时间点: %d 样本 (%.2f μs)\n', settling_idx, settling_idx*1e6/Fs);

%% Step 8: 保存分析结果
fprintf('\n===== 步骤8: 保存分析结果 =====\n');

% 创建结构体存储验证结果
validation_results = struct();
validation_results.timestamp = datestr(now);
validation_results.num_samples = num_compare;
validation_results.exact_match_percent = exact_match_percent;
validation_results.within_1lsb_percent = within_1lsb_percent;
validation_results.max_abs_error = max_abs_error_fixed;
validation_results.mean_abs_error = mean_abs_error_fixed;
validation_results.rms_error = rms_error_fixed;
validation_results.snr_db = snr_db;
validation_results.settling_time = settling_idx;

% 保存验证结果
save('validation_results.mat', 'validation_results', 'ref_compare', 'rtl_compare', ...
     'error_fixed', 'error_float', 'sliding_mse', 'settling_idx');

% 保存总结报告
fid = fopen('validation_report.txt', 'w');
fprintf(fid, '============================================\n');
fprintf(fid, 'IIR滤波器RTL实现验证报告\n');
fprintf(fid, '============================================\n\n');
fprintf(fid, '生成时间: %s\n\n', datestr(now));

fprintf(fid, '验证参数:\n');
fprintf(fid, '  比较样本数: %d\n', num_compare);
fprintf(fid, '  定点格式: Q%d.%d (总位数: %d)\n', word_length-frac_length-1, frac_length, word_length);
fprintf(fid, '  参考输出文件: reference_output.hex\n');
fprintf(fid, '  RTL仿真输出文件: %s\n\n', rtl_output_file);

fprintf(fid, '验证结果:\n');
fprintf(fid, '  精确匹配样本: %.2f%%\n', exact_match_percent);
fprintf(fid, '  ±1 LSB内样本: %.2f%%\n', within_1lsb_percent);
fprintf(fid, '  最大绝对误差: %d (%.10f)\n', max_abs_error_fixed, max_abs_error_float);
fprintf(fid, '  平均绝对误差: %.2f (%.10f)\n', mean_abs_error_fixed, mean_abs_error_float);
fprintf(fid, '  均方根误差: %.2f (%.10f)\n', rms_error_fixed, rms_error_float);
fprintf(fid, '  信噪比: %.2f dB\n', snr_db);
fprintf(fid, '  稳定时间: %d 样本 (%.2f μs)\n\n', settling_idx, settling_idx*1e6/Fs);

% 添加总体结论
if exact_match_percent >= 99
    fprintf(fid, '总体结论: 优秀 (99%%以上样本完全匹配)\n');
elseif within_1lsb_percent >= 99
    fprintf(fid, '总体结论: 良好 (99%%以上样本在±1 LSB误差范围内)\n');
elseif within_1lsb_percent >= 95
    fprintf(fid, '总体结论: 合格 (95%%以上样本在±1 LSB误差范围内)\n');
elseif snr_db >= 40
    fprintf(fid, '总体结论: 需要调查 (SNR > 40dB，但精确匹配率较低)\n');
else
    fprintf(fid, '总体结论: 需要修正 (误差较大)\n');
end

% 添加建议
fprintf(fid, '\n建议:\n');
if exact_match_percent < 99 && within_1lsb_percent >= 99
    fprintf(fid, '- LSB误差可能是由舍入模式不一致导致，检查RTL舍入实现\n');
end
if snr_db < 40
    fprintf(fid, '- 检查是否存在系数转换错误或数据流路径问题\n');
    fprintf(fid, '- 确认定点化位宽和小数位配置一致\n');
    fprintf(fid, '- 检查SOS节顺序是否正确配置\n');
end
if settling_idx > 50
    fprintf(fid, '- 初始状态可能需要调整，当前稳定时间较长\n');
end

fclose(fid);

fprintf('分析结果已保存到 validation_results.mat\n');
fprintf('验证报告已保存到 validation_report.txt\n');

fprintf('\n====================================================\n');
fprintf('RTL实现验证完成。请查看生成的图表和报告以获取详细结果。\n');
fprintf('====================================================\n');