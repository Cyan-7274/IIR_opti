% 自动对齐并对比RTL与Matlab的输出误差、溢出检测
clear; close all; clc

% 1. 读取RTL和matlab参考输出
rtltable = readtable('D:\A_Hesper\IIRfilter\qts\tb\rtl_trace.txt', 'Delimiter', ' ', 'ReadVariableNames', true);
mat = load('D:\A_Hesper\IIRfilter\qts\sim\reference_data.mat'); % 假设有matlab参考数据

% 2. 获取有效数据（以data_out_valid对齐）
valid_idx = find(rtltable.data_out_valid ~= 0);
rtl_data = double(rtltable.data_out(valid_idx));
rtl_cycle = rtltable.cycle(valid_idx);

% 3. Matlab数据对齐（如需要可加延迟补偿）
matlab_data = double(mat.y_q22(1:length(rtl_data))); % 假设matlab输出变量为y_q22

% 4. 误差计算
diff = rtl_data - matlab_data;

% 5. 溢出点检测
q22_max = 2^21-1; q22_min = -2^21;
is_sat = (rtl_data >= q22_max) | (rtl_data <= q22_min);

% 6. 绘制对比
figure;
subplot(2,1,1);
plot(rtl_cycle, rtl_data/2^22, 'r'); hold on;
plot(rtl_cycle, matlab_data/2^22, 'k--');
legend('RTL data\_out','Matlab y\_q22');
xlabel('Cycle'); ylabel('Q2.22 Value');
title('RTL vs Matlab 输出对比');
sat_idx = find(is_sat);
if ~isempty(sat_idx)
    plot(rtl_cycle(sat_idx), rtl_data(sat_idx)/2^22, 'bo','MarkerSize',6, 'DisplayName','Saturation');
end

subplot(2,1,2);
plot(rtl_cycle, diff/2^22, 'b');
xlabel('Cycle'); ylabel('误差 (RTL-Matlab)');
title('输出误差（RTL-Matlab）');
if ~isempty(sat_idx)
    hold on; plot(rtl_cycle(sat_idx), diff(sat_idx)/2^22, 'ro','MarkerSize',6);
    legend('误差','溢出点');
end

% 7. 输出溢出点和大误差点
fprintf('最大误差: %.6f (Q2.22)\n', max(abs(diff))/2^22);
fprintf('溢出点数量: %d/%d\n', sum(is_sat), length(is_sat));
if sum(is_sat)>0
    fprintf('溢出点cycle范围: %d ~ %d\n', rtl_cycle(sat_idx(1)), rtl_cycle(sat_idx(end)));
end