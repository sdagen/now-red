function plan = defaultMissionPlan(strategy, options)
%DEFAULTMISSIONPLAN Create a baseline route plan for LogisticsMissionPlanEval.

arguments
    strategy (1,1) string = "roundrobin"
    options.CampaignHr (1,1) double = NaN
    options.DispatchPeriodHr (1,1) double = NaN
end

if isnan(options.CampaignHr) || isnan(options.DispatchPeriodHr)
    evalin('base', 'scenarioParams');
end

campaignHr = options.CampaignHr;
dispatchPeriodHr = options.DispatchPeriodHr;

if isnan(campaignHr)
    campaignHr = evalin('base', 'CAMPAIGN_HR');
end

if isnan(dispatchPeriodHr)
    dispatchPeriodHr = evalin('base', 'DISPATCH_PERIOD_HR');
end

nConvoys = floor(campaignHr / dispatchPeriodHr) + 1;
routeSequence = ones(nConvoys, 1);

switch lower(strategy)
    case "north"
        routeSequence(:) = 1;
    case "south"
        routeSequence(:) = 2;
    case "roundrobin"
        routeSequence(2:2:end) = 2;
    case "split"
        routeSequence(ceil(nConvoys/2)+1:end) = 2;
    otherwise
        error('Unsupported default strategy "%s".', strategy);
end

plan = struct( ...
    'Name', char(strategy), ...
    'RouteSequence', routeSequence, ...
    'DispatchTimesHr', (0:nConvoys-1)' * dispatchPeriodHr);
end
