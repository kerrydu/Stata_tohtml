function opt = take_options(opt, args)
%TAKE_OPTIONS  Apply name-value pairs. Char defaults stay char.
if isempty(args)
    return
end
index = 1;
while index <= numel(args)
    if index == numel(args)
        error('matlab_tohtml:Option', '选项 %s 缺少取值', as_char(args{index}));
    end
    key = as_char(args{index});
    if ~isfield(opt, key)
        error('matlab_tohtml:Option', '未知选项 %s', key);
    end
    value = args{index + 1};
    if ischar(opt.(key))
        value = as_char(value);
    end
    opt.(key) = value;
    index = index + 2;
end
end
