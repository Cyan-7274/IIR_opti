%% IIR滤波器设计与分析主脚本 (1_filter_design.m)
% 功能：SOS结构椭圆滤波器设计、定点化处理、全面分析
% 这个脚本负责滤波器的基础设计和分析，包括：
% 1. 滤波器参数设计
% 2. SOS节点顺序分析
% 3. 稳定性分析
% 4. 转置II型结构转换
% 5. 增益分配策略分析与选择
% 6. 定点化参数分析与定点化实现
% 7. 结果保存

clear all;
close all;
clc;

fprintf('====================================================\n');
fprintf('       高速IIR滤波器设计与分析工具 v1.0            \n');
fprintf('====================================================\n\n');

%% Step 1: 滤波器设计参数设置
fprintf('===== 步骤1: 滤波器设计参数设置 =====\n');

% 可以根据需要修改滤波器类型：'lowpass', 'highpass', 'bandpass', 'bandstop'
filter_type = 'bandpass';

% 采样频率
Fs = 122.88e6; % 122.88 MHz

% 滤波器规格
if strcmp(filter_type, 'bandpass')
    % 带通滤波器参数
    Fp1 = 20.72e6; Fp2 = 40.72e6;  % 通带边界 (Hz)
    Fs1 = 18.72e6; Fs2 = 42.72e6;  % 阻带边界 (Hz)
    Wp = [Fp1 Fp2]/(Fs/2);
    Ws = [Fs1 Fs2]/(Fs/2);
elseif strcmp(filter_type, 'lowpass')
    % 低通滤波器参数
    Fp = 6e6;      % 通带边界 (Hz)
    Fs_edge = 12e6; % 阻带边界 (Hz)
    Wp = Fp/(Fs/2);
    Ws = Fs_edge/(Fs/2);
end

% 通带纹波和阻带衰减
Rp = 1;    % 通带纹波 (dB)
Rs = 50;   % 阻带衰减 (dB)

% 打印滤波器设计参数
fprintf('滤波器类型: %s\n', filter_type);
fprintf('采样频率: %.2f MHz\n', Fs/1e6);
if strcmp(filter_type, 'bandpass')
    fprintf('通带: %.2f - %.2f MHz\n', Fp1/1e6, Fp2/1e6);
    fprintf('阻带: < %.2f MHz, > %.2f MHz\n', Fs1/1e6, Fs2/1e6);
elseif strcmp(filter_type, 'lowpass')
    fprintf('通带: < %.2f MHz\n', Fp/1e6);
    fprintf('阻带: > %.2f MHz\n', Fs_edge/1e6);
end
fprintf('通带纹波: %.1f dB, 阻带衰减: %.1f dB\n', Rp, Rs);

%% Step 2: 滤波器设计
fprintf('\n===== 步骤2: 滤波器设计 =====\n');
% 计算滤波器阶数
[N, Wn] = ellipord(Wp, Ws, Rp, Rs);

% 设计椭圆滤波器
[B, A] = ellip(N, Rp, Rs, Wn, filter_type);

% 转换为Second-Order Sections (SOS)结构
[sos, g] = tf2sos(B, A);

fprintf('滤波器阶数: %d\n', N);
fprintf('SOS节点数: %d\n', size(sos, 1));
fprintf('初始增益g: %.10f\n', g);

% 创建滤波器对象 - 使用转置II型结构
Hd = dfilt.df2tsos(sos, g);

%% Step 3: 极点零点分析
fprintf('\n===== 步骤3: 极点零点与稳定性分析 =====\n');
% 获取滤波器零极点
[z, p, k] = sos2zp(sos, g);

% 绘制零极点图
figure('Name', '零极点图');
zplane(z, p);
title('滤波器零极点图');
grid on;

% 分析整体滤波器稳定性
fprintf('整体滤波器极点分析:\n');
fprintf('最大极点模: %.10f (稳定条件: <1)\n', max(abs(p)));

if max(abs(p)) >= 1
    warning('滤波器不稳定！极点在单位圆外。');
elseif max(abs(p)) >= 0.99
    warning('滤波器极点非常接近单位圆，量化后可能不稳定。');
end

%% Step 4: SOS节点稳定性分析与排序
fprintf('\n===== 步骤4: SOS节点稳定性分析与排序 =====\n');

N_sections = size(sos, 1);
section_poles = cell(N_sections, 1);
pole_mags = zeros(N_sections, 1);

