%% IIR滤波器测试信号生成脚本 (2_test_signal_gen.m)
% 功能：生成测试信号、产生参考输出、保存为RTL可用格式
% 这个脚本依赖于1_filter_design.m已经运行

close all;
clc;

fprintf('====================================================\n');
fprintf('       IIR滤波器测试信号生成工具 v1.0              \n');
fprintf('====================================================\n\n');

%% Step 1: 加载滤波器设计结果
fprintf('===== 步骤1: 加载滤波器设计结果 =====\n');

% 检查滤波器设计文件是否存在
if ~exist('filter_analysis.mat', 'file')
    error('找不到filter_analysis.mat文件。请先运行1_filter_design.m');
end

% 加载滤波器设计结果
load('filter_analysis.mat', 'sos', 'sorted_sos', 'transposed_sos', ...
     'fixed_coeffs', 'hex_coeffs', 'word_length', 'frac_length');

% 输出基本信息
fprintf('成功加载滤波器设计参数\n');
fprintf('SOS节点数: %d\n', size(sorted_sos, 1));
fprintf('定点化格式: Q%d.%d (总位数: %d)\n', word_length-frac_length-1, frac_length, word_length);

% 定义缩放因子
scale_factor = 2^frac_length;

%% Step 2: 设置测试参数
fprintf('\n===== 步骤2: 设置测试参数 =====\n');

% 采样频率设置 (确保与滤波器设计中的一致)
Fs = 122.88e6;  % 采样频率，122.88MHz

% 测试信号长度
num_samples = 2048;  % 可以根据需要调整

% 创建时间向量
t = (0:num_samples-1)/Fs;

% 探测滤波器类型和特性以生成合适的测试信号
filter_type = 'bandpass';  % 默认假设为带通滤波器
if mean(transposed_sos(:,1)) > 0.5
    % 通过查看b0系数大致判断滤波器类型
    % 如果大多数b0接近1，可能是带通或高通
    % 这只是一个粗略的估计，需要根据实际设计调整
    passband_center = Fs/4;  % 默认带通中心频率估计值
else
    filter_type = 'lowpass';  % 假设为低通
    passband_center = Fs/8;   % 默认低通截止频率估计值
end

fprintf('估计的滤波器类型: %s\n', filter_type);
fprintf('将生成适合此类型滤波器的测试信号\n');
fprintf('采样频率: %.2f MHz\n', Fs/1e6);
fprintf('测试信号长度: %d 样本\n', num_samples);

%% Step 3: 生成测试信号
fprintf('\n===== 步骤3: 生成测试信号 =====\n');

% 根据滤波器类型定义测试信号频率
if strcmp(filter_type, 'bandpass')
    % 带通滤波器测试信号
    % 定义多个测试频率：通带内和阻带内
    f_in_band1 = passband_center * 0.9;   % 通带内频率1
    f_in_band2 = passband_center * 1.1;   % 通带内频率2
    f_out_band1 = passband_center * 0.5;  % 阻带频率1
    f_out_band2 = passband_center * 1.5;  % 阻带频率2
else
    % 低通滤波器测试信号
    f_in_band1 = passband_center * 0.3;   % 通带内频率1
    f_in_band2 = passband_center * 0.7;   % 通带内频率2
    f_out_band1 = passband_center * 1.5;  % 阻带频率1
    f_out_band2 = passband_center * 2.0;  % 阻带频率2
end

% 生成组合测试信号
test_signal = 0.1 * ( ...
    sin(2*pi*f_in_band1*t) + ...
    sin(2*pi*f_in_band2*t) + ...
    0.5*sin(2*pi*f_out_band1*t) + ...
    0.5*sin(2*pi*f_out_band2*t) );

% 添加少量噪声使信号更真实
test_signal = test_signal + 0.01*randn(size(t));

% 将信号幅度限制在[-0.95, 0.95]范围内，避免溢出
max_amplitude = max(abs(test_signal));
if max_amplitude > 0.95
    test_signal = test_signal * (0.95 / max_amplitude);
end

fprintf('测试信号包含频率成分:\n');
fprintf('  通带内频率: %.2f MHz, %.2f MHz\n', f_in_band1/1e6, f_in_band2/1e6);
fprintf('  阻带内频率: %.2f MHz, %.2f MHz\n', f_out_band1/1e6, f_out_band2/1e6);
fprintf('  信号最大幅度: %.2f\n', max(abs(test_signal)));

% 绘制测试信号时域波形
figure('Name', '测试信号时域波形');
plot(t(1:min(500, end))*1e6, test_signal(1:min(500, end)));
title('测试信号时域波形 (前500个样本)');
xlabel('时间 (μs)');
ylabel('幅度');
grid on;

