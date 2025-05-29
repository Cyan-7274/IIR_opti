clear; close all; clc;

filename = 'D:/A_Hesper/IIRfilter/qts/sim/all_sos_full_pipeline.csv';
range = 1:100; % 可根据需求调整
Q = 2^22;

% 读取RTL输出
T = readtable(filename, 'VariableNamingRule', 'preserve');
b0_p = T.sos0_b0_p / Q;
b1_p = T.sos0_b1_p / Q;
b2_p = T.sos0_b2_p / Q;
b0_p_vld = logical(T.sos0_b0_valid_out);
b1_p_vld = logical(T.sos0_b1_valid_out);
b2_p_vld = logical(T.sos0_b2_valid_out);

% 读取matlab理论参考信号
load('reference_data.mat');
b0_p_theory = b0_p_theory_q22(:);
b1_p_theory = b1_p_theory_q22(:);
b2_p_theory = b2_p_theory_q22(:);

% 峰值对齐函数
function [aligned_theory, delay, rtl_peak_idx, theory_peak_idx] = align_first_positive_peak(rtl_sig, rtl_valid, theory_sig)
    % 只考虑RTL有效区间
    N = min(length(rtl_sig), length(theory_sig));
    rtl_sig = rtl_sig(1:N); theory_sig = theory_sig(1:N); rtl_valid = rtl_valid(1:N);

    % 找到有效区间的第一个正半波峰（前面可能全是0，要避开初始零头）
    search_start = find(rtl_valid, 1, 'first');
    % 只在有效区间找
    [~, rtl_peak_idx] = max(rtl_sig(search_start:end));
    rtl_peak_idx = rtl_peak_idx + search_start - 1;
    % 只找正半波最大值
    [~, theory_peak_idx] = max(theory_sig(search_start:end));
    theory_peak_idx = theory_peak_idx + search_start - 1;

    delay = rtl_peak_idx - theory_peak_idx;
    aligned_theory = nan(size(rtl_sig));
    for i = rtl_peak_idx:N
        t_idx = i - delay;
        if t_idx >= 1 && t_idx <= N
            aligned_theory(i) = theory_sig(t_idx);
        end
    end
end

% 对齐b0
[b0_p_theory_aligned, b0_delay, b0_peak_rtl, b0_peak_theory] = align_first_positive_peak(b0_p, b0_p_vld, b0_p_theory);
% 对齐b1
[b1_p_theory_aligned, b1_delay, b1_peak_rtl, b1_peak_theory] = align_first_positive_peak(b1_p, b1_p_vld, b1_p_theory);
% 对齐b2
[b2_p_theory_aligned, b2_delay, b2_peak_rtl, b2_peak_theory] = align_first_positive_peak(b2_p, b2_p_vld, b2_p_theory);

fprintf('b0峰值延迟 = %d, b1峰值延迟 = %d, b2峰值延迟 = %d\n', b0_delay, b1_delay, b2_delay);

%% b0对比图
figure('Name','b0 p信号 RTL与理论峰值对齐对比');
subplot(2,1,1);
plot(range, b0_p(range), 'r', 'LineWidth', 1.0); hold on;
plot(range, b0_p_theory_aligned(range), 'k--', 'LineWidth', 1.0);
idx = range(b0_p_vld(range));
stem(idx, b0_p(idx), 'g.', 'LineWidth',1.5);
scatter(b0_peak_rtl, b0_p(b0_peak_rtl), 80, 'ro', 'filled');
scatter(b0_peak_rtl, b0_p_theory_aligned(b0_peak_rtl), 80, 'ko', 'filled');
title(sprintf('b0 乘法器p输出 RTL vs 理论（峰值对齐%d拍，前%d点）', b0_delay, range(end)));
xlabel('采样点');
ylabel('Q2.22数值');
legend('RTL b0\_p','理论 b0\_p（峰值对齐）', 'RTL有效点','RTL首峰','理论峰');
grid on;
subplot(2,1,2);
plot(range, b0_p(range) - b0_p_theory_aligned(range), 'b');
title('b0\_p误差（RTL - 理论, 峰值对齐）');
xlabel('采样点');
ylabel('误差');
grid on;

