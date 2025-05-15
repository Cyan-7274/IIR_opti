%% verify_opti.m - IIR滤波器仿真结果可视化与比较 (优化版)
clear
close all
clc
%% 参数设置
Fs = 122.88e6;     % 采样频率
Fc = 30.72e6;      % 中心频率
frac_length = 13;  % Q1.2.13格式的小数部分长度

%% 检查文件是否存在
if ~exist('D:/A_Hesper/IIRfilter/qts/sim/filter_design.mat', 'file')
    error('设计参数文件 filter_design.mat 不存在，请先运行 opti_design.m');
end

if ~exist('D:/A_Hesper/IIRfilter/qts/sim/ref_output.mat', 'file')
    warning('参考输出文件 ref_output.mat 不存在，请先运行 opti_design.m');
end

if ~exist('D:/A_Hesper/IIRfilter/qts/sim/output_results.hex', 'file')
    error('RTL仿真输出文件 output_results.hex 不存在，请先运行RTL仿真');
end

%% 加载设计参数和参考输出
fprintf('加载设计参数和参考输出...\n');
load('D:/A_Hesper/IIRfilter/qts/sim/filter_design.mat');  % 加载滤波器设计参数

if exist('D:/A_Hesper/IIRfilter/qts/sim/ref_output.mat', 'file')
    load('D:/A_Hesper/IIRfilter/qts/sim/ref_output.mat');     % 加载MATLAB参考输出
    has_ref = true;
    fprintf('已加载参考输出\n');
else
    has_ref = false;
    fprintf('未找到参考输出文件，将只分析RTL输出\n');
end

%% 加载RTL仿真输出
fprintf('加载RTL仿真输出...\n');
rtl_output_file = 'D:/A_Hesper/IIRfilter/qts/sim/output_results.hex';
rtl_hex_data = fileread(rtl_output_file);
rtl_lines = strsplit(rtl_hex_data, '\n');

% 转换hex为十进制
rtl_fixed = zeros(length(rtl_lines), 1);
rtl_output = zeros(length(rtl_lines), 1);
valid_count = 0;

for i = 1:length(rtl_lines)
    line = strtrim(rtl_lines{i});
    if ~isempty(line)
        % 将hex字符串转换为有符号整数
        val = hex2dec(line);
        if val >= 2^15  % 负数(最高位为1)
            val = val - 2^16;
        end
        
        valid_count = valid_count + 1;
        rtl_fixed(valid_count) = val;
        rtl_output(valid_count) = val / 2^frac_length;  % 转换回浮点数
    end
end

% 剪裁数组到有效大小
rtl_fixed = rtl_fixed(1:valid_count);
rtl_output = rtl_output(1:valid_count);

fprintf('RTL输出加载完成，共 %d 个有效样本\n', valid_count);
fprintf('RTL输出整数值范围: [%d, %d]\n', min(rtl_fixed), max(rtl_fixed));
fprintf('RTL输出浮点值范围: [%.6f, %.6f]\n', min(rtl_output), max(rtl_output));

% 统计RTL输出的唯一值数量
unique_rtl = unique(rtl_fixed);
fprintf('RTL输出中的唯一值数量: %d\n', length(unique_rtl));

%% 检查输入信号
if ~exist('test_input', 'var')
    fprintf('未从ref_output.mat找到测试输入，尝试从test_signal.hex加载...\n');
    
    if exist('D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex', 'file')
        test_hex_data = fileread('D:/A_Hesper/IIRfilter/qts/sim/test_signal.hex');
        test_lines = strsplit(test_hex_data, '\n');
        test_fixed = zeros(length(test_lines), 1);
        test_input = zeros(length(test_lines), 1);
        test_count = 0;
        
        for i = 1:length(test_lines)
            line = strtrim(test_lines{i});
            if ~isempty(line)
                val = hex2dec(line);
                if val >= 2^15
                    val = val - 2^16;
                end
                
                test_count = test_count + 1;
                test_fixed(test_count) = val;
                test_input(test_count) = val / 2^frac_length;
            end
        end
        
        test_fixed = test_fixed(1:test_count);
        test_input = test_input(1:test_count);
        fprintf('已从test_signal.hex加载测试输入，共 %d 个样本\n', test_count);
    else
        fprintf('未找到test_signal.hex，将生成合成的测试信号...\n');
        % 创建合成的测试信号
        t = (0:valid_count-1) / Fs;
        test_input = 0.5 * sin(2*pi*Fc*t);
        test_fixed = floor(test_input * 2^frac_length);
    end
end

%% 调整数组大小，确保比较的样本数一致
% 修正: 考虑RTL输出延迟
delay_compensation = 6; % 根据第二阶段设计的延迟调整

