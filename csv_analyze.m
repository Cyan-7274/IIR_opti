clear; close all; clc

% -------------- 信号链严格对应tb表头 -----------------
signals = { ...
    'data_in', 'data_in_valid', ...
    'u_sos0_data_valid_in', 'u_sos0_data_in', ...
    'u_sos0_w0','u_sos0_w1','u_sos0_w2' ...
    'u_sos0_data_valid_out', 'u_sos0_data_out', ...
    'u_sos1_data_valid_in', 'u_sos1_data_in', 'u_sos1_data_valid_out', 'u_sos1_data_out', ...
    'u_sos2_data_valid_in', 'u_sos2_data_in', 'u_sos2_data_valid_out', 'u_sos2_data_out', ...
    'u_sos3_data_valid_in', 'u_sos3_data_in', 'u_sos3_data_valid_out', 'u_sos3_data_out', ...
    'data_out', 'data_out_valid', ...

    };

% -------------- 读取RTL数据 -----------------
T = readtable('D:/A_Hesper/IIRfilter/qts/tb/rtl_trace.txt', 'Delimiter', ' ', 'ReadVariableNames', true);

% -------------- 理论延迟表（每级15*1拍，输出寄存器1拍） -----------------
theorydelay_data = containers.Map();
% -------------- 理论延迟表（每级15*1拍，输出寄存器1拍） -----------------
theorydelay_data = containers.Map();
theorydelay_data('data_in') = 0;
theorydelay_data('data_in_valid') = 0;
theorydelay_data('u_sos0_data_valid_in') = 0;
theorydelay_data('u_sos0_data_in') = 0;

theorydelay_data('u_sos0_w0') = 2;  % data_in 有效后第 2 拍
theorydelay_data('u_sos0_w1') = 3;  % w0 再晚 1 拍
theorydelay_data('u_sos0_w2') = 4;  % w1 再晚 1 拍

theorydelay_data('u_sos0_data_valid_out') = 15*1;
theorydelay_data('u_sos0_data_out') = 15*1;
theorydelay_data('u_sos1_data_valid_in') = 15*1;
theorydelay_data('u_sos1_data_in') = 15*1;
theorydelay_data('u_sos1_data_valid_out') = 15*2;
theorydelay_data('u_sos1_data_out') = 15*2;
theorydelay_data('u_sos2_data_valid_in') = 15*2;
theorydelay_data('u_sos2_data_in') = 15*2;
theorydelay_data('u_sos2_data_valid_out') = 15*3;
theorydelay_data('u_sos2_data_out') = 15*3;
theorydelay_data('u_sos3_data_valid_in') = 15*3;
theorydelay_data('u_sos3_data_in') = 15*3;
theorydelay_data('u_sos3_data_valid_out') = 15*4;
theorydelay_data('u_sos3_data_out') = 15*4;
theorydelay_data('data_out_valid') = 15*4;
theorydelay_data('data_out') = 15*4;

base_signal = 'data_in';
if ismember(base_signal, T.Properties.VariableNames)
    base_cycle = find(abs(T.(base_signal)) > 0, 1, 'first');
    base_cycle_num = T.cycle(base_cycle);
else
    base_cycle = 1;
    base_cycle_num = 1;
    warning('基准信号未找到，延迟全部相对第一个cycle');
end

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
            delay_table{i,2} = T.cycle(idx);
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