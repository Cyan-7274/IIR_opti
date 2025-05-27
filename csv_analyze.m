clear; close all; clc
% 文件绝对路径
file_path = 'D:\A_Hesper\IIRfilter\qts\tb\rtl_trace.txt';

% 读取表格，自动处理变量名合法性（点变下划线）
T = readtable(file_path, 'Delimiter', ' ', 'ReadVariableNames', true);

% 你保存的信号（用原始表头名字，Matlab会自动变成下划线风格）
signals = { ...
    'cycle', 'data_in', 'data_in_valid', 'data_out', 'data_out_valid', ...
    'mul_b0_x_a', 'mul_b0_x_b', 'mul_b0_x_p', ...
    'mul_b1_x_a', 'mul_b1_x_b', 'mul_b1_x_p', ...
    'mul_b2_x_a', 'mul_b2_x_b', 'mul_b2_x_p', ...
    'mul_a1_y_a', 'mul_a1_y_b', 'mul_a1_y_p', ...
    'mul_a2_y_a', 'mul_a2_y_b', 'mul_a2_y_p', ...
    'x_pipe0', 'x_pipe6', 'x_pipe12', ...
    'y1_pipe0', 'y1_pipe6', 'y1_pipe12', ...
    'y2_pipe0', 'y2_pipe6', 'y2_pipe12', ...
    'valid_pipe0', 'valid_pipe6', 'valid_pipe12' ...
    };

% 如果需要，检查哪些信号未被正确读取
var_names = T.Properties.VariableNames;
not_found = setdiff(signals, var_names);
if ~isempty(not_found)
    warning('下列信号在表中未找到: %s', strjoin(not_found, ', '));
end

% 选择基准信号（如data_in），用于计算延迟
base_signal = 'data_in';
base_idx = find(abs(T.(base_signal)) > 0, 1, 'first');

% 统计每个信号首次非零的cycle
delay_table = cell(length(signals), 3);
delay_table(:,1) = signals';

for i = 1:length(signals)
    sig = signals{i};
    if ismember(sig, var_names)
        idx = find(abs(double(T.(sig))) > 0, 1, 'first');
        if isempty(idx)
            delay_table{i,2} = NaN;
        else
            delay_table{i,2} = T.cycle(idx);
        end
        delay_table{i,3} = delay_table{i,2} - T.cycle(base_idx); % 相对delay
    else
        delay_table{i,2} = NaN;
        delay_table{i,3} = NaN;
    end
end

% 输出延迟表
delay_tbl = cell2table(delay_table, 'VariableNames', {'Signal','FirstNonZeroCycle','Delay_vs_base'});
disp(delay_tbl)

% 你也可以直接绘图，例如
figure;
plot(T.cycle, T.data_in, 'b', T.cycle, T.data_out, 'r');
legend('data\_in','data\_out');
xlabel('cycle');
ylabel('signal value');
title('输入输出信号对比');