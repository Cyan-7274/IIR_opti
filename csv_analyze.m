clear; close all; clc

% 1. 读取文件
T = readtable('D:\A_Hesper\IIRfilter\qts\tb\rtl_trace.txt', 'Delimiter', ' ', 'ReadVariableNames', true);

% 2. 信号名集合，和表头严格一致
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
base_signal = 'data_in';
if ismember(base_signal, T.Properties.VariableNames)
    base_cycle = find(abs(T.(base_signal)) > 0, 1, 'first');
    base_cycle_num = T.cycle(base_cycle);
else
    base_cycle = 1;
    base_cycle_num = 1;
    warning('基准信号未找到，延迟全部相对第一个cycle');
end

% 4. 理论延迟表
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

% 5. 构造延迟统计表
delay_table = cell(length(signals), 4);
delay_table(:,1) = signals';

for i = 1:length(signals)
    sig_name = signals{i};
    % RTL首个有效周期
    if ismember(sig_name, T.Properties.VariableNames)
        sig = T.(sig_name);
        idx = find(abs(sig) > 0, 1, 'first');
        if isempty(idx)
            delay_table{i,2} = NaN;
        else
            delay_table{i,2} = T.cycle(idx); % RTL首个有效周期
        end
    else
        delay_table{i,2} = NaN;
    end

    % 理论首个有效周期
    if theorydelay_data.isKey(sig_name)
        delay_table{i,3} = base_cycle_num + theorydelay_data(sig_name);
    else
        delay_table{i,3} = NaN;
    end

    % 差异
    delay_table{i,4} = delay_table{i,2} - delay_table{i,3};
end

delay_tbl = cell2table(delay_table, ...
    'VariableNames', {'Signal','RTL_cycle','TheoryCycle','CycleDiff'});

disp(delay_tbl)