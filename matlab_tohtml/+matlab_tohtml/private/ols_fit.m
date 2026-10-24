function result = ols_fit(y, columns, const_name, add_const)
%OLS_FIT  OLS with an optional intercept. No toolbox.
if ~isnumeric(y)
    error('matlab_tohtml:Regress', '因变量要是数值');
end
y = double(y(:));
names = {};
xcolumns = {};
if ~isempty(columns)
    for k = 1:numel(columns)
        values = columns(k).values;
        if ~(isnumeric(values) || islogical(values))
            error('matlab_tohtml:Regress', '%s 要是数值', columns(k).name);
        end
        values = double(values(:));
        if numel(values) ~= numel(y)
            error('matlab_tohtml:Regress', '%s 的长度是 %d，因变量长度是 %d', ...
                columns(k).name, numel(values), numel(y));
        end
        names{end + 1} = columns(k).name; %#ok<AGROW>
        xcolumns{end + 1} = values; %#ok<AGROW>
    end
end
if add_const && any(strcmp(names, const_name))
    error('matlab_tohtml:Regress', '自变量里已经有 %s，和常数项重名', const_name);
end
slope_count = numel(names);
coef_count = slope_count + double(add_const);
if coef_count == 0
    error('matlab_tohtml:Regress', '没有可估计的系数');
end
rows_y = zeros(0, 1);
rows_x = zeros(0, slope_count);
for index = 1:numel(y)
    yi = y(index);
    if isnan(yi)
        continue
    end
    xi = zeros(1, slope_count);
    bad = false;
    for col = 1:slope_count
        value = xcolumns{col}(index);
        if isnan(value)
            bad = true;
            break
        end
        xi(col) = value;
    end
    if bad
        continue
    end
    rows_y(end + 1, 1) = yi; %#ok<AGROW>
    rows_x(end + 1, :) = xi; %#ok<AGROW>
end
nobs = numel(rows_y);
if nobs <= coef_count
    error('matlab_tohtml:Regress', '有效观测只有 %d 个，估计 %d 个系数不够', nobs, coef_count);
end
if add_const
    design = [rows_x ones(nobs, 1)];
    order = [names, {const_name}];
else
    design = rows_x;
    order = names;
end
xtx = design' * design;
xty = design' * rows_y;
try
    inverse = invert_matrix(xtx);
catch
    error('matlab_tohtml:Regress', '回归设计矩阵不满秩');
end
beta = inverse * xty;
fitted = design * beta;
resid = rows_y - fitted;
sse = sum(resid .^ 2);
mean_y = sum(rows_y) / nobs;
sst = sum((rows_y - mean_y) .^ 2);
if sst <= 1e-15
    if sse <= 1e-15
        rsquared = 1;
    else
        rsquared = 0;
    end
else
    rsquared = 1 - sse / sst;
end
df_resid = nobs - coef_count;
sigma2 = sse / df_resid;
params = struct();
bse = struct();
pvalues = struct();
tvalues = struct();
for index = 1:coef_count
    name = order{index};
    coef = beta(index);
    variance = sigma2 * inverse(index, index);
    if variance > 0
        se = sqrt(variance);
    else
        se = 0;
    end
    if se == 0
        if coef == 0
            tstat = 0;
            pvalue = 1;
        else
            tstat = Inf;
            pvalue = 0;
        end
    else
        tstat = coef / se;
        pvalue = t_pvalue(tstat, df_resid);
    end
    params.(name) = coef;
    bse.(name) = se;
    tvalues.(name) = tstat;
    pvalues.(name) = pvalue;
end
result = struct();
result.params = params;
result.bse = bse;
result.pvalues = pvalues;
result.tvalues = tvalues;
result.nobs = nobs;
result.rsquared = rsquared;
result.df_resid = df_resid;
if add_const
    result.const_name = const_name;
else
    result.const_name = '';
end
end

function inverse = invert_matrix(matrix)
n = size(matrix, 1);
work = [matrix eye(n)];
for col = 1:n
    [~, pivot_offset] = max(abs(work(col:n, col)));
    pivot = pivot_offset + col - 1;
    if abs(work(pivot, col)) < 1e-12
        error('matlab_tohtml:Singular', 'singular');
    end
    work([col, pivot], :) = work([pivot, col], :);
    work(col, :) = work(col, :) / work(col, col);
    for row = 1:n
        if row == col
            continue
        end
        factor = work(row, col);
        if factor == 0
            continue
        end
        work(row, :) = work(row, :) - factor * work(col, :);
    end
end
inverse = work(:, n + 1:end);
end

function pvalue = t_pvalue(tstat, df)
if df <= 0
    pvalue = NaN;
    return
end
if isinf(tstat)
    pvalue = 0;
    return
end
x = df / (df + tstat * tstat);
pvalue = regularized_beta(df / 2, 0.5, x);
end

function value = regularized_beta(a, b, x)
if x <= 0
    value = 0;
    return
end
if x >= 1
    value = 1;
    return
end
log_bt = gammaln(a + b) - gammaln(a) - gammaln(b) + a * log(x) + b * log(1 - x);
bt = exp(log_bt);
if x < (a + 1) / (a + b + 2)
    value = bt * betacf(a, b, x) / a;
else
    value = 1 - bt * betacf(b, a, 1 - x) / b;
end
end

function h = betacf(a, b, x)
fpmin = 1e-30;
qab = a + b;
qap = a + 1;
qam = a - 1;
c = 1;
d = 1 - qab * x / qap;
if abs(d) < fpmin
    d = fpmin;
end
d = 1 / d;
h = d;
for m = 1:200
    m2 = 2 * m;
    aa = m * (b - m) * x / ((qam + m2) * (a + m2));
    d = 1 + aa * d;
    if abs(d) < fpmin
        d = fpmin;
    end
    c = 1 + aa / c;
    if abs(c) < fpmin
        c = fpmin;
    end
    d = 1 / d;
    h = h * d * c;
    aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
    d = 1 + aa * d;
    if abs(d) < fpmin
        d = fpmin;
    end
    c = 1 + aa / c;
    if abs(c) < fpmin
        c = fpmin;
    end
    d = 1 / d;
    delta = d * c;
    h = h * delta;
    if abs(delta - 1) < 1e-12
        break
    end
end
end