if has_ref
    min_length = min([length(rtl_output), length(ref_output), length(test_input)]);
    rtl_output = rtl_output(1:min_length);
    rtl_fixed = rtl_fixed(1:min_length);
    
    % 调整参考输出以补偿延迟
    if delay_compensation > 0 && length(ref_output) > delay_compensation
        ref_output_adj = [zeros(delay_compensation, 1); ref_output(1:end-delay_compensation)];
        ref_output = ref_output_adj(1:min_length);
    else
        ref_output = ref_output(1:min_length);
    end
    
    if exist('ref_fixed', 'var')
        ref_fixed = ref_fixed(1:min_length);
    end
    test_input = test_input(1:min_length);
    
    fprintf('调整数组大小完成，将分析 %d 个样本\n', min_length);
else
    min_length = min(length(rtl_output), length(test_input));
    rtl_output = rtl_output(1:min_length);
    rtl_fixed = rtl_fixed(1:min_length);
    test_input = test_input(1:min_length);
    
    fprintf('调整数组大小完成，将分析 %d 个样本\n', min_length);
end

%% 可视化结果
fprintf('正在生成可视化结果...\n');
t = (0:min_length-1)/Fs;  % 时间轴

% 创建图形1：时域波形
figure('Name', 'IIR滤波器仿真结果', 'Position', [100, 100, 1000, 800]);

% 绘制时域比较 - 全部数据
subplot(2,1,1);
plot(t, test_input, 'b-', 'LineWidth', 1.5);
hold on;
if has_ref
    plot(t, ref_output, 'r-', 'LineWidth', 1);
end
plot(t, rtl_output, 'g--', 'LineWidth', 1);
title('滤波器输入与输出对比 (全部数据)');
xlabel('时间 (秒)');
ylabel('幅度');
if has_ref
    legend('输入信号', 'MATLAB参考输出', 'RTL输出');
else
    legend('输入信号', 'RTL输出');
end
grid on;

% 绘制时域比较 - 前200个样本(跳过初始暂态)
subplot(2,1,2);
start_sample = 20; % 跳过前20个样本(暂态)
samples_to_show = min(200, min_length-start_sample);
plot(t(start_sample:start_sample+samples_to_show-1), test_input(start_sample:start_sample+samples_to_show-1), 'b-', 'LineWidth', 1.5);
hold on;
if has_ref
    plot(t(start_sample:start_sample+samples_to_show-1), ref_output(start_sample:start_sample+samples_to_show-1), 'r-', 'LineWidth', 1);
end
plot(t(start_sample:start_sample+samples_to_show-1), rtl_output(start_sample:start_sample+samples_to_show-1), 'g--', 'LineWidth', 1);
title(sprintf('滤波器输入与输出对比 (样本 %d-%d)', start_sample, start_sample+samples_to_show-1));
xlabel('时间 (秒)');
ylabel('幅度');
if has_ref
    legend('输入信号', 'MATLAB参考输出', 'RTL输出');
else
    legend('输入信号', 'RTL输出');
end
grid on;

% 创建图形2：频率响应
figure('Name', '频率响应比较', 'Position', [200, 100, 1000, 800]);

% 计算频谱 - 移除直流分量和应用窗口函数以减少泄漏
window = hann(min_length);
N = min_length;
f = (0:N/2-1)*Fs/N;  % 频率轴

% 输入信号频谱
Y_in = fft(detrend(test_input) .* window);
P_in = abs(Y_in/N);
P_in = P_in(1:N/2);
P_in(2:end) = 2*P_in(2:end);

% 参考输出频谱 (如果有)
if has_ref
    Y_ref = fft(detrend(ref_output) .* window);
    P_ref = abs(Y_ref/N);
    P_ref = P_ref(1:N/2);
    P_ref(2:end) = 2*P_ref(2:end);
end

% RTL输出频谱
Y_rtl = fft(detrend(rtl_output) .* window);
P_rtl = abs(Y_rtl/N);
P_rtl = P_rtl(1:N/2);
P_rtl(2:end) = 2*P_rtl(2:end);

