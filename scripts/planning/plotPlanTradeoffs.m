function fig = plotPlanTradeoffs(optimizer)
%PLOTPLANTRADEOFFS Visualize optimizer history and the best route plan.

arguments
    optimizer struct
end

history = optimizer.History;
bestEval = optimizer.BestEvaluation;

fig = figure( ...
    'Name', 'Operation IRON RELAY - mission planner tradeoffs', ...
    'Color', [0.08 0.10 0.13], ...
    'Position', [120 120 1180 760]);

tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Operation IRON RELAY - outer-loop mission planner');

ax1 = nexttile(tl);
plot(ax1, 1:height(history), history.MeanCost, '-o', ...
    'Color', [0.41 0.71 0.98], 'MarkerFaceColor', [0.41 0.71 0.98], 'MarkerSize', 4);
styleAxes(ax1);
xlabel(ax1, 'Candidate evaluation');
ylabel(ax1, 'Mean cost');
title(ax1, 'Search history');

ax2 = nexttile(tl);
scatter(ax2, history.MeanDeliveredTons, history.MeanLostTons, 36, history.MeanCost, 'filled');
styleAxes(ax2);
colormap(ax2, turbo);
cb = colorbar(ax2);
cb.Color = [0.92 0.95 0.98];
xlabel(ax2, 'Mean delivered tons');
ylabel(ax2, 'Mean lost tons');
title(ax2, 'Cost-colored tradeoff cloud');

ax3 = nexttile(tl);
stairs(ax3, (0:numel(bestEval.RouteSequence)-1) * bestEval.DispatchPeriodHr / 24, bestEval.RouteSequence, ...
    'Color', [0.29 0.82 0.66], 'LineWidth', 2);
styleAxes(ax3);
ax3.YTick = [1 2];
ax3.YTickLabel = {'North', 'South'};
xlabel(ax3, 'Campaign day');
ylabel(ax3, 'Assigned route');
title(ax3, 'Best plan route sequence');

ax4 = nexttile(tl);
plot(ax4, bestEval.tGrid / 24, bestEval.StockGrid', 'Color', [0.36 0.40 0.46], 'LineWidth', 0.7);
hold(ax4, 'on');
plot(ax4, bestEval.tGrid / 24, mean(bestEval.StockGrid, 1), 'Color', [0.41 0.71 0.98], 'LineWidth', 2.4);
yline(ax4, 0, '--', 'FOB dry', 'Color', [0.93 0.44 0.34], 'LineWidth', 1.1);
styleAxes(ax4);
xlabel(ax4, 'Campaign day');
ylabel(ax4, 'Stockpile (tons)');
title(ax4, 'Best plan stockpile outcomes');
hold(ax4, 'off');
end

function styleAxes(ax)
ax.Color = [0.10 0.12 0.16];
ax.XColor = [0.68 0.74 0.80];
ax.YColor = [0.68 0.74 0.80];
ax.GridColor = [0.27 0.32 0.39];
ax.Title.Color = [0.92 0.95 0.98];
ax.XLabel.Color = [0.68 0.74 0.80];
ax.YLabel.Color = [0.68 0.74 0.80];
ax.GridAlpha = 0.12;
grid(ax, 'on');
end