fprintf('各SOS节点稳定性分析:\n');
for i = 1:N_sections
    b_sec = sos(i, 1:3);
    a_sec = [1, sos(i, 4:6)];
    
    [z_sec, p_sec, k_sec] = tf2zp(b_sec, a_sec);
    section_poles{i} = p_sec;
    pole_mags(i) = max(abs(p_sec));
    
    fprintf('SOS节点 %d:\n', i);
    fprintf('  系数: b0=%.6f, b1=%.6f, b2=%.6f, a1=%.6f, a2=%.6f\n', ...
        b_sec(1), b_sec(2), b_sec(3), a_sec(2), a_sec(3));
    fprintf('  零点: ');
    for j = 1:length(z_sec)
        fprintf('%.6f + %.6fi (|z|=%.6f)', real(z_sec(j)), imag(z_sec(j)), abs(z_sec(j)));
        if j < length(z_sec), fprintf(', '); end
    end
    fprintf('\n');
    
    fprintf('  极点: ');
    for j = 1:length(p_sec)
        fprintf('%.6f + %.6fi (|p|=%.6f)', real(p_sec(j)), imag(p_sec(j)), abs(p_sec(j)));
        if j < length(p_sec), fprintf(', '); end
    end
    fprintf('\n');
    
    fprintf('  最大极点模: %.10f ', pole_mags(i));
    if pole_mags(i) >= 0.99
        fprintf('(警告: 接近不稳定)\n');
    else
        fprintf('(稳定)\n');
    end
end

% 按极点模排序
[sorted_mags, sort_idx] = sort(pole_mags, 'descend');

fprintf('\nSOS节点排序 (按极点模值从大到小):\n');
for i = 1:N_sections
    fprintf('节点排序 #%d: 原始序号 %d, 极点模 = %.10f\n', i, sort_idx(i), sorted_mags(i));
end

% 重新排列SOS节点
sorted_sos = sos(sort_idx, :);

%% Step 5: 转置II型结构系数提取
fprintf('\n===== 步骤5: 转置II型结构系数提取 =====\n');

% 检查当前SOS格式
fprintf('SOS矩阵格式: [b0, b1, b2, 1, a1, a2]\n');
fprintf('转置II型需要的格式: [b0, b1, b2, a1, a2]\n');

% 提取转置II型结构所需系数 [b0, b1, b2, a1, a2]
transposed_sos = sorted_sos(:, [1 2 3 5 6]);

% 显示转置II型结构系数
fprintf('转置II型结构系数 (排序后):\n');
fprintf('节点\tb0\t\tb1\t\tb2\t\ta1\t\ta2\n');
for i = 1:N_sections
    fprintf('%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n', i, ...
        transposed_sos(i,1), transposed_sos(i,2), transposed_sos(i,3), ...
        transposed_sos(i,4), transposed_sos(i,5));
end

%% Step 6: 增益分配策略分析
fprintf('\n===== 步骤6: 增益分配策略分析 =====\n');

% 检查是否有缩放值
try
    % 尝试直接从滤波器对象获取缩放值
    scaleValues = Hd.ScaleValues;
    fprintf('从滤波器对象获取缩放值成功\n');
    for i = 1:length(scaleValues)
        fprintf('缩放值 %d: %.10f\n', i, scaleValues(i));
    end
    
    % 总增益
    overall_gain = prod(scaleValues);
    fprintf('总增益 (所有缩放值的乘积): %.10f\n', overall_gain);
catch
    % 如果失败，使用传递函数增益
    fprintf('无法获取滤波器对象缩放值，使用传递函数增益g代替\n');
    fprintf('总增益g: %.10f\n', g);
    overall_gain = g;
end

% 分析三种不同的增益分配策略
fprintf('\n增益分配策略分析:\n');

% 策略1: 将总增益应用到最后一个节点
trans_sos_strategy1 = transposed_sos;
trans_sos_strategy1(end,1:3) = trans_sos_strategy1(end,1:3) * overall_gain;

% 策略2: 将总增益均匀分布到所有节点
root_gain = nthroot(overall_gain, N_sections);
trans_sos_strategy2 = transposed_sos;
for i = 1:N_sections
    trans_sos_strategy2(i,1:3) = trans_sos_strategy2(i,1:3) * root_gain;
end

% 策略3: 将总增益作为独立系数
trans_sos_strategy3 = transposed_sos;
final_gain_factor = overall_gain;

