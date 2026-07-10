function results = analyzeCampaign(nRuns, options)
%ANALYZECAMPAIGN Run LogisticsMission Monte Carlo analysis without side effects.
%   results = analyzeCampaign(nRuns) simulates nRuns independent campaigns
%   and returns extracted sustainment metrics for use in scripts and UI.

arguments
    nRuns (1,1) double {mustBeInteger, mustBePositive} = 30
    options.DisplaySummary (1,1) logical = false
    options.MakePlots (1,1) logical = false
end

evalin('base', 'scenarioParams');

campaignHr = evalin('base', 'CAMPAIGN_HR');
dispatchPeriodHr = evalin('base', 'DISPATCH_PERIOD_HR');
convoyCargoTons = evalin('base', 'CONVOY_CARGO_TONS');
model = 'LogisticsMission';

load_system(model);

simIn(1:nRuns) = Simulink.SimulationInput(model);
for idx = 1:nRuns
    simIn(idx) = simIn(idx).setVariable('RUN_SEED_NORTH', 1000 + 2 * idx);
    simIn(idx) = simIn(idx).setVariable('RUN_SEED_SOUTH', 2000 + 2 * idx + 1);
end

simOut = sim(simIn);
tGrid = (0:campaignHr)';

delivered = zeros(nRuns, 1);
lost = zeros(nRuns, 1);
kills = zeros(nRuns, 1);
minStock = zeros(nRuns, 1);
dryHours = zeros(nRuns, 1);
stockGrid = zeros(nRuns, numel(tGrid));
routeNorthCount = zeros(nRuns, 1);
routeSouthCount = zeros(nRuns, 1);

for idx = 1:nRuns
    summary = summarizeRun(simOut(idx), tGrid, convoyCargoTons, dispatchPeriodHr);
    delivered(idx) = summary.DeliveredTons;
    lost(idx) = summary.LostTons;
    kills(idx) = summary.ConvoysKilled;
    minStock(idx) = summary.MinStockTons;
    dryHours(idx) = summary.DryHours;
    stockGrid(idx, :) = summary.StockGrid;
    routeNorthCount(idx) = summary.RouteNorthCount;
    routeSouthCount(idx) = summary.RouteSouthCount;
end

dispatchedTons = (floor(campaignHr / dispatchPeriodHr) + 1) * convoyCargoTons;
routeTotalCount = routeNorthCount + routeSouthCount;
routeNorthSharePct = 100 * routeNorthCount ./ max(routeTotalCount, 1);
throughputPct = 100 * delivered / dispatchedTons;
singleRun = summarizeRun(simOut(1), tGrid, convoyCargoTons, dispatchPeriodHr);

results = struct( ...
    'nRuns', nRuns, ...
    'campaignHr', campaignHr, ...
    'tGrid', tGrid, ...
    'dispatchedTons', dispatchedTons, ...
    'delivered', delivered, ...
    'lost', lost, ...
    'kills', kills, ...
    'minStock', minStock, ...
    'dryHours', dryHours, ...
    'stockGrid', stockGrid, ...
    'throughputPct', throughputPct, ...
    'routeNorthCount', routeNorthCount, ...
    'routeSouthCount', routeSouthCount, ...
    'routeNorthSharePct', routeNorthSharePct, ...
    'singleRun', singleRun);

if options.DisplaySummary
    printSummary(results);
end

if options.MakePlots
    plotCampaignResults(results);
end
end

function summary = summarizeRun(out, tGrid, convoyCargoTons, dispatchPeriodHr)
stockTs = out.fobStock;
stockGrid = interp1(stockTs.Time, stockTs.Data, tGrid, 'previous', 'extrap');

routeTs = out.routeSelected;
routeValues = routeTs.Data(:);
validRouteMask = ~isnan(routeValues) & routeValues > 0;
routeValues = routeValues(validRouteMask);

summary = struct( ...
    'TimeDays', stockTs.Time(:) / 24, ...
    'StockTons', stockTs.Data(:), ...
    'DeliveredSeriesTons', out.deliveredTons.Data(:), ...
    'LostSeriesTons', out.lostTons.Data(:), ...
    'KilledSeries', out.convoysKilled.Data(:), ...
    'RouteTimeDays', routeTs.Time(:) / 24, ...
    'RouteSelected', routeTs.Data(:), ...
    'DeliveredTons', out.deliveredTons.Data(end), ...
    'LostTons', out.lostTons.Data(end), ...
    'ConvoysKilled', out.convoysKilled.Data(end), ...
    'MinStockTons', min(stockGrid), ...
    'DryHours', sum(stockGrid <= 0), ...
    'StockGrid', stockGrid(:)', ...
    'RouteNorthCount', sum(routeValues == 1), ...
    'RouteSouthCount', sum(routeValues == 2), ...
    'DispatchPeriodHr', dispatchPeriodHr, ...
    'ConvoyCargoTons', convoyCargoTons);
end

function printSummary(results)
fprintf('\n===== Operation IRON RELAY - %d-run campaign summary =====\n', results.nRuns);
fprintf('Tons dispatched per campaign : %8.0f\n', results.dispatchedTons);
fprintf('Tons delivered (mean +/- sd) : %8.1f +/- %.1f  (%.1f%% throughput)\n', ...
    mean(results.delivered), std(results.delivered), mean(results.throughputPct));
