function opt = report_options()
%REPORT_OPTIONS  Defaults shared by run, build and gather.
opt = struct();
opt.mode = 'full';
opt.embed = false;
opt.mathjax = [];
opt.tabwidth = '100%';
opt.tabheight = '80vh';
opt.clean = false;
opt.cleancode = false;
opt.html = '';
opt.md = '';
opt.log = '';
opt.zoom = '';
opt.width = '';
opt.height = '';
end
