function results = evaluateMissionPlan(plan, options)
%EVALUATEMISSIONPLAN Simulate an externally planned route sequence.

arguments
    plan
    options.Model (1,1) string = "LogisticsMissionPlanEval"
    options.Runs (1,1) double {mustBeInteger, mustBePositive} = 1
    options.SeedNorthBase (1,1) double = 1000
    options.SeedSouthBase (1,1) double = 2000
    options.DryHoursWeight (1,1) double = 5.0
    options.LostTonsWeight (1,1) double = 0.03
    options.KillsWeight (1,1) double = 12.0
    options.DeliveryReward (1,1) double = 0.01
end

evalin('base', 'scenarioParams');

campaignHr = evalin('base', 'CAMPAIGN_HR');
dispatchPeriodHr = evalin('base', 'DISPATCH_PERIOD_HR');
convoyCargoTons = evalin('base', 'CONVOY_CARGO_TONS');
dispatchedTons = (floor(campaignHr / dispatchPeriodHr) + 1) * convoyCargoTons;
tGrid = (0:campaignHr)';
expectedConvoys = floor(campaignHr / dispatchPeriodHr) + 1;
routeSequence = normalizePlan(plan, campaignHr, dispatchPeriodHr);
routeSequence = buildRoutePlanSequence(routeSequence, ExpectedConvoys=expectedConvoys);

model = char(options.Model);
load_system(model);

simIn(1:options.Runs) = Simulink.SimulationInput(model);
for idx = 1:options.Runs
    simIn(idx) = simIn(idx).setVariable('ROUTE_PLAN_SEQUENCE', routeSequence);
    simIn(idx) = simIn(idx).setVariable('RUN_SEED_NORTH', options.SeedNorthBase + 2 * idx);
    simIn(idx) = simIn(idx).setVariable('RUN_SEED_SOUTH', options.SeedSouthBase + 2 * idx + 1);
end

simOut = sim(simIn);

delivered = zeros(options.Runs, 1);
lost = zeros(options.Runs, 1);
kills = zeros(options.Runs, 1);
minStock = zeros(options.Runs, 1);
dryHours = zeros(options.Runs, 1);
northSharePct = zeros(options.Runs, 1);
stockGrid = zeros(options.Runs, numel(tGrid));
routeHistory = cell(options.Runs, 1);

for idx = 1:options.Runs
    stockTs = simOut(idx).fobStock;
    stockGrid(idx, :) = interp1(stockTs.Time, stockTs.Data, tGrid, 'previous', 'extrap');
    minStock(idx) = min(stockGrid(idx, :));
    dryHours(idx) = nnz(stockGrid(idx, :) <= 0);

    delivered(idx) = simOut(idx).deliveredTons.Data(end);
    lost(idx) = simOut(idx).lostTons.Data(end);
    kills(idx) = simOut(idx).convoysKilled.Data(end);

    routeValues = simOut(idx).routeSelected.Data(:);
    routeValues = routeValues(~isnan(routeValues));
    northSharePct(idx) = 100 * nnz(routeValues == 1) / max(numel(routeValues), 1);
    routeHistory{idx} = routeValues;
end

cost = options.DryHoursWeight * dryHours ...
    + options.LostTonsWeight * lost ...
    + options.KillsWeight * kills ...
    - options.DeliveryReward * delivered;

results = struct( ...
    'Model', model, ...
    'RouteSequence', routeSequence, ...
    'DispatchPeriodHr', dispatchPeriodHr, ...
    'DispatchedTons', dispatchedTons, ...
    'tGrid', tGrid, ...
    'StockGrid', stockGrid, ...
    'PerRun', table(delivered, lost, kills, minStock, dryHours, northSharePct, cost, ...
        'VariableNames', {'DeliveredTons', 'LostTons', 'Kills', 'MinStockTons', 'DryHours', 'NorthSharePct', 'Cost'}), ...
    'Mean', struct( ...
        'DeliveredTons', mean(delivered), ...
        'LostTons', mean(lost), ...
        'Kills', mean(kills), ...
        'MinStockTons', mean(minStock), ...
        'DryHours', mean(dryHours), ...
        'NorthSharePct', mean(northSharePct), ...
        'ThroughputPct', 100 * mean(delivered) / dispatchedTons, ...
        'Cost', mean(cost)), ...
    'RouteHistory', {routeHistory});
end

function routeSequence = normalizePlan(plan, campaignHr, dispatchPeriodHr)
expectedConvoys = floor(campaignHr / dispatchPeriodHr) + 1;

if isnumeric(plan)
    routeSequence = plan(:);
elseif isstruct(plan) && isfield(plan, 'RouteSequence')
    routeSequence = plan.RouteSequence(:);
else
    error('Plan must be a numeric route vector or a struct with RouteSequence.');
end

if numel(routeSequence) ~= expectedConvoys
    error('Route plan must contain %d convoy decisions, found %d.', ...
        expectedConvoys, numel(routeSequence));
end
end