%% b1对比图
figure('Name','b1 p信号 RTL与理论峰值对齐对比');
subplot(2,1,1);
plot(range, b1_p(range), 'g', 'LineWidth', 1.0); hold on;
plot(range, b1_p_theory_aligned(range), 'k--', 'LineWidth', 1.0);
idx = range(b1_p_vld(range));
stem(idx, b1_p(idx), 'b.', 'LineWidth',1.5);
scatter(b1_peak_rtl, b1_p(b1_peak_rtl), 80, 'go', 'filled');
scatter(b1_peak_rtl, b1_p_theory_aligned(b1_peak_rtl), 80, 'ko', 'filled');
title(sprintf('b1 乘法器p输出 RTL vs 理论（峰值对齐%d拍，前%d点）', b1_delay, range(end)));
xlabel('采样点');
ylabel('Q2.22数值');
legend('RTL b1\_p','理论 b1\_p（峰值对齐）', 'RTL有效点','RTL首峰','理论峰');
grid on;
subplot(2,1,2);
plot(range, b1_p(range) - b1_p_theory_aligned(range), 'b');
title('b1\_p误差（RTL - 理论, 峰值对齐）');
xlabel('采样点');
ylabel('误差');
grid on;

%% b2对比图
figure('Name','b2 p信号 RTL与理论峰值对齐对比');
subplot(2,1,1);
plot(range, b2_p(range), 'b', 'LineWidth', 1.0); hold on;
plot(range, b2_p_theory_aligned(range), 'k--', 'LineWidth', 1.0);
idx = range(b2_p_vld(range));
stem(idx, b2_p(idx), 'm.', 'LineWidth',1.5);
scatter(b2_peak_rtl, b2_p(b2_peak_rtl), 80, 'bo', 'filled');
scatter(b2_peak_rtl, b2_p_theory_aligned(b2_peak_rtl), 80, 'ko', 'filled');
title(sprintf('b2 乘法器p输出 RTL vs 理论（峰值对齐%d拍，前%d点）', b2_delay, range(end)));
xlabel('采样点');
ylabel('Q2.22数值');
legend('RTL b2\_p','理论 b2\_p（峰值对齐）', 'RTL有效点','RTL首峰','理论峰');
grid on;
subplot(2,1,2);
plot(range, b2_p(range) - b2_p_theory_aligned(range), 'b');
title('b2\_p误差（RTL - 理论, 峰值对齐）');
xlabel('采样点');
ylabel('误差');
grid on;

%% 三路合并对比
figure('Name','b0/b1/b2 p信号 RTL与理论延迟峰值对齐对比');
hold on;
plot(range, b0_p(range), 'r', 'LineWidth', 1.2);
plot(range, b1_p(range), 'g', 'LineWidth', 1.2);
plot(range, b2_p(range), 'b', 'LineWidth', 1.2);
plot(range, b0_p_theory_aligned(range), 'r--', 'LineWidth', 1.2);
plot(range, b1_p_theory_aligned(range), 'g--', 'LineWidth', 1.2);
plot(range, b2_p_theory_aligned(range), 'b--', 'LineWidth', 1.2);
scatter(b0_peak_rtl, b0_p(b0_peak_rtl), 80, 'ro', 'filled');
scatter(b1_peak_rtl, b1_p(b1_peak_rtl), 80, 'go', 'filled');
scatter(b2_peak_rtl, b2_p(b2_peak_rtl), 80, 'bo', 'filled');
title(sprintf('b0/b1/b2 p信号 RTL与理论延迟峰值对齐（b0:%d, b1:%d, b2:%d，前%d点）', ...
    b0_delay, b1_delay, b2_delay, range(end)));
xlabel('采样点');
ylabel('Q2.22数值');
legend('b0 RTL','b1 RTL','b2 RTL','b0理论','b1理论','b2理论','b0峰','b1峰','b2峰');
grid on;
hold off;