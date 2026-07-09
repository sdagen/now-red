%% scenarioParams.m
% Scenario definition: Operation IRON RELAY — contested logistics resupply.
%
% Blue force sustains a forward operating base (FOB) by dispatching truck
% convoys from a logistics support area (LSA) over two ground routes. Red
% force interdiction cells on each route ambush convoys with a probability
% that depends on the cell's posture (dormant / active / surge).
%
% Time base: 1 simulation time unit = 1 hour.
%
% Run this script before simulating LogisticsMission.slx.

%% Campaign
CAMPAIGN_HR = 720;                 % 30-day campaign duration

%% Blue force — convoy dispatch (LSA)
DISPATCH_PERIOD_HR  = 8;           % one convoy every 8 hours
TRUCKS_PER_CONVOY   = 20;
TONS_PER_TRUCK      = 5;
CONVOY_CARGO_TONS   = TRUCKS_PER_CONVOY * TONS_PER_TRUCK;
MAX_CONVOYS_EN_ROUTE = 25;         % transit server capacity per route

%% Routes
TRANSIT_NORTH_HR = 6;              % short route, higher threat
TRANSIT_SOUTH_HR = 10;             % long route, lower threat

%% Blue force — FOB sustainment
FOB_STOCK_INITIAL_TONS  = 400;
FOB_CONSUMPTION_TPD     = 200;                      % tons per day
FOB_CONSUMPTION_TPH     = FOB_CONSUMPTION_TPD / 24; % tons per hour

%% Red force — interdiction cells
% Ambush probability per convoy transit while the cell is ACTIVE.
% DORMANT and SURGE postures scale this baseline.
P_AMBUSH_NORTH = 0.35;
P_AMBUSH_SOUTH = 0.12;
DORMANT_FACTOR = 0.25;             % posture multiplier when dormant
SURGE_FACTOR   = 2.0;              % posture multiplier when surging

% Posture cycle durations (hours) — north cell runs a faster, more
% aggressive cycle than the south cell.
T_DORMANT_NORTH_HR = 72;
T_ACTIVE_NORTH_HR  = 96;
T_SURGE_NORTH_HR   = 48;
T_DORMANT_SOUTH_HR = 120;
T_ACTIVE_SOUTH_HR  = 96;
T_SURGE_SOUTH_HR   = 24;

% Attrition per successful ambush: fraction of trucks destroyed is drawn
% uniformly from [LOSS_FRAC_MIN, LOSS_FRAC_MAX]. A complex ambush
% (probability P_CATASTROPHIC_KILL, given an ambush occurs) destroys the
% entire convoy.
LOSS_FRAC_MIN = 0.10;
LOSS_FRAC_MAX = 0.50;
P_CATASTROPHIC_KILL = 0.08;

%% Monte Carlo control
% Seeds for the red cells' internal random number generators. Vary these
% per run to get independent campaign realizations.
RUN_SEED_NORTH = 1;
RUN_SEED_SOUTH = 2;

%% Entity type: convoy payload carried through the SimEvents network
convoyElems(1) = Simulink.BusElement;
convoyElems(1).Name = 'Trucks';
convoyElems(2) = Simulink.BusElement;
convoyElems(2).Name = 'CargoTons';
ConvoyBus = Simulink.Bus;
ConvoyBus.Elements = convoyElems;
clear convoyElems

% Initial payload of every convoy entity at dispatch
CONVOY_INIT = struct('Trucks', TRUCKS_PER_CONVOY, 'CargoTons', CONVOY_CARGO_TONS);
