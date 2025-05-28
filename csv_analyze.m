clear; close all; clc

% 1. 读取文件，使用绝对路径
T = readtable('D:\A_Hesper\IIRfilter\qts\tb\rtl_trace.txt', 'Delimiter', ' ', 'ReadVariableNames', true);

% 2. 信号名集合，严格与表头一致
signals = { ...
    'cycle', ...
    'data_in', ...
    'data_in_valid', ...
    'data_out', ...
    'data_out_valid', ...
    'u_sos0_data_out', ...
    'u_sos0_data_valid_out', ...
    'mul_b0_x_a', 'mul_b0_x_b', 'mul_b0_x_p', ...
    'mul_b1_x_a', 'mul_b1_x_b', 'mul_b1_x_p', ...
    'mul_b2_x_a', 'mul_b2_x_b', 'mul_b2_x_p', ...
    'mul_a1_y_a', 'mul_a1_y_b', 'mul_a1_y_p', ...
    'mul_a2_y_a', 'mul_a2_y_b', 'mul_a2_y_p', ...
    'x_pipe0', 'x_pipe1', 'x_pipe2', ...
    'y1_pipe0', 'y1_pipe1', 'y1_pipe2', ...
    'y2_pipe0', 'y2_pipe1', 'y2_pipe2', ...
    'valid_pipe0', 'valid_pipe1', 'valid_pipe2' ...
    };

% 3. 找到data_in首次有效的cycle，作为基准
base_signal = 'cycle';
if ismember(base_signal, T.Properties.VariableNames)
    base_cycle = find(abs(T.(base_signal)) > 0, 1, 'first');
    base_cycle_num = T.cycle(base_cycle); % 例如7
else
    base_cycle = 1;
    base_cycle_num = 1;
    warning('基准信号未找到，延迟全部相对第一个cycle');
end

% 4. 理论延迟表，用Map结构，key与signals一致
theorydelay_data = containers.Map();
theorydelay_data('cycle') = -6;
theorydelay_data('data_in') = 0;
theorydelay_data('data_in_valid') = 0;
theorydelay_data('u_sos0_data_out') = 15;
theorydelay_data('u_sos0_data_valid_out') = 15;
theorydelay_data('data_out') = 60;
theorydelay_data('data_out_valid') = 60;
theorydelay_data('mul_b0_x_a') = 2;
theorydelay_data('mul_b0_x_b') = 2;
theorydelay_data('mul_b0_x_p') = 14;
theorydelay_data('mul_b1_x_a') = 1;
theorydelay_data('mul_b1_x_b') = 1;
theorydelay_data('mul_b1_x_p') = 14;
theorydelay_data('mul_b2_x_a') = 0;
theorydelay_data('mul_b2_x_b') = 0;
theorydelay_data('mul_b2_x_p') = 14;
theorydelay_data('mul_a1_y_a') = 2;
theorydelay_data('mul_a1_y_b') = 2;
theorydelay_data('mul_a1_y_p') = 14;
theorydelay_data('mul_a2_y_a') = 2;
theorydelay_data('mul_a2_y_b') = 2;
theorydelay_data('mul_a2_y_p') = 14;
theorydelay_data('x_pipe0') = 0;
theorydelay_data('x_pipe1') = 1;
theorydelay_data('x_pipe2') = 2;
theorydelay_data('y1_pipe0') = 0;
theorydelay_data('y1_pipe1') = 1;
theorydelay_data('y1_pipe2') = 2;
theorydelay_data('y2_pipe0') = 0;
theorydelay_data('y2_pipe1') = 1;
theorydelay_data('y2_pipe2') = 2;
theorydelay_data('valid_pipe0') = 0;
theorydelay_data('valid_pipe1') = 1;
theorydelay_data('valid_pipe2') = 2;

% 5. 主循环，统计每个信号首次有效的cycle和时刻
delay_table = cell(length(signals), 6);
delay_table(:,1) = signals';

one_cycle_us = 1; % 1个周期=1us

for i = 1:length(signals)
    if ismember(signals{i}, T.Properties.VariableNames)
        sig = T.(signals{i});
        idx = find(abs(sig) > 0, 1, 'first');
        if isempty(idx)
            delay_table{i,2} = NaN;
            delay_table{i,3} = NaN;
            delay_table{i,4} = NaN;
        else
            delay_table{i,2} = T.cycle(idx); % 首次有效的cycle值
            delay_table{i,3} = T.cycle(idx) - base_cycle_num; % Delay_vs_data_in
            delay_table{i,4} = T.cycle(idx) * one_cycle_us; % 实际时刻(us)
        end
    else
        delay_table{i,2} = NaN;
        delay_table{i,3} = NaN;
        delay_table{i,4} = NaN;
    end

    if theorydelay_data.isKey(signals{i})
        delay_table{i,5} = theorydelay_data(signals{i});
        delay_table{i,6} = (base_cycle_num + theorydelay_data(signals{i})) * one_cycle_us;
    else
        delay_table{i,5} = NaN;
        delay_table{i,6} = NaN;
    end
end

delay_tbl = cell2table(delay_table, ...
    'VariableNames', {'Signal','RTL_cycle','RTL_Delay','ActualTime_us','TheoryDelay','TheoryTime_us'});
disp(delay_tbl)