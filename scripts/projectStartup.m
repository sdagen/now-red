%% projectStartup.m — Operation IRON RELAY project startup
% Loads the scenario parameters (including the ConvoyBus entity type) into
% the base workspace so LogisticsMission.slx is immediately simulable.
scenarioParams;
fprintf('Operation IRON RELAY loaded: %d-day campaign, dispatch every %d h.\n', ...
    CAMPAIGN_HR/24, DISPATCH_PERIOD_HR);