fprintf('策略1 - 增益应用到最后节点 (%.10f):\n', overall_gain);
fprintf('  优点: 简单，只修改一个节点\n');
fprintf('  缺点: 可能导致该节点的系数过大或过小\n');

fprintf('\n策略2 - 增益均匀分布到所有节点 (每节点 %.10f):\n', root_gain);
fprintf('  优点: 避免任一节点系数过大，更均衡的范围\n');
fprintf('  缺点: 实现时需要修改所有节点的系数\n');

fprintf('\n策略3 - 使用独立增益系数 (%.10f):\n', final_gain_factor);
fprintf('  优点: SOS节点保持原样，便于调整\n');
fprintf('  缺点: 需要额外的乘法器\n');

% 打印系数的范围，以便后续定点化分析
max_coef1 = max(abs(trans_sos_strategy1(:)));
max_coef2 = max(abs(trans_sos_strategy2(:)));

fprintf('\n各策略系数范围:\n');
fprintf('  策略1 - 最大系数绝对值: %.10f\n', max_coef1);
fprintf('  策略2 - 最大系数绝对值: %.10f\n', max_coef2);
fprintf('  策略3 - 增益系数值: %.10f\n', final_gain_factor);

% 基于分析选择最佳策略（通常是策略2）
fprintf('\n基于分析选择策略2 - 增益均匀分布\n');
transposed_sos = trans_sos_strategy2;
fprintf('采用的最大系数绝对值: %.10f\n', max_coef2);

%% Step 7: 定点化格式分析
fprintf('\n===== 步骤7: 定点化格式分析 =====\n');

% 分析不同的定点格式
formats_to_try = {
    {16, 14, 'Q1.14'}, % 总位宽，小数位宽，格式名称
    {16, 13, 'Q2.13'},
    {16, 12, 'Q3.12'},
    {16, 15, 'Q0.15'}
};

% 找出最大系数值用于定点化分析
max_coef = max(abs(transposed_sos(:)));
fprintf('增益分配后最大系数绝对值: %.10f\n', max_coef);

for fmt_idx = 1:length(formats_to_try)
    format_info = formats_to_try{fmt_idx};
    word_length = format_info{1};
    frac_length = format_info{2};
    format_name = format_info{3};
    
    % 计算可表示范围
    scale_factor = 2^frac_length;
    int_bits = word_length - frac_length - 1; % 减去符号位
    min_val = -2^int_bits;
    max_val = 2^int_bits - 2^(-frac_length);
    
    fprintf('\n%s格式分析 - 位宽:%d, 小数位:%d\n', format_name, word_length, frac_length);
    fprintf('表示范围: [%.10f, %.10f]\n', min_val, max_val);
    
    % 检查系数是否超出范围
    if max_coef > max_val
        fprintf('警告: 系数超出%s格式表示范围!\n', format_name);
        
        % 找出超出范围的系数
        out_of_range_count = 0;
        for i = 1:N_sections
            for j = 1:5
                if abs(transposed_sos(i,j)) > max_val
                    if out_of_range_count < 3  % 只显示前几个超出范围的例子
                        fprintf('  节点%d系数%d = %.10f 超出范围\n', i, j, transposed_sos(i,j));
                    end
                    out_of_range_count = out_of_range_count + 1;
                end
            end
        end
        if out_of_range_count > 3
            fprintf('  ... 以及其他 %d 个系数\n', out_of_range_count - 3);
        end
    else
        fprintf('所有系数在%s格式范围内\n', format_name);
    end
end

% 根据分析选择合适的定点格式
if max_coef <= 1.999
    fprintf('\n基于分析选择Q1.14格式 - 范围合适且提供高精度\n');
    word_length = 16;
    frac_length = 14;
elseif max_coef <= 3.999
    fprintf('\n基于分析选择Q2.13格式 - 提供足够的范围和精度\n');
    word_length = 16;
    frac_length = 13;
else
    fprintf('\n基于分析选择Q3.12格式 - 提供更大的范围\n');
    word_length = 16;
    frac_length = 12;
end

scale_factor = 2^frac_length;
int_bits = word_length - frac_length - 1;
min_val = -2^int_bits;
max_val = 2^int_bits - 2^(-frac_length);
fprintf('选定格式表示范围: [%.10f, %.10f]\n', min_val, max_val);

%% Step 8: 系数定点化
fprintf('\n===== 步骤8: 系数定点化 =====\n');

