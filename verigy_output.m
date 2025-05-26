clear;close all; clc
N = 1024;
num_stages = 4; % SOS级数

for stage = 1:num_stages
    fname_matlab = sprintf('stage%d_output.hex',stage);
    fname_rtl = sprintf('sos%d_output.hex',stage);

    % Matlab输出
    fid = fopen(fname_matlab,'r');
    y_matlab_hex = textscan(fid, '%6s');
    fclose(fid);
    y_matlab = hex2dec(char(y_matlab_hex{1}));
    y_matlab(y_matlab >= 2^23) = y_matlab(y_matlab >= 2^23) - 2^24;
    y_matlab = double(y_matlab) / 2^22;

    % RTL输出
    fid = fopen(fname_rtl,'r');
    y_rtl_hex = textscan(fid, '%6s');
    fclose(fid);
    y_rtl = hex2dec(char(y_rtl_hex{1}));
    y_rtl(y_rtl >= 2^23) = y_rtl(y_rtl >= 2^23) - 2^24;
    y_rtl = double(y_rtl) / 2^22;

    minlen = min(length(y_matlab), length(y_rtl));
    y_matlab = y_matlab(1:minlen);
    y_rtl = y_rtl(1:minlen);

    err = y_matlab - y_rtl;
    rel_err = err ./ max(abs(y_matlab), 1e-9);

    figure;
    subplot(3,1,1); plot(y_matlab,'b'); hold on; plot(y_rtl,'r--');
    legend('Matlab逐级定点','RTL'); title(sprintf('第%d级输出对比',stage));
    subplot(3,1,2); plot(err,'k'); ylabel('绝对误差');
    subplot(3,1,3); plot(rel_err*100,'m'); ylabel('相对误差(%%)'); xlabel('采样点');
    sgtitle(sprintf('第%d级SOS输出对比',stage));
    fprintf('Stage %d: max abs err = %.4g, max rel err = %.2f%%\n',stage,max(abs(err)),max(abs(rel_err))*100);
end