fprintf('Tons lost to red (mean)      : %8.1f\n', mean(results.lost));
fprintf('Convoys destroyed (mean)     : %8.2f\n', mean(results.kills));
fprintf('Min FOB stock (mean)         : %8.1f tons\n', mean(results.minStock));
fprintf('P(FOB goes dry)              : %8.1f%%\n', 100 * mean(results.dryHours > 0));
end

function plotCampaignResults(results)
colBlue = [0.41 0.71 0.98];
colRed = [0.93 0.44 0.34];
colSand = [0.24 0.30 0.38];
colGray = [0.44 0.49 0.57];
colOlive = [0.29 0.82 0.66];
figBg = [0.08 0.10 0.13];
axesBg = [0.10 0.12 0.16];
textPrimary = [0.92 0.95 0.98];
textMuted = [0.68 0.74 0.80];
gridColor = [0.27 0.32 0.39];

fig = figure( ...
    'Name', 'Operation IRON RELAY - campaign results', ...
    'Color', figBg, ...
    'Position', [80 80 1180 760]);
tl = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
titleHandle = title(tl, sprintf('Operation IRON RELAY - %d-day contested resupply, %d realizations', ...
    round(results.campaignHr / 24), results.nRuns));
titleHandle.Color = textPrimary;

ax1 = nexttile(tl, [1 2]);
applyDarkAxesTheme(ax1, axesBg, textPrimary, textMuted, gridColor);
hold(ax1, 'on');
stockP10 = prctile(results.stockGrid, 10, 1);
stockP90 = prctile(results.stockGrid, 90, 1);
fill(ax1, ...
    [results.tGrid; flipud(results.tGrid)] / 24, ...
    [stockP10'; flipud(stockP90')], ...
    [0.15 0.30 0.40], ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.85);
plot(ax1, results.tGrid / 24, results.stockGrid', 'Color', colGray, 'LineWidth', 0.5);
plot(ax1, results.tGrid / 24, median(results.stockGrid, 1), 'Color', colBlue, 'LineWidth', 2.2);
yline(ax1, 0, '--', 'FOB dry', 'Color', colRed, 'LineWidth', 1.1, ...
    'LabelHorizontalAlignment', 'left');
grid(ax1, 'on');
ax1.GridAlpha = 0.12;
xlabel(ax1, 'Campaign day');
ylabel(ax1, 'FOB stockpile (tons)');
title(ax1, 'Stockpile envelope - every run, 10-90% band, median');
hold(ax1, 'off');

ax2 = nexttile(tl);
applyDarkAxesTheme(ax2, axesBg, textPrimary, textMuted, gridColor);
histogram(ax2, results.delivered, ...
    'FaceColor', colBlue, 'EdgeColor', axesBg, 'LineWidth', 1);
xline(ax2, results.dispatchedTons, '--', 'Dispatched', ...
    'Color', colOlive, 'LineWidth', 1.1);
grid(ax2, 'on');
ax2.GridAlpha = 0.12;
xlabel(ax2, 'Tons delivered per campaign');
ylabel(ax2, 'Realizations');
title(ax2, 'Delivered tonnage distribution');

ax3 = nexttile(tl);
applyDarkAxesTheme(ax3, axesBg, textPrimary, textMuted, gridColor);
dryMask = results.dryHours > 0;
scatter(ax3, results.delivered(~dryMask), results.lost(~dryMask), ...
    42, colSand, 'filled', 'MarkerEdgeColor', colBlue, 'LineWidth', 0.8);
hold(ax3, 'on');
scatter(ax3, results.delivered(dryMask), results.lost(dryMask), ...
    52, colRed, 'filled', 'MarkerEdgeColor', [0.98 0.62 0.56], 'LineWidth', 0.8);
grid(ax3, 'on');
ax3.GridAlpha = 0.12;
xlabel(ax3, 'Delivered tons');
ylabel(ax3, 'Lost tons');
title(ax3, 'Campaign outcomes');
legendHandle = legend(ax3, {'Sustained FOB', 'FOB went dry'}, 'Location', 'best');
styleDarkLegend(legendHandle, axesBg, textPrimary);
hold(ax3, 'off');

ax4 = nexttile(tl);
applyDarkAxesTheme(ax4, axesBg, textPrimary, textMuted, gridColor);
histogram(ax4, results.routeNorthSharePct, ...
    'FaceColor', colOlive, 'EdgeColor', axesBg, 'LineWidth', 1);
xline(ax4, mean(results.routeNorthSharePct), '--', 'Mean north share', ...
    'Color', colBlue, 'LineWidth', 1.1);
grid(ax4, 'on');
ax4.GridAlpha = 0.12;
xlabel(ax4, 'Convoys routed north (%)');
ylabel(ax4, 'Realizations');
title(ax4, 'Adaptive routing mix');
end

function applyDarkAxesTheme(ax, axesBg, textPrimary, textMuted, gridColor)
ax.Color = axesBg;
ax.XColor = textMuted;
ax.YColor = textMuted;
ax.GridColor = gridColor;
ax.MinorGridColor = gridColor;
ax.Title.Color = textPrimary;
ax.XLabel.Color = textMuted;
ax.YLabel.Color = textMuted;
end

function styleDarkLegend(legendHandle, axesBg, textPrimary)
legendHandle.Color = axesBg;
legendHandle.TextColor = textPrimary;
end