% 初始化存储定点化系数
fixed_coeffs = zeros(N_sections, 5);

for i = 1:N_sections
    for j = 1:5
        val = transposed_sos(i, j);
        
        % 检查范围
        if abs(val) > max_val
            fprintf('警告: 系数 [%d,%d] = %.6f 超出定点范围 [%.6f, %.6f]\n', ...
                   i, j, val, min_val, max_val);
            % 截断到有效范围
            val = max(min(val, max_val), min_val);
        end
        
        % 定点化 (四舍五入)
        fixed_val = round(val * scale_factor);
        
        % 保证不超出有符号整数范围
        fixed_val = max(min(fixed_val, 2^(word_length-1)-1), -2^(word_length-1));
        
        % 存储定点化的值
        fixed_coeffs(i, j) = fixed_val;
    end
end

% 打印定点化系数
fprintf('定点化系数 (Q%d.%d格式):\n', word_length-frac_length-1, frac_length);
fprintf('节点\tb0\t\tb1\t\tb2\t\ta1\t\ta2\n');
for i = 1:N_sections
    fprintf('%d\t%d\t%d\t%d\t%d\t%d\n', i, ...
        fixed_coeffs(i,1), fixed_coeffs(i,2), fixed_coeffs(i,3), ...
        fixed_coeffs(i,4), fixed_coeffs(i,5));
end

%% Step 9: 系数保存
fprintf('\n===== 步骤9: 保存结果 =====\n');

% 将定点化系数转为16进制
hex_coeffs = cell(N_sections, 5);
for i = 1:N_sections
    for j = 1:5
        val = fixed_coeffs(i, j);
        % 转为二进制补码表示的16进制
        if val < 0
            val = 2^word_length + val;
        end
        hex_coeffs{i, j} = sprintf('%04X', val);
    end
end

% 打印16进制系数
fprintf('16进制系数表示:\n');
fprintf('节点\tb0\t\tb1\t\tb2\t\ta1\t\ta2\n');
for i = 1:N_sections
    fprintf('%d\t%s\t%s\t%s\t%s\t%s\n', i, ...
        hex_coeffs{i,1}, hex_coeffs{i,2}, hex_coeffs{i,3}, ...
        hex_coeffs{i,4}, hex_coeffs{i,5});
end

% 保存SOS系数到文件
coeff_file = 'iir_coeffs.txt';
fid = fopen(coeff_file, 'w');
% 写入头部信息
fprintf(fid, '// IIR滤波器系数 - 格式Q%d.%d\n', word_length-frac_length-1, frac_length);
fprintf(fid, '// 节点数: %d\n', N_sections);
fprintf(fid, '// 格式: [b0, b1, b2, a1, a2] 每行一个节点\n');
% 写入系数 (按行，每行一个SOS节点的5个系数)
for i = 1:N_sections
    for j = 1:5
        fprintf(fid, '%s ', hex_coeffs{i,j});
    end
    fprintf(fid, '\n');
end
fclose(fid);

% 保存分析结果
save('filter_analysis.mat', 'sos', 'sorted_sos', 'transposed_sos', ...
     'fixed_coeffs', 'hex_coeffs', 'pole_mags', 'sort_idx', ...
     'overall_gain', 'root_gain', 'word_length', 'frac_length');

fprintf('系数已保存到 %s\n', coeff_file);
fprintf('分析结果已保存到 filter_analysis.mat\n');

%% Step 10: 频率和响应分析
fprintf('\n===== 步骤10: 频率和响应分析 =====\n');

% 创建基于定点化系数的滤波器模型
sos_fixed = zeros(N_sections, 6);
for i = 1:N_sections
    sos_fixed(i, 1:3) = fixed_coeffs(i, 1:3) / scale_factor;
    sos_fixed(i, 4) = 1;  % 重建SOS格式 [b0,b1,b2,1,a1,a2]
    sos_fixed(i, 5:6) = fixed_coeffs(i, 4:5) / scale_factor;
end

% 创建固定点滤波器对象
Hd_fixed = dfilt.df2tsos(sos_fixed, 1);  % 注意增益已经分配到各节点的系数中了

% 计算并绘制频率响应
figure('Name', '滤波器频率响应');
[h, w] = freqz(Hd);
[h_fixed, w_fixed] = freqz(Hd_fixed);

