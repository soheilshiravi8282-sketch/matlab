function bridge_watcher(folder)
% BRIDGE_WATCHER  Watches a shared folder for request.json (written by the
% HTML page), runs analysis_headless() on it, and writes response.json
% back. This avoids any networking / Java / toolbox dependency — it's
% just fopen/fread/fwrite in a loop, which works on every MATLAB install.
%
% USAGE:
%   1. Put this file, analysis_headless.m, PlateSolver.m, FEMesh.m and
%      the rest of your computational .m files in the SAME folder.
%   2. In MATLAB, cd to that folder and run:  bridge_watcher
%   3. Open index.html in Chrome or Edge, click "انتخاب پوشه اشتراکی"
%      and choose that SAME folder.
%   4. Fill in the parameters and click "اجرای تحلیل". Keep this MATLAB
%      session running in the background. Ctrl+C here to stop watching.

    if nargin < 1
        folder = pwd;
    end
    addpath(genpath(folder));

    reqFile = fullfile(folder, 'request.json');
    resFile = fullfile(folder, 'response.json');

    fprintf('✔ در حال پایش پوشه:\n   %s\n', folder);
    fprintf('  منتظر request.json از صفحه HTML هستم... (Ctrl+C برای توقف)\n');

    while true
        if exist(reqFile, 'file') == 2
            try
                raw = fileread(reqFile);
                p = jsondecode(raw);
                fprintf('⏱ درخواست جدید دریافت شد، در حال تحلیل...\n');
                result = analysis_headless(p);
                jsonStr = jsonencode(result);
                fprintf('✔ تحلیل با موفقیت انجام شد.\n');
            catch ME
                jsonStr = jsonencode(struct('status', 'error', 'message', ME.message));
                fprintf('✖ خطا: %s\n', ME.message);
            end

            fid = fopen(resFile, 'w');
            fwrite(fid, jsonStr, 'char');
            fclose(fid);

            % Remove the request so we don't process it twice
            delete(reqFile);
        end
        pause(0.4);
    end
end
