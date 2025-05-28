% 读取csv/波形数据
filename = 'your_signals.csv';
T = readtable(filename);

% 用门限自动判定有效点（可换成valid信号判定）
sig_names = {'data_in', 'mul_b0_x_p', 'mul_b1_x_p', 'mul_b2_x_p', ...
             'mul_a1_y_a', 'mul_a2_y_a', ...
             'mul_a1_y_p', 'mul_a2_y_p', ...
             'acc_sum', 'data_out', 'y1_pipe', 'y2_pipe'};
threshold = 1e-6; % 非零判据，可调整
Nsig = numel(sig_names);

first_valid = zeros(Nsig, 1);

for k = 1:Nsig
    sig = T.(sig_names{k});
    idx = find(abs(sig) > threshold, 1, 'first');
    if isempty(idx)
        first_valid(k) = NaN;
    else
        first_valid(k) = idx;
    end
end

% 打印全部信号的首有效点
fprintf('信号\t\t首有效点索引\n');
for k = 1:Nsig
    fprintf('%-12s\t%d\n', sig_names{k}, first_valid(k));
end

% 统计关键延迟
fprintf('\n主要路径延迟统计：\n');
% 举例统计几个关键链路
fprintf('data_in -> mul_b0_x_p : %d\n', first_valid(2) - first_valid(1));
fprintf('data_in -> acc_sum    : %d\n', first_valid(9) - first_valid(1));
fprintf('data_in -> data_out   : %d\n', first_valid(10) - first_valid(1));
fprintf('data_out -> y1_pipe   : %d\n', first_valid(11) - first_valid(10));
fprintf('y1_pipe  -> y2_pipe   : %d\n', first_valid(12) - first_valid(11));
fprintf('y1_pipe  -> mul_a1_y_a: %d\n', first_valid(5) - first_valid(11));
fprintf('mul_a1_y_a -> mul_a1_y_p: %d\n', first_valid(7) - first_valid(5));
% 可按需扩展更多路径