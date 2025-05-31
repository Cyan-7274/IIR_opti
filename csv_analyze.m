clear; close all; clc

% -------------- 配置：信号链理论顺序，严格对应tb的表头 -----------------
signals = { ...
    'data_in', 'data_in_valid', ...
    'u_sos0_data_in', 'u_sos0_data_valid_in', ...
    'u_sos0_data_out', 'u_sos0_data_valid_out', ...
    'u_sos1_data_in', 'u_sos1_data_valid_in', ...
    'u_sos1_data_out', 'u_sos1_data_valid_out', ...
    'u_sos2_data_in', 'u_sos2_data_valid_in', ...
    'u_sos2_data_out', 'u_sos2_data_valid_out', ...
    'u_sos3_data_in', 'u_sos3_data_valid_in', ...
    'u_sos3_data_out', 'u_sos3_data_valid_out', ...
    'data_out', 'data_out_valid', ...
    'u_sos0_w0_reg','u_sos0_w1','u_sos0_w2', ...
    'u_sos0_b0','u_sos0_w0_reg','u_sos0_p_b0_w0', ...
    'u_sos0_b1','u_sos0_w1','u_sos0_p_b1_w1', ...
    'u_sos0_b2','u_sos0_w2','u_sos0_p_b2_w2', ...
    'u_sos0_a1','u_sos0_w1','u_sos0_p_a1_w1', ...
    'u_sos0_a2','u_sos0_w2','u_sos0_p_a2_w2', ...
    'u_sos0_valid_pipe0','u_sos0_valid_pipe1','u_sos0_valid_pipe2', ...
    'u_sos0_acc_sum_w0','u_sos0_acc_sum_y' ...
    };

% -------------- 读取RTL数据 -----------------
T = readtable('D:/A_Hesper/IIRfilter/qts/tb/rtl_trace.txt', 'Delimiter', ' ', 'ReadVariableNames', true);

% -------------- 理论延迟表（以data_in为0点，假设每sos级延迟14拍，data_out多1拍） -----------------
theorydelay_data = containers.Map();
theorydelay_data('data_in') = 0;
theorydelay_data('data_in_valid') = 0;
theorydelay_data('u_sos0_data_in') = 0;
theorydelay_data('u_sos0_data_valid_in') = 0;
theorydelay_data('u_sos0_data_out') = 14;
theorydelay_data('u_sos0_data_valid_out') = 14;
theorydelay_data('u_sos1_data_in') = 14;
theorydelay_data('u_sos1_data_valid_in') = 14;
theorydelay_data('u_sos1_data_out') = 28;
theorydelay_data('u_sos1_data_valid_out') = 28;
theorydelay_data('u_sos2_data_in') = 28;
theorydelay_data('u_sos2_data_valid_in') = 28;
theorydelay_data('u_sos2_data_out') = 42;
theorydelay_data('u_sos2_data_valid_out') = 42;
theorydelay_data('u_sos3_data_in') = 42;
theorydelay_data('u_sos3_data_valid_in') = 42;
theorydelay_data('u_sos3_data_out') = 56;
theorydelay_data('u_sos3_data_valid_out') = 56;
theorydelay_data('data_out') = 57; % 多顶层寄存器一拍
theorydelay_data('data_out_valid') = 57;

% 其余内部信号可不填或置为NaN

% -------------- 找到基准起点（第一个data_in非零） -----------------
base_signal = 'data_in';
if ismember(base_signal, T.Properties.VariableNames)
    base_cycle = find(abs(T.(base_signal)) > 0, 1, 'first');
    base_cycle_num = T.cycle(base_cycle);
else
    base_cycle = 1;
    base_cycle_num = 1;
    warning('基准信号未找到，延迟全部相对第一个cycle');
end

% -------------- 统计延迟 --------------
delay_table = cell(length(signals), 4);
delay_table(:,1) = signals';

for i = 1:length(signals)
    sig_name = signals{i};
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
    if theorydelay_data.isKey(sig_name)
        delay_table{i,3} = base_cycle_num + theorydelay_data(sig_name);
    else
        delay_table{i,3} = NaN;
    end
    delay_table{i,4} = delay_table{i,2} - delay_table{i,3};
end

delay_tbl = cell2table(delay_table, ...
    'VariableNames', {'Signal','RTL_cycle','TheoryCycle','CycleDiff'});
disp(delay_tbl)