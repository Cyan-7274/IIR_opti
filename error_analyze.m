clear; close all; clc;

Q = 2^22;
rtl_file = 'D:/A_Hesper/IIRfilter/qts/tb/rtl_trace.txt';
ref_file = 'reference_data.csv';
mat_file = 'reference_data.mat';

% 读取RTL输出
T_rtl = readtable(rtl_file, 'Delimiter', ' ', 'MultipleDelimsAsOne', true);

% 读取matlab理论输出
T_ref = readtable(ref_file);
load(mat_file, 'group_delay');
group_delay = group_delay;

cycle = T_rtl.cycle;
data_out = double(T_rtl.data_out) / Q;
data_out_valid = logical(T_rtl.data_out_valid);

y_q22 = double(T_ref.y_q22) / Q;

N = min(length(data_out), length(y_q22));
cycle = cycle(1:N);
data_out = data_out(1:N);
data_out_valid = data_out_valid(1:N);
y_q22 = y_q22(1:N);

% === group delay对齐（忽略前group_delay个点） ===
aligned_y = nan(N,1);
for i = group_delay+1:N
    aligned_y(i) = y_q22(i - group_delay);
end

% 只分析对齐后100个点（且必须有效）
first_valid = find(data_out_valid, 1, 'first');
start_idx = max(group_delay+1, first_valid);
window_len = 500;
idx_range = start_idx : min(start_idx + window_len - 1, N);

window_cycle = cycle(idx_range);
window_data_out = data_out(idx_range);
window_aligned_y = aligned_y(idx_range);
window_valid = data_out_valid(idx_range) & ~isnan(window_aligned_y);

window_error = window_data_out - window_aligned_y;
window_error_valid = window_error(window_valid);

% 标注点
[~, max_err_idx_rel] = max(abs(window_error_valid));
valid_indices = find(window_valid);
if ~isempty(valid_indices)
    max_err_idx = idx_range(valid_indices(max_err_idx_rel));
else
    max_err_idx = NaN;
end

figure('Name','RTL输出 vs Matlab理论输出（群延迟对齐）');
subplot(2,1,1);
plot(window_cycle, window_data_out, 'r', 'LineWidth', 1.2); hold on;
plot(window_cycle, window_aligned_y, 'k--', 'LineWidth', 1.2);

plot(cycle(first_valid), data_out(first_valid), 'go', 'MarkerFaceColor','g', 'DisplayName','first valid');
text(cycle(first_valid), data_out(first_valid), '  first valid', 'Color','g', 'FontSize',9, 'VerticalAlignment','bottom');
plot(cycle(start_idx), data_out(start_idx), 'mo', 'MarkerFaceColor','m', 'DisplayName','group delay');
text(cycle(start_idx), data_out(start_idx), '  group delay', 'Color','m', 'FontSize',9, 'VerticalAlignment','top');
if ~isnan(max_err_idx)
    plot(cycle(max_err_idx), data_out(max_err_idx), 'bs', 'MarkerFaceColor','b', 'DisplayName','max error');
    text(cycle(max_err_idx), data_out(max_err_idx), '  max error', 'Color','b', 'FontSize',9, 'VerticalAlignment','bottom');
end

legend('RTL data\_out','Matlab y\_q22','Location','best');
xlabel('Cycle'); ylabel('Q2.22 Value');
title(sprintf('RTL vs Matlab, 群延迟对齐(%d点, 窗口%d点)', group_delay, window_len));
grid on;

subplot(2,1,2);
plot(window_cycle(window_valid), window_error_valid, 'b', 'LineWidth', 1.0); hold on;
if ~isnan(max_err_idx)
    plot(cycle(max_err_idx), window_error(cycle(max_err_idx)==window_cycle), 'rs', 'MarkerFaceColor','r');
    text(cycle(max_err_idx), window_error(cycle(max_err_idx)==window_cycle), '  max error', 'Color','r', 'FontSize',9, 'VerticalAlignment','bottom');
end
title('输出误差（RTL - Matlab, 群延迟对齐, 有效区）');
xlabel('Cycle');
ylabel('误差');
grid on;

% 输出统计量
fprintf('群延迟对齐 = %d点\n', group_delay);
fprintf('窗口范围: Cycle %d 到 %d\n', window_cycle(1), window_cycle(end));
fprintf('窗口内: 最大绝对误差: %.3g\n', max(abs(window_error_valid)));
fprintf('窗口内: 均方误差: %.3g\n', mean(window_error_valid.^2));
fprintf('窗口内: 平均误差: %.3g\n', mean(window_error_valid));
if ~isnan(max_err_idx)
    fprintf('最大误差点: Cycle=%d, RTL=%.4f, Matlab=%.4f, 误差=%.4f\n', ...
        cycle(max_err_idx), data_out(max_err_idx), aligned_y(max_err_idx), window_error(cycle(max_err_idx)==window_cycle));
end