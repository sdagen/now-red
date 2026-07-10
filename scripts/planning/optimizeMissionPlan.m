function optimizer = optimizeMissionPlan(nIterations, options)
%OPTIMIZEMISSIONPLAN Search for a lower-cost external route plan.

arguments
    nIterations (1,1) double {mustBeInteger, mustBePositive} = 40
    options.RunsPerCandidate (1,1) double {mustBeInteger, mustBePositive} = 3
    options.MutationRate (1,1) double {mustBeGreaterThan(options.MutationRate, 0), mustBeLessThanOrEqual(options.MutationRate, 1)} = 0.12
    options.RandomRestartProbability (1,1) double {mustBeGreaterThanOrEqual(options.RandomRestartProbability, 0), mustBeLessThanOrEqual(options.RandomRestartProbability, 1)} = 0.15
    options.RngSeed (1,1) double = 7
end

evalin('base', 'scenarioParams');
campaignHr = evalin('base', 'CAMPAIGN_HR');
dispatchPeriodHr = evalin('base', 'DISPATCH_PERIOD_HR');

rng(options.RngSeed, 'twister');

seedPlans = [ ...
    defaultMissionPlan("north", CampaignHr=campaignHr, DispatchPeriodHr=dispatchPeriodHr), ...
    defaultMissionPlan("south", CampaignHr=campaignHr, DispatchPeriodHr=dispatchPeriodHr), ...
    defaultMissionPlan("roundrobin", CampaignHr=campaignHr, DispatchPeriodHr=dispatchPeriodHr)];

historyRows = repmat(struct( ...
    'Iteration', 0, ...
    'Source', "", ...
    'MeanCost', 0, ...
    'MeanDeliveredTons', 0, ...
    'MeanLostTons', 0, ...
    'MeanDryHours', 0, ...
    'MeanNorthSharePct', 0), nIterations + numel(seedPlans), 1);

bestEvaluation = [];
row = 0;

for idx = 1:numel(seedPlans)
    evaluation = evaluateMissionPlan(seedPlans(idx), Runs=options.RunsPerCandidate);
    row = row + 1;
    historyRows(row) = makeHistoryRow(row - numel(seedPlans), "seed:" + string(seedPlans(idx).Name), evaluation);
    if isempty(bestEvaluation) || evaluation.Mean.Cost < bestEvaluation.Mean.Cost
        bestEvaluation = evaluation;
    end
end

for iter = 1:nIterations
    candidateSequence = bestEvaluation.RouteSequence;

    if rand < options.RandomRestartProbability
        candidateSequence = randi([1 2], size(candidateSequence));
        source = "restart";
    else
        flipMask = rand(size(candidateSequence)) < options.MutationRate;
        if ~any(flipMask)
            flipMask(randi(numel(candidateSequence))) = true;
        end
        candidateSequence(flipMask) = 3 - candidateSequence(flipMask);
        source = "mutate";
    end

    candidate = struct('Name', sprintf('iter_%03d', iter), 'RouteSequence', candidateSequence);
    evaluation = evaluateMissionPlan(candidate, Runs=options.RunsPerCandidate);
    row = row + 1;
    historyRows(row) = makeHistoryRow(iter, source, evaluation);

    if evaluation.Mean.Cost < bestEvaluation.Mean.Cost
        bestEvaluation = evaluation;
    end
end

history = struct2table(historyRows(1:row));
optimizer = struct( ...
    'BestPlan', struct('RouteSequence', bestEvaluation.RouteSequence), ...
    'BestEvaluation', bestEvaluation, ...
    'History', history, ...
    'Options', options);
end

function row = makeHistoryRow(iteration, source, evaluation)
row = struct( ...
    'Iteration', iteration, ...
    'Source', string(source), ...
    'MeanCost', evaluation.Mean.Cost, ...
    'MeanDeliveredTons', evaluation.Mean.DeliveredTons, ...
    'MeanLostTons', evaluation.Mean.LostTons, ...
    'MeanDryHours', evaluation.Mean.DryHours, ...
    'MeanNorthSharePct', evaluation.Mean.NorthSharePct);
end
