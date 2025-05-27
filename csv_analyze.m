clear; close all; clc;

filename = 'D:/A_Hesper/IIRfilter/qts/sim/all_sos_full_pipeline.csv';
range = 1:800; % 对比区间
Q = 2^22;

T = readtable(filename, 'VariableNamingRule', 'preserve');
a1_p = T.sos0_a1_p / Q;
a2_p = T.sos0_a2_p / Q;
a1_p_vld = logical(T.sos0_a1_valid_out);
a2_p_vld = logical(T.sos0_a2_valid_out);

load('reference_data.mat');
% ==== 前馈部分（已注释） ====
% b0_p_theory_q22 = ...;
% b1_p_theory_q22 = ...;
% b2_p_theory_q22 = ...;

% ==== 反馈部分 ====
a1_p_theory_q22 = a1_p_theory_q22(:);
a2_p_theory_q22 = a2_p_theory_q22(:);

function [aligned_theory, delay, rtl_peak_idx, theory_peak_idx] = align_first_positive_peak(rtl_sig, rtl_valid, theory_sig)
    N = min(length(rtl_sig), length(theory_sig));
    rtl_sig = rtl_sig(1:N); theory_sig = theory_sig(1:N); rtl_valid = rtl_valid(1:N);
    search_start = find(rtl_valid, 1, 'first');
    [~, rtl_peak_idx] = max(rtl_sig(search_start:end)); rtl_peak_idx = rtl_peak_idx + search_start - 1;
    [~, theory_peak_idx] = max(theory_sig(search_start:end)); theory_peak_idx = theory_peak_idx + search_start - 1;
    delay = rtl_peak_idx - theory_peak_idx;
    aligned_theory = nan(size(rtl_sig));
    for i = rtl_peak_idx:N
        t_idx = i - delay;
        if t_idx >= 1 && t_idx <= N
            aligned_theory(i) = theory_sig(t_idx);
        end
    end
end

[a1_p_theory_aligned, a1_delay, a1_peak_rtl, a1_peak_theory] = align_first_positive_peak(a1_p, a1_p_vld, a1_p_theory_q22);
[a2_p_theory_aligned, a2_delay, a2_peak_rtl, a2_peak_theory] = align_first_positive_peak(a2_p, a2_p_vld, a2_p_theory_q22);

fprintf('a1峰值延迟 = %d, a2峰值延迟 = %d\n', a1_delay, a2_delay);

% ==== 前馈部分对比（已注释） ====
% figure(...)

% ==== 反馈a1对比 ====
figure('Name','a1 p信号 RTL与理论峰值对齐对比');
subplot(2,1,1);
plot(range, a1_p(range), 'r', 'LineWidth', 1.0); hold on;
plot(range, a1_p_theory_aligned(range), 'k--', 'LineWidth', 1.0);
idx = range(a1_p_vld(range));
stem(idx, a1_p(idx), 'g.', 'LineWidth',1.5);
scatter(a1_peak_rtl, a1_p(a1_peak_rtl), 80, 'ro', 'filled');
scatter(a1_peak_rtl, a1_p_theory_aligned(a1_peak_rtl), 80, 'ko', 'filled');
title(sprintf('a1 乘法器p输出 RTL vs 理论（峰值对齐%d拍，前%d点）', a1_delay, range(end)));
xlabel('采样点'); ylabel('Q2.22数值');
legend('RTL a1\_p','理论 a1\_p（峰值对齐）', 'RTL有效点','RTL首峰','理论峰');
grid on;
subplot(2,1,2);
plot(range, a1_p(range) - a1_p_theory_aligned(range), 'b');
title('a1\_p误差（RTL - 理论, 峰值对齐）');
xlabel('采样点'); ylabel('误差');
grid on;

% ==== 反馈a2对比 ====
figure('Name','a2 p信号 RTL与理论峰值对齐对比');
subplot(2,1,1);
plot(range, a2_p(range), 'b', 'LineWidth', 1.0); hold on;
plot(range, a2_p_theory_aligned(range), 'k--', 'LineWidth', 1.0);
idx = range(a2_p_vld(range));
stem(idx, a2_p(idx), 'm.', 'LineWidth',1.5);
scatter(a2_peak_rtl, a2_p(a2_peak_rtl), 80, 'bo', 'filled');
scatter(a2_peak_rtl, a2_p_theory_aligned(a2_peak_rtl), 80, 'ko', 'filled');
title(sprintf('a2 乘法器p输出 RTL vs 理论（峰值对齐%d拍，前%d点）', a2_delay, range(end)));
xlabel('采样点'); ylabel('Q2.22数值');
legend('RTL a2\_p','理论 a2\_p（峰值对齐）', 'RTL有效点','RTL首峰','理论峰');
grid on;
subplot(2,1,2);
plot(range, a2_p(range) - a2_p_theory_aligned(range), 'b');
title('a2\_p误差（RTL - 理论, 峰值对齐）');
xlabel('采样点'); ylabel('误差');
grid on;

% ==== 合并对比 ====
figure('Name','a1/a2 p信号 RTL与理论峰值对齐对比');
hold on;
plot(range, a1_p(range), 'r', 'LineWidth', 1.2);
plot(range, a2_p(range), 'b', 'LineWidth', 1.2);
plot(range, a1_p_theory_aligned(range), 'r--', 'LineWidth', 1.2);
plot(range, a2_p_theory_aligned(range), 'b--', 'LineWidth', 1.2);
scatter(a1_peak_rtl, a1_p(a1_peak_rtl), 80, 'ro', 'filled');
scatter(a2_peak_rtl, a2_p(a2_peak_rtl), 80, 'bo', 'filled');
title(sprintf('a1/a2 p信号 RTL与理论峰值对齐（a1:%d, a2:%d，前%d点）', a1_delay, a2_delay, range(end)));
xlabel('采样点'); ylabel('Q2.22数值');
legend('a1 RTL','a2 RTL','a1理论','a2理论','a1峰','a2峰');
grid on;
hold off;