% 绘制频谱
subplot(3,1,1);
plot(f/1e6, 20*log10(P_in+eps), 'b-', 'LineWidth', 1.5);
title('输入信号频谱');
xlabel('频率 (MHz)');
ylabel('幅度 (dB)');
grid on;
xlim([0, Fs/2/1e6]);
ylim([-100, 20]);
hold on;
line([Fc/1e6 Fc/1e6], get(gca, 'YLim'), 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
text(Fc/1e6 + 2, 0, sprintf('中心频率 %.2f MHz', Fc/1e6), 'Color', 'r');

% 参考输出频谱 (如果有)
if has_ref
    subplot(3,1,2);
    plot(f/1e6, 20*log10(P_ref+eps), 'r-', 'LineWidth', 1.5);
    title('MATLAB参考输出频谱');
    xlabel('频率 (MHz)');
    ylabel('幅度 (dB)');
    grid on;
    xlim([0, Fs/2/1e6]);
    ylim([-100, 20]);
    hold on;
    line([Fc/1e6 Fc/1e6], get(gca, 'YLim'), 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
    text(Fc/1e6 + 2, 0, sprintf('中心频率 %.2f MHz', Fc/1e6), 'Color', 'r');
end

% RTL输出频谱
subplot(3,1,3);
plot(f/1e6, 20*log10(P_rtl+eps), 'g-', 'LineWidth', 1.5);
title('RTL仿真输出频谱');
xlabel('频率 (MHz)');
ylabel('幅度 (dB)');
grid on;
xlim([0, Fs/2/1e6]);
ylim([-100, 20]);
hold on;
line([Fc/1e6 Fc/1e6], get(gca, 'YLim'), 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
text(Fc/1e6 + 2, 0, sprintf('中心频率 %.2f MHz', Fc/1e6), 'Color', 'r');

% 如果有参考输出，创建比较图
if has_ref
    % 创建图形3：RTL与参考输出对比
    figure('Name', 'RTL与参考输出对比', 'Position', [300, 100, 1000, 800]);
    
    % 时域对比 - 跳过初始暂态
    subplot(2,1,1);
    start_sample = 20; % 跳过前20个样本(暂态)
    samples_to_show = min(200, min_length-start_sample);
    plot(t(start_sample:start_sample+samples_to_show-1), ref_output(start_sample:start_sample+samples_to_show-1), 'r-', 'LineWidth', 1.5);
    hold on;
    plot(t(start_sample:start_sample+samples_to_show-1), rtl_output(start_sample:start_sample+samples_to_show-1), 'g--', 'LineWidth', 1);
    title('时域响应对比: MATLAB参考 vs RTL仿真');
    xlabel('时间 (秒)');
    ylabel('幅度');
    legend('MATLAB参考', 'RTL仿真');
    grid on;
    
    % 计算差异 - 忽略初始暂态
    diff = rtl_output - ref_output;
    valid_range = start_sample:min_length;
    abs_diff = abs(diff(valid_range));
    max_diff = max(abs_diff);
    mean_diff = mean(abs_diff);
    rms_diff = sqrt(mean(diff(valid_range).^2));
    
    % 计算差异
    subplot(2,1,2);
    plot(t(start_sample:start_sample+samples_to_show-1), diff(start_sample:start_sample+samples_to_show-1), 'b-', 'LineWidth', 1.5);
    title(sprintf('差异 (RTL - MATLAB): 最大差异=%.6f, 均方根=%.6f', max_diff, rms_diff));
    xlabel('时间 (秒)');
    ylabel('差异');
    grid on;
    
    % 打印差异统计
    fprintf('\n========== 输出比较结果 ==========\n');
    fprintf('最大绝对差异: %.6f\n', max_diff);
    fprintf('平均绝对差异: %.6f\n', mean_diff);
    fprintf('均方根差异: %.6f\n', rms_diff);
    fprintf('相对差异 (均方根/输出均方根): %.2f%%\n', 100*rms_diff/sqrt(mean(ref_output(valid_range).^2)));
    
    % 创建频率响应比较图
    figure('Name', '频率响应比较', 'Position', [400, 100, 1000, 400]);
    plot(f/1e6, 20*log10(P_ref+eps), 'r-', 'LineWidth', 1.5);
    hold on;
    plot(f/1e6, 20*log10(P_rtl+eps), 'g--', 'LineWidth', 1);
    title('频率响应比较: MATLAB参考 vs RTL仿真');
    xlabel('频率 (MHz)');
    ylabel('幅度 (dB)');
    legend('MATLAB参考', 'RTL仿真');
    grid on;
    xlim([0, Fs/2/1e6]);
    ylim([-100, 20]);
    line([Fc/1e6 Fc/1e6], get(gca, 'YLim'), 'Color', 'b', 'LineStyle', '--', 'LineWidth', 1);
    text(Fc/1e6 + 2, 0, sprintf('中心频率 %.2f MHz', Fc/1e6), 'Color', 'b');
end

%% 保存图片
fprintf('正在保存图片...\n');
saveas(1, 'D:/A_Hesper/IIRfilter/qts/sim/time_domain_comparison.png');
saveas(2, 'D:/A_Hesper/IIRfilter/qts/sim/frequency_response.png');
if has_ref
    saveas(3, 'D:/A_Hesper/IIRfilter/qts/sim/rtl_vs_matlab.png');
    saveas(4, 'D:/A_Hesper/IIRfilter/qts/sim/frequency_comparison.png');
end

fprintf('\n分析完成，已保存可视化结果。\n');