% 绘制测试信号频谱
figure('Name', '测试信号频谱');
[pxx, f] = periodogram(test_signal, hann(length(test_signal)), [], Fs);
plot(f/1e6, 10*log10(pxx));
title('测试信号频谱');
xlabel('频率 (MHz)');
ylabel('功率/频率 (dB/Hz)');
grid on;

%% Step 4: 定点化测试信号
fprintf('\n===== 步骤4: 定点化测试信号 =====\n');

% 定点化测试信号
test_signal_fixed = round(test_signal * scale_factor);
test_signal_fixed = max(min(test_signal_fixed, 2^(word_length-1)-1), -2^(word_length-1));

% 检查是否有溢出
if any(abs(test_signal) * scale_factor > 2^(word_length-1)-1)
    fprintf('警告: 测试信号在定点化过程中发生溢出\n');
    overflow_count = sum(abs(test_signal) * scale_factor > 2^(word_length-1)-1);
    fprintf('溢出样本数: %d (%.2f%%)\n', overflow_count, 100*overflow_count/num_samples);
else
    fprintf('测试信号成功定点化，无溢出\n');
end

%% Step 5: 创建基于定点系数的滤波器模型
fprintf('\n===== 步骤5: 创建定点滤波器模型 =====\n');

% 重建SOS格式，用于创建滤波器对象
sos_fixed = zeros(size(sorted_sos));
for i = 1:size(fixed_coeffs, 1)
    sos_fixed(i, 1:3) = fixed_coeffs(i, 1:3) / scale_factor;
    sos_fixed(i, 4) = 1;  % 添加a0=1
    sos_fixed(i, 5:6) = fixed_coeffs(i, 4:5) / scale_factor;
end

% 创建基于定点化系数的滤波器对象
Hd_fixed = dfilt.df2tsos(sos_fixed, 1);  % 增益已包含在系数中

fprintf('创建完成基于定点系数的滤波器模型\n');

%% Step 6: 生成滤波器参考输出
fprintf('\n===== 步骤6: 生成滤波器参考输出 =====\n');

% 方法1: 使用浮点滤波器对象和浮点输入
ref_output_float = filter(Hd_fixed, test_signal);

% 方法2: 手动实现定点滤波过程
ref_output_fixed_sim = zeros(size(test_signal));
states = zeros(size(fixed_coeffs, 1), 2);  % 每个SOS节点的2个状态变量

% 模拟定点实现的行为
for n = 1:length(test_signal)
    % 将浮点输入转为定点
    x_fixed = test_signal_fixed(n);
    
    % 通过所有SOS节点
    for i = 1:size(fixed_coeffs, 1)
        % 获取当前节点定点系数
        b0 = fixed_coeffs(i, 1);
        b1 = fixed_coeffs(i, 2);
        b2 = fixed_coeffs(i, 3);
        a1 = fixed_coeffs(i, 4);
        a2 = fixed_coeffs(i, 5);
        
        % 转置II型结构方程 (使用定点运算)
        % y = b0*x + s1
        prod_b0x = round((b0 * x_fixed) / scale_factor);
        y_fixed = min(max(prod_b0x + states(i, 1), -2^(word_length-1)), 2^(word_length-1)-1);
        
        % s1 = b1*x - a1*y + s2
        prod_b1x = round((b1 * x_fixed) / scale_factor);
        prod_a1y = round((a1 * y_fixed) / scale_factor);
        s1_new = min(max(prod_b1x - prod_a1y + states(i, 2), -2^(word_length-1)), 2^(word_length-1)-1);
        
        % s2 = b2*x - a2*y
        prod_b2x = round((b2 * x_fixed) / scale_factor);
        prod_a2y = round((a2 * y_fixed) / scale_factor);
        s2_new = min(max(prod_b2x - prod_a2y, -2^(word_length-1)), 2^(word_length-1)-1);
        
        % 更新状态
        states(i, 1) = s1_new;
        states(i, 2) = s2_new;
        
        % 输出传递到下一个节点
        x_fixed = y_fixed;
    end
    
    % 保存定点滤波输出
    ref_output_fixed_sim(n) = x_fixed;
end

% 将定点模拟结果转回浮点以便比较和可视化
ref_output_fixed_float = ref_output_fixed_sim / scale_factor;

% 绘制参考输出
figure('Name', '滤波器参考输出');
subplot(2,1,1);
plot(t(1:min(500, end))*1e6, ref_output_float(1:min(500, end)));
title('浮点滤波器输出 (前500个样本)');
xlabel('时间 (μs)');
ylabel('幅度');
grid on;

subplot(2,1,2);
plot(t(1:min(500, end))*1e6, ref_output_fixed_float(1:min(500, end)));
title('定点模拟滤波器输出 (前500个样本)');
xlabel('时间 (μs)');
ylabel('幅度');
grid on;

