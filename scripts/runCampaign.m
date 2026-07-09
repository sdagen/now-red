function results = runCampaign(nRuns)
%RUNCAMPAIGN Monte Carlo campaign analysis for LogisticsMission.
%   results = RUNCAMPAIGN(nRuns) simulates nRuns independent 30-day
%   contested-logistics campaigns (default 30), varying the red force
%   random seeds per run, and reports sustainment metrics for the blue
%   force: delivered tonnage, attrition, and FOB stockpile risk.
%
%   Run scenarioParams first (or let this function do it).

if nargin < 1
    nRuns = 30;
end

% Ensure scenario parameters (and ConvoyBus) exist in the base workspace,
% which the model reads its parameters from.
evalin('base', 'scenarioParams');
campaignHr = evalin('base', 'CAMPAIGN_HR');
consumptionTph = evalin('base', 'FOB_CONSUMPTION_TPH');

model = 'LogisticsMission';
load_system(model);

%% Assemble one SimulationInput per run, varying only the red seeds
simIn(1:nRuns) = Simulink.SimulationInput(model);
for i = 1:nRuns
    simIn(i) = simIn(i).setVariable('RUN_SEED_NORTH', 1000 + 2*i);
    simIn(i) = simIn(i).setVariable('RUN_SEED_SOUTH', 2000 + 2*i + 1);
end

%% Simulate
fprintf('Running %d campaign realizations...\n', nRuns);
simOut = sim(simIn, 'ShowProgress', 'off');

%% Extract metrics onto a common hourly grid
tGrid = (0:campaignHr)';
delivered = zeros(nRuns, 1);
lost      = zeros(nRuns, 1);
kills     = zeros(nRuns, 1);
minStock  = zeros(nRuns, 1);
dryHours  = zeros(nRuns, 1);
stockGrid = zeros(nRuns, numel(tGrid));

for i = 1:nRuns
    out = simOut(i);
    delivered(i) = out.deliveredTons.Data(end);
    lost(i)      = out.lostTons.Data(end);
    kills(i)     = out.convoysKilled.Data(end);

    stockTs = out.fobStock;
    stockGrid(i, :) = interp1(stockTs.Time, stockTs.Data, tGrid, 'previous', 'extrap');
    minStock(i) = min(stockGrid(i, :));
    dryHours(i) = sum(stockGrid(i, :) <= 0);
end

results = struct('delivered', delivered, 'lost', lost, 'kills', kills, ...
    'minStock', minStock, 'dryHours', dryHours, ...
    'tGrid', tGrid, 'stockGrid', stockGrid);

%% Campaign summary
dispatchedTons = (floor(campaignHr / evalin('base','DISPATCH_PERIOD_HR')) + 1) ...
    * evalin('base','CONVOY_CARGO_TONS');
fprintf('\n===== Operation IRON RELAY — %d-run campaign summary =====\n', nRuns);
fprintf('Tons dispatched per campaign : %8.0f\n', dispatchedTons);
fprintf('Tons delivered (mean +/- sd) : %8.1f +/- %.1f  (%.1f%% throughput)\n', ...
    mean(delivered), std(delivered), 100*mean(delivered)/dispatchedTons);
fprintf('Tons lost to red (mean)      : %8.1f\n', mean(lost));
fprintf('Convoys destroyed (mean)     : %8.2f\n', mean(kills));
fprintf('Min FOB stock (mean)         : %8.1f tons\n', mean(minStock));
fprintf('P(FOB goes dry)              : %8.1f%%\n', 100*mean(dryHours > 0));

%% Plots — fixed colorblind-safe palette (Okabe-Ito)
colBlue  = [0.000 0.447 0.698];   % blue force / primary series
colRed   = [0.835 0.369 0.000];   % red force effects / losses
colGray  = [0.55 0.55 0.55];      % individual realizations (context)

fig = figure('Name', 'Operation IRON RELAY — campaign results', ...
    'Color', 'w', 'Position', [80 80 1100 700]);
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('Operation IRON RELAY — %d-day contested resupply, %d realizations', ...
    round(campaignHr/24), nRuns));

% (1) FOB stockpile trajectories: all runs as context, median emphasized
ax1 = nexttile(tl, [1 2]);
hold(ax1, 'on');
plot(ax1, tGrid/24, stockGrid', 'Color', [colGray 0.25], 'LineWidth', 0.5);
plot(ax1, tGrid/24, median(stockGrid, 1), 'Color', colBlue, 'LineWidth', 2);
yline(ax1, 0, '--', 'FOB dry', 'Color', colRed, 'LineWidth', 1, ...
    'LabelHorizontalAlignment', 'left');
grid(ax1, 'on'); ax1.GridAlpha = 0.15;
xlabel(ax1, 'Campaign day');
ylabel(ax1, 'FOB stockpile (tons)');
title(ax1, 'FOB stockpile — every realization (gray), median (blue)');
hold(ax1, 'off');

% (2) Distribution of delivered tonnage
ax2 = nexttile(tl);
histogram(ax2, delivered, 'FaceColor', colBlue, 'EdgeColor', 'w', 'LineWidth', 1);
xline(ax2, dispatchedTons, '--', 'Dispatched', 'Color', colGray, 'LineWidth', 1);
grid(ax2, 'on'); ax2.GridAlpha = 0.15;
xlabel(ax2, 'Tons delivered per campaign');
ylabel(ax2, 'Realizations');
title(ax2, 'Delivered tonnage distribution');

% (3) Attrition: tons lost per campaign
ax3 = nexttile(tl);
histogram(ax3, lost, 'FaceColor', colRed, 'EdgeColor', 'w', 'LineWidth', 1);
grid(ax3, 'on'); ax3.GridAlpha = 0.15;
xlabel(ax3, 'Tons lost to interdiction per campaign');
ylabel(ax3, 'Realizations');
title(ax3, 'Red interdiction attrition');

end