subplot(2,1,1);
plot(w/pi*Fs/2/1e6, 20*log10(abs(h)), 'b');
hold on;
plot(w_fixed/pi*Fs/2/1e6, 20*log10(abs(h_fixed)), 'r--');
title('幅频响应');
xlabel('频率 (MHz)');
ylabel('幅度 (dB)');
legend('浮点实现', '定点实现');
grid on;

subplot(2,1,2);
plot(w/pi*Fs/2/1e6, unwrap(angle(h))*180/pi, 'b');
hold on;
plot(w_fixed/pi*Fs/2/1e6, unwrap(angle(h_fixed))*180/pi, 'r--');
title('相频响应');
xlabel('频率 (MHz)');
ylabel('相位 (度)');
legend('浮点实现', '定点实现');
grid on;

% 计算并绘制群延迟
figure('Name', '群延迟');
[gd, w_gd] = grpdelay(Hd);
[gd_fixed, w_gd_fixed] = grpdelay(Hd_fixed);

plot(w_gd/pi*Fs/2/1e6, gd, 'b');
hold on;
plot(w_gd_fixed/pi*Fs/2/1e6, gd_fixed, 'r--');
title('群延迟');
xlabel('频率 (MHz)');
ylabel('群延迟 (样本)');
legend('浮点实现', '定点实现');
grid on;

% 计算群延迟指标
max_gd = max(gd);
avg_gd = mean(gd);
max_gd_fixed = max(gd_fixed);
avg_gd_fixed = mean(gd_fixed);

fprintf('群延迟分析:\n');
fprintf('  浮点实现 - 最大群延迟: %.2f 样本, 平均群延迟: %.2f 样本\n', max_gd, avg_gd);
fprintf('  定点实现 - 最大群延迟: %.2f 样本, 平均群延迟: %.2f 样本\n', max_gd_fixed, avg_gd_fixed);
fprintf('  建议稳定时间: %.0f 样本\n', 3*max(max_gd, max_gd_fixed));

% 生成并绘制脉冲响应
impulse_length = 2000;
x_impulse = zeros(impulse_length, 1);
x_impulse(1) = 1;  % 单位脉冲

y_impulse = filter(Hd, x_impulse);
y_impulse_fixed = filter(Hd_fixed, x_impulse);

figure('Name', '脉冲响应');
subplot(2,1,1);
stem(0:99, y_impulse(1:100), 'b');
hold on;
stem(0:99, y_impulse_fixed(1:100), 'r--');
title('脉冲响应 (前100个样本)');
xlabel('样本索引');
ylabel('幅度');
legend('浮点实现', '定点实现');
grid on;

% 找到脉冲响应衰减到峰值1%的时间
peak_val = max(abs(y_impulse));
decay_threshold = 0.01 * peak_val;
decay_samples = impulse_length;
for i = impulse_length:-1:1
    if abs(y_impulse(i)) > decay_threshold
        decay_samples = i;
        break;
    end
end

subplot(2,1,2);
plot(abs(y_impulse), 'b');
hold on;
plot(abs(y_impulse_fixed), 'r--');
yline(decay_threshold, 'k--', '1% 峰值');
xline(decay_samples, 'g--', '衰减点');
title('脉冲响应衰减');
xlabel('样本索引');
ylabel('幅度 (绝对值)');
legend('浮点实现', '定点实现', '1% 峰值', '衰减点');
grid on;
set(gca, 'YScale', 'log');

fprintf('脉冲响应分析:\n');
fprintf('  峰值: %.10f\n', peak_val);
fprintf('  衰减到峰值1%%所需样本数: %d\n', decay_samples);

% 保存重要参数到文件
fid = fopen('filter_parameters.txt', 'w');
fprintf(fid, '// IIR滤波器参数摘要\n');
fprintf(fid, 'Filter Type: %s\n', filter_type);
fprintf(fid, 'Order: %d\n', N);
fprintf(fid, 'SOS Sections: %d\n', N_sections);
fprintf(fid, 'Fixed-point Format: Q%d.%d\n', word_length-frac_length-1, frac_length);
fprintf(fid, 'Max Pole Magnitude: %.10f\n', max(sorted_mags));
fprintf(fid, 'Max Group Delay: %.2f samples\n', max(max_gd, max_gd_fixed));
fprintf(fid, 'Settling Time: %d samples\n', decay_samples);
fclose(fid);

fprintf('滤波器分析完成，参数已保存到 filter_parameters.txt\n');