function result = regress(y, x, varargin)
%REGRESS  带常数项的最小二乘，对应 Stata regress。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   m = matlab_tohtml.regress(price, {"油耗", mpg, "车重", weight})
%   m.params.('油耗')
%   m.bse.('常数项')
%   m.pvalues, m.nobs, m.rsquared
if nargin < 2
    x = {};
end
opt = struct();
opt.const = '常数项';
opt.add_const = true;
if nargin >= 3
    opt = take_options(opt, varargin);
end
result = ols_fit(y, normalize_columns(x), as_char(opt.const), logical(opt.add_const));
end
