clear; close all; clc;
T = readtable('D:/A_Hesper/IIRfilter/qts/sim/all_sos_full_pipeline.csv');
Q = 2^22;

% ------------ 1. 输入信号与理论sos0输出对比 -------------
in = T.data_in / Q;
out = T.sos0_data_out / Q;
vld = T.sos0_data_valid_out;

% 用户需提供matlab理论sos0输出
theory_out = matlab_sos0_out(:); % 保证长度配齐

figure;
subplot(3,1,1); plot(in, 'b'); title('输入信号Q2.22');
subplot(3,1,2); plot(out, 'r'); hold on; plot(theory_out, 'b--');
legend('RTL', 'MATLAB理论'); title('sos0输出RTL vs 理论');
subplot(3,1,3); plot(out-theory_out); title('输出误差');

% ------------ 2. 各乘法器流水线对比（仅显示头/尾级） -------------
pipe_num = 12;
fields = {'b0','b1','b2','a1','a2'};
for f = 1:length(fields)
    pipe_head = T.(sprintf('sos0_%s_a_pipe0', fields{f}));
    pipe_tail = T.(sprintf('sos0_%s_a_pipe%d', fields{f}, pipe_num));
    figure;
    plot(pipe_head, 'b'); hold on; plot(pipe_tail, 'r');
    legend('头级','尾级'); title(sprintf('%s乘法器a_pipe，延迟对比', fields{f}));
end

% ------------ 3. 乘法器最终p输出 vs 理论值（需matlab变量） -------------
b0_p = T.sos0_b0_p / Q;
b1_p = T.sos0_b1_p / Q;
b2_p = T.sos0_b2_p / Q;
a1_p = T.sos0_a1_p / Q;
a2_p = T.sos0_a2_p / Q;

% 用户需提供理论p值（matlab_b0_p等）
figure;
hold on
plot(b0_p, 'r'); plot(matlab_b0_p, 'b--'); title('b0乘法器输出p对比'); legend('RTL','理论');
figure;
hold on
plot(b1_p, 'r'); plot(matlab_b1_p, 'b--'); title('b1乘法器输出p对比'); legend('RTL','理论');
% ...其他乘法器同理

% ------------ 4. 反馈寄存器y1_pipe/y2_pipe对比 -------------
y1_pipe = T.sos0_y1_pipe / Q;
y2_pipe = T.sos0_y2_pipe / Q;
figure; plot(y1_pipe, 'r'); hold on; plot(matlab_y1, 'b--'); legend('RTL','理论');
title('y1_pipe反馈对比');
figure; plot(y2_pipe, 'r'); hold on; plot(matlab_y2, 'b--'); legend('RTL','理论');
title('y2_pipe反馈对比');

% ------------ 5. 累加器acc_sum对比 -------------
acc_sum = T.sos0_acc_sum / Q;
figure; plot(acc_sum, 'r'); hold on; plot(matlab_acc_sum, 'b--'); legend('RTL','理论');
title('acc_sum累加对比');

% ------------ 6. 输出valid信号延迟分析 -------------
valid_idx = find(vld==1);
figure; plot(valid_idx, out(valid_idx), 'r.'); hold on; plot(valid_idx, theory_out(valid_idx), 'b.');
title('输出有效data_valid_out=1时对齐对比');
legend('RTL','理论');
