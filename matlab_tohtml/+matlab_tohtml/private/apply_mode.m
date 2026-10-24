function opt = apply_mode(opt)
%APPLY_MODE  Turn clean / cleancode into the report mode.
if logical(opt.clean) && logical(opt.cleancode)
    error('matlab_tohtml:Option', 'clean 和 cleancode 不能同时用');
end
if logical(opt.clean)
    opt.mode = 'clean';
elseif logical(opt.cleancode)
    opt.mode = 'cleancode';
end
opt.mode = as_char(opt.mode);
if ~any(strcmp(opt.mode, {'full', 'clean', 'cleancode'}))
    error('matlab_tohtml:Option', '未知报告模式 %s', opt.mode);
end
end