% 比较两种方法的差异
error_fixed_vs_float = ref_output_fixed_float - ref_output_float;
max_error = max(abs(error_fixed_vs_float));
mean_error = mean(abs(error_fixed_vs_float));

fprintf('定点模拟与浮点实现对比:\n');
fprintf('  最大误差: %.10f\n', max_error);
fprintf('  平均误差: %.10f\n', mean_error);

% 选择定点模拟作为RTL参考输出
ref_output = ref_output_fixed_sim;

%% Step 7: 保存测试信号和参考输出
fprintf('\n===== 步骤7: 保存测试信号和参考输出 =====\n');

% 准备十六进制格式的测试信号
test_signal_hex = cell(num_samples, 1);
for i = 1:num_samples
    val = test_signal_fixed(i);
    if val < 0
        val = 2^word_length + val;  % 转换为二进制补码表示
    end
    test_signal_hex{i} = sprintf('%04X', val);
end

% 准备十六进制格式的参考输出
ref_output_hex = cell(num_samples, 1);
for i = 1:num_samples
    val = ref_output(i);
    if val < 0
        val = 2^word_length + val;  % 转换为二进制补码表示
    end
    ref_output_hex{i} = sprintf('%04X', val);
end

% 保存测试信号
test_signal_file = 'test_signal.hex';
fid = fopen(test_signal_file, 'w');
fprintf(fid, '// 测试信号 - 格式Q%d.%d (%d样本)\n', word_length-frac_length-1, frac_length, num_samples);
for i = 1:num_samples
    fprintf(fid, '%s\n', test_signal_hex{i});
end
fclose(fid);

% 保存参考输出
ref_output_file = 'reference_output.hex';
fid = fopen(ref_output_file, 'w');
fprintf(fid, '// 参考输出 - 格式Q%d.%d (%d样本)\n', word_length-frac_length-1, frac_length, num_samples);
for i = 1:num_samples
    fprintf(fid, '%s\n', ref_output_hex{i});
end
fclose(fid);

% 保存测试信号和参考输出数据
save('test_data.mat', 'test_signal', 'test_signal_fixed', 'ref_output', ...
     'ref_output_float', 'ref_output_fixed_float', 't', 'Fs');

fprintf('测试信号已保存到 %s\n', test_signal_file);
fprintf('参考输出已保存到 %s\n', ref_output_file);
fprintf('测试数据已保存到 test_data.mat\n');

%% Step 8: 生成测试信号和参考输出摘要
fprintf('\n===== 步骤8: 测试信号和参考输出摘要 =====\n');

% 计算测试信号统计信息
test_signal_stats = struct();
test_signal_stats.min = min(test_signal);
test_signal_stats.max = max(test_signal);
test_signal_stats.mean = mean(test_signal);
test_signal_stats.std = std(test_signal);

% 计算参考输出统计信息
ref_output_stats = struct();
ref_output_stats.min = min(ref_output_fixed_float);
ref_output_stats.max = max(ref_output_fixed_float);
ref_output_stats.mean = mean(ref_output_fixed_float);
ref_output_stats.std = std(ref_output_fixed_float);

fprintf('测试信号统计信息:\n');
fprintf('  最小值: %.6f\n', test_signal_stats.min);
fprintf('  最大值: %.6f\n', test_signal_stats.max);
fprintf('  平均值: %.6f\n', test_signal_stats.mean);
fprintf('  标准差: %.6f\n', test_signal_stats.std);

fprintf('参考输出统计信息:\n');
fprintf('  最小值: %.6f\n', ref_output_stats.min);
fprintf('  最大值: %.6f\n', ref_output_stats.max);
fprintf('  平均值: %.6f\n', ref_output_stats.mean);
fprintf('  标准差: %.6f\n', ref_output_stats.std);

% 计算滤波器在测试信号上的通带增益
[pxx_in, f_in] = periodogram(test_signal, hann(length(test_signal)), [], Fs);
[pxx_out, f_out] = periodogram(ref_output_fixed_float, hann(length(ref_output_fixed_float)), [], Fs);

% 找出通带内的能量比例
if strcmp(filter_type, 'bandpass')
    inband_idx = (f_in >= f_in_band1 & f_in <= f_in_band2);
else
    inband_idx = f_in <= passband_center;
end

inband_power_in = sum(pxx_in(inband_idx));
inband_power_out = sum(pxx_out(inband_idx));
inband_gain_db = 10*log10(inband_power_out / inband_power_in);

fprintf('通带内增益: %.2f dB\n', inband_gain_db);

fprintf('\n====================================================\n');
fprintf('测试信号生成完成。使用生成的测试信号和参考输出验证您的RTL设计。\n');
fprintf('====================================================\n');