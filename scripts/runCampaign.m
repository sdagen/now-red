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

fprintf('Running %d campaign realizations...\n', nRuns);
results = analyzeCampaign(nRuns, DisplaySummary=true, MakePlots=true);
end
