classdef MissionPlannerApp < handle
    %MISSIONPLANNERAPP Interactive UI for the outer-loop mission planner.

    properties (Access = private)
        UIFigure
        StrategyDropDown
        RunsSpinner
        IterationsSpinner
        MutationRateField
        RestartRateField
        DryWeightField
        LostWeightField
        KillsWeightField
        DeliveryRewardField
        StatusLabel
        ScenarioTextArea
        EvaluateButton
        OptimizeButton
        MetricValueLabels cell = cell(1, 6)
        MetricDetailLabels cell = cell(1, 6)
        RouteAxes
        StockAxes
        OutcomeAxes
        SearchAxes
        LastEvaluation struct = struct([])
        LastOptimizer struct = struct([])
    end

    methods
        function app = MissionPlannerApp()
            app.createComponents();
            app.loadScenarioSnapshot();
            app.renderEmptyState();
        end
    end

    methods (Access = private)
        function createComponents(app)
            theme = plannerPalette();

            app.UIFigure = uifigure( ...
                'Name', 'Operation IRON RELAY - Mission Planner', ...
                'Color', theme.FigureBg, ...
                'Position', [90 70 1540 920]);

            mainGrid = uigridlayout(app.UIFigure, [3 2]);
            mainGrid.RowHeight = {132, '1x', '1x'};
            mainGrid.ColumnWidth = {340, '1x'};
            mainGrid.Padding = [16 16 16 16];
            mainGrid.RowSpacing = 14;
            mainGrid.ColumnSpacing = 14;

            controlPanel = uipanel(mainGrid, ...
                'Title', 'Planner Controls', ...
                'BackgroundColor', theme.PanelBg, ...
                'ForegroundColor', theme.TextPrimary, ...
                'FontWeight', 'bold');
            controlPanel.Layout.Row = [1 3];
            controlPanel.Layout.Column = 1;

            controlGrid = uigridlayout(controlPanel, [18 1]);
            controlGrid.RowHeight = {30, 22, 32, 22, 32, 22, 32, 22, 32, 22, 32, 22, 32, 22, 32, '1x', 74, 44};
            controlGrid.Padding = [12 12 12 12];
            controlGrid.RowSpacing = 6;
            controlGrid.BackgroundColor = theme.PanelBg;

            titleLabel = uilabel(controlGrid, ...
                'Text', 'Operation IRON RELAY Planner', ...
                'FontSize', 24, ...
                'FontWeight', 'bold', ...
                'FontName', 'Bahnschrift');
            titleLabel.FontColor = theme.TextPrimary;

            uilabel(controlGrid, 'Text', 'Baseline strategy', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            app.StrategyDropDown = uidropdown(controlGrid, ...
                'Items', {'roundrobin', 'north', 'south', 'split'}, ...
                'Value', 'roundrobin', ...
                'BackgroundColor', theme.ControlBg, ...
                'FontColor', theme.TextPrimary);

            uilabel(controlGrid, 'Text', 'Monte Carlo runs', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            app.RunsSpinner = uispinner(controlGrid, ...
                'Limits', [1 30], 'Value', 3, 'Step', 1, ...
                'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);

            uilabel(controlGrid, 'Text', 'Optimization iterations', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            app.IterationsSpinner = uispinner(controlGrid, ...
                'Limits', [1 200], 'Value', 20, 'Step', 1, ...
                'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);

            uilabel(controlGrid, 'Text', 'Mutation / restart', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            mutationGrid = uigridlayout(controlGrid, [1 2]);
            mutationGrid.ColumnWidth = {'1x', '1x'};
            mutationGrid.Padding = [0 0 0 0];
            mutationGrid.ColumnSpacing = 8;
            mutationGrid.BackgroundColor = theme.PanelBg;
            app.MutationRateField = uieditfield(mutationGrid, 'numeric', ...
                'Limits', [0.01 1], 'Value', 0.12, ...
                'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);
            app.RestartRateField = uieditfield(mutationGrid, 'numeric', ...
                'Limits', [0 1], 'Value', 0.15, ...
                'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);

            uilabel(controlGrid, 'Text', 'Dry / lost weights', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            costGrid1 = uigridlayout(controlGrid, [1 2]);
            costGrid1.ColumnWidth = {'1x', '1x'};
            costGrid1.Padding = [0 0 0 0];
            costGrid1.ColumnSpacing = 8;
            costGrid1.BackgroundColor = theme.PanelBg;
            app.DryWeightField = uieditfield(costGrid1, 'numeric', ...
                'Value', 5.0, 'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);
            app.LostWeightField = uieditfield(costGrid1, 'numeric', ...
                'Value', 0.03, 'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);

            uilabel(controlGrid, 'Text', 'Kills / delivery reward', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            costGrid2 = uigridlayout(controlGrid, [1 2]);
            costGrid2.ColumnWidth = {'1x', '1x'};
            costGrid2.Padding = [0 0 0 0];
            costGrid2.ColumnSpacing = 8;
            costGrid2.BackgroundColor = theme.PanelBg;
            app.KillsWeightField = uieditfield(costGrid2, 'numeric', ...
                'Value', 12.0, 'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);
            app.DeliveryRewardField = uieditfield(costGrid2, 'numeric', ...
                'Value', 0.01, 'BackgroundColor', theme.ControlBg, 'FontColor', theme.TextPrimary);

            uilabel(controlGrid, 'Text', 'Scenario snapshot', ...
                'FontWeight', 'bold', 'FontColor', theme.TextMuted);
            app.ScenarioTextArea = uitextarea(controlGrid, ...
                'Editable', 'off', ...
                'BackgroundColor', theme.ControlBg, ...
                'FontColor', theme.TextPrimary, ...
                'FontName', 'Consolas', ...
                'Value', {'Loading scenario parameters...'});

            buttonGrid = uigridlayout(controlGrid, [1 2]);
            buttonGrid.ColumnWidth = {'1x', '1x'};
            buttonGrid.Padding = [0 0 0 0];
            buttonGrid.ColumnSpacing = 8;
            buttonGrid.BackgroundColor = theme.PanelBg;
            app.EvaluateButton = uibutton(buttonGrid, 'push', ...
                'Text', 'Evaluate Plan', ...
                'ButtonPushedFcn', @(~, ~) app.evaluateCurrentPlan());
            stylePlannerButton(app.EvaluateButton, theme.AccentBlue);
            app.OptimizeButton = uibutton(buttonGrid, 'push', ...
                'Text', 'Optimize Plan', ...
                'ButtonPushedFcn', @(~, ~) app.optimizePlan());
            stylePlannerButton(app.OptimizeButton, theme.AccentGreen);

            app.StatusLabel = uilabel(controlGrid, ...
                'Text', 'Ready. Evaluate a baseline plan or run the optimizer.', ...
                'WordWrap', 'on', ...
                'FontColor', theme.TextMuted, ...
                'FontAngle', 'italic');

            summaryGrid = uigridlayout(mainGrid, [2 3]);
            summaryGrid.Layout.Row = 1;
            summaryGrid.Layout.Column = 2;
            summaryGrid.RowHeight = {'1x', '1x'};
            summaryGrid.ColumnWidth = {'1x', '1x', '1x'};
            summaryGrid.RowSpacing = 12;
            summaryGrid.ColumnSpacing = 12;
            summaryGrid.Padding = [0 0 0 0];
            summaryGrid.BackgroundColor = theme.FigureBg;

            cardTitles = {'Cost', 'Throughput', 'Delivered', 'Losses', 'Dry Hours', 'North Share'};
            for idx = 1:numel(cardTitles)
                card = uipanel(summaryGrid, ...
                    'BackgroundColor', theme.CardBg, ...
                    'ForegroundColor', theme.Edge, ...
                    'HighlightColor', theme.Edge, ...
                    'BorderType', 'line');
                cardGrid = uigridlayout(card, [3 1]);
                cardGrid.RowHeight = {22, '1x', 24};
                cardGrid.Padding = [12 10 12 10];
                cardGrid.RowSpacing = 2;
                cardGrid.BackgroundColor = theme.CardBg;

                uilabel(cardGrid, ...
                    'Text', upper(cardTitles{idx}), ...
                    'FontSize', 11, ...
                    'FontWeight', 'bold', ...
                    'FontColor', theme.TextMuted);
                app.MetricValueLabels{idx} = uilabel(cardGrid, ...
                    'Text', '--', ...
                    'FontSize', 24, ...
                    'FontName', 'Bahnschrift', ...
                    'FontWeight', 'bold', ...
                    'FontColor', theme.TextPrimary);
                app.MetricDetailLabels{idx} = uilabel(cardGrid, ...
                    'Text', '', ...
                    'FontSize', 11, ...
                    'FontColor', theme.TextSubtle);
            end

            vizGrid = uigridlayout(mainGrid, [2 2]);
            vizGrid.Layout.Row = [2 3];
            vizGrid.Layout.Column = 2;
            vizGrid.RowHeight = {'1x', '1x'};
            vizGrid.ColumnWidth = {'1x', '1x'};
            vizGrid.RowSpacing = 12;
            vizGrid.ColumnSpacing = 12;
            vizGrid.Padding = [0 0 0 0];
            vizGrid.BackgroundColor = theme.FigureBg;

            app.RouteAxes = uiaxes(vizGrid);
            app.RouteAxes.Layout.Row = 1;
            app.RouteAxes.Layout.Column = 1;

            app.StockAxes = uiaxes(vizGrid);
            app.StockAxes.Layout.Row = 1;
            app.StockAxes.Layout.Column = 2;

            app.OutcomeAxes = uiaxes(vizGrid);
            app.OutcomeAxes.Layout.Row = 2;
            app.OutcomeAxes.Layout.Column = 1;

            app.SearchAxes = uiaxes(vizGrid);
            app.SearchAxes.Layout.Row = 2;
            app.SearchAxes.Layout.Column = 2;

            formatPlannerAxes(app.RouteAxes);
            formatPlannerAxes(app.StockAxes);
            formatPlannerAxes(app.OutcomeAxes);
            formatPlannerAxes(app.SearchAxes);
        end

        function loadScenarioSnapshot(app)
            evalin('base', 'scenarioParams');
            campaignDays = evalin('base', 'CAMPAIGN_HR / 24');
            dispatchPeriodHr = evalin('base', 'DISPATCH_PERIOD_HR');
            convoyTons = evalin('base', 'CONVOY_CARGO_TONS');
            stockInitial = evalin('base', 'FOB_STOCK_INITIAL_TONS');
            pNorth = evalin('base', 'P_AMBUSH_NORTH');
            pSouth = evalin('base', 'P_AMBUSH_SOUTH');

            app.ScenarioTextArea.Value = { ...
                sprintf('Campaign length   : %.0f days', campaignDays), ...
                sprintf('Dispatch rhythm   : 1 convoy / %d h', dispatchPeriodHr), ...
                sprintf('Convoy payload    : %.0f tons', convoyTons), ...
                sprintf('Initial FOB stock : %.0f tons', stockInitial), ...
                sprintf('North ambush base : %.0f%%', 100 * pNorth), ...
                sprintf('South ambush base : %.0f%%', 100 * pSouth)};
        end

        function renderEmptyState(app)
            app.updateMetricCards({'--','--','--','--','--','--'}, ...
                {'Awaiting planner run','','','','',''});
            plannerPlaceholder(app.RouteAxes, 'Route sequence appears here.');
            plannerPlaceholder(app.StockAxes, 'Stockpile outcomes appear here.');
            plannerPlaceholder(app.OutcomeAxes, 'Delivery/loss tradeoffs appear here.');
            plannerPlaceholder(app.SearchAxes, 'Optimization history appears here.');
        end

        function evaluateCurrentPlan(app)
            opts = app.collectEvaluationOptions();
            app.setBusyState(true, 'Evaluating baseline route plan...');
            cleanup = onCleanup(@() app.setControlsEnabled(true));

            try
                plan = defaultMissionPlan(string(app.StrategyDropDown.Value));
                evaluation = evaluateMissionPlan(plan, ...
                    Runs=opts.Runs, ...
                    DryHoursWeight=opts.DryHoursWeight, ...
                    LostTonsWeight=opts.LostTonsWeight, ...
                    KillsWeight=opts.KillsWeight, ...
                    DeliveryReward=opts.DeliveryReward);
                app.LastEvaluation = evaluation;
                app.LastOptimizer = struct([]);
                app.renderEvaluation(evaluation, plan.Name, []);
                app.StatusLabel.Text = sprintf( ...
                    'Baseline plan "%s" evaluated across %d runs. Mean cost %.2f.', ...
                    plan.Name, opts.Runs, evaluation.Mean.Cost);
            catch ME
                app.StatusLabel.Text = 'Baseline evaluation failed.';
                uialert(app.UIFigure, ME.message, 'Planner Error');
            end

            clear cleanup
        end

        function optimizePlan(app)
            opts = app.collectEvaluationOptions();
            app.setBusyState(true, sprintf('Optimizing route plan across %d iterations...', opts.Iterations));
            cleanup = onCleanup(@() app.setControlsEnabled(true));

            try
                optimizer = optimizeMissionPlan(opts.Iterations, ...
                    RunsPerCandidate=opts.Runs, ...
                    MutationRate=opts.MutationRate, ...
                    RandomRestartProbability=opts.RestartRate, ...
                    DryHoursWeight=opts.DryHoursWeight, ...
                    LostTonsWeight=opts.LostTonsWeight, ...
                    KillsWeight=opts.KillsWeight, ...
                    DeliveryReward=opts.DeliveryReward);
                app.LastOptimizer = optimizer;
                app.LastEvaluation = optimizer.BestEvaluation;
                app.renderEvaluation(optimizer.BestEvaluation, 'optimized', optimizer.History);
                app.StatusLabel.Text = sprintf( ...
                    'Optimization complete. Best mean cost %.2f after %d iterations.', ...
                    optimizer.BestEvaluation.Mean.Cost, opts.Iterations);
            catch ME
                app.StatusLabel.Text = 'Optimization failed.';
                uialert(app.UIFigure, ME.message, 'Planner Error');
            end

            clear cleanup
        end

        function opts = collectEvaluationOptions(app)
            opts = struct( ...
                'Runs', round(app.RunsSpinner.Value), ...
                'Iterations', round(app.IterationsSpinner.Value), ...
                'MutationRate', app.MutationRateField.Value, ...
                'RestartRate', app.RestartRateField.Value, ...
                'DryHoursWeight', app.DryWeightField.Value, ...
                'LostTonsWeight', app.LostWeightField.Value, ...
                'KillsWeight', app.KillsWeightField.Value, ...
                'DeliveryReward', app.DeliveryRewardField.Value);
        end

        function renderEvaluation(app, evaluation, label, history)
            app.updateMetricCards( ...
                {sprintf('%.2f', evaluation.Mean.Cost), ...
                sprintf('%.1f%%', evaluation.Mean.ThroughputPct), ...
                sprintf('%.0f t', evaluation.Mean.DeliveredTons), ...
                sprintf('%.0f t', evaluation.Mean.LostTons), ...
                sprintf('%.1f h', evaluation.Mean.DryHours), ...
                sprintf('%.1f%%', evaluation.Mean.NorthSharePct)}, ...
                {sprintf('%s plan', label), ...
                sprintf('dispatch %.0f t', evaluation.DispatchedTons), ...
                sprintf('min stock %.0f t', evaluation.Mean.MinStockTons), ...
                'mean tons lost to interdiction', ...
                'mean time at or below zero stock', ...
                'mean convoy share routed north'});

            app.drawRoutePlan(evaluation.RouteSequence, evaluation.DispatchPeriodHr);
            app.drawStockOutcomes(evaluation);
            app.drawOutcomeScatter(evaluation);
            app.drawSearchHistory(history, evaluation);
        end

        function updateMetricCards(app, values, details)
            for idx = 1:numel(app.MetricValueLabels)
                app.MetricValueLabels{idx}.Text = values{idx};
                app.MetricDetailLabels{idx}.Text = details{idx};
            end
        end

        function drawRoutePlan(app, routeSequence, dispatchPeriodHr)
            ax = app.RouteAxes;
            cla(ax);
            formatPlannerAxes(ax);
            days = (0:numel(routeSequence)-1) * dispatchPeriodHr / 24;
            stairs(ax, days, routeSequence, 'Color', [0.29 0.82 0.66], 'LineWidth', 2.2);
            ax.YTick = [1 2];
            ax.YTickLabel = {'North', 'South'};
            ax.YLim = [0.75 2.25];
            title(ax, 'Route Assignment Timeline', 'FontWeight', 'bold');
            xlabel(ax, 'Campaign day');
            ylabel(ax, 'Selected route');
        end

        function drawStockOutcomes(app, evaluation)
            ax = app.StockAxes;
            cla(ax);
            formatPlannerAxes(ax);
            hold(ax, 'on');
            plot(ax, evaluation.tGrid / 24, evaluation.StockGrid', ...
                'Color', [0.36 0.40 0.46], 'LineWidth', 0.7);
            plot(ax, evaluation.tGrid / 24, mean(evaluation.StockGrid, 1), ...
                'Color', [0.41 0.71 0.98], 'LineWidth', 2.4);
            yline(ax, 0, '--', 'FOB dry', 'Color', [0.93 0.44 0.34], 'LineWidth', 1.1);
            title(ax, 'Stockpile Outcomes', 'FontWeight', 'bold');
            xlabel(ax, 'Campaign day');
            ylabel(ax, 'FOB stockpile (tons)');
            hold(ax, 'off');
        end

        function drawOutcomeScatter(app, evaluation)
            ax = app.OutcomeAxes;
            cla(ax);
            formatPlannerAxes(ax);
            dryMask = evaluation.PerRun.DryHours > 0;
            scatter(ax, evaluation.PerRun.DeliveredTons(~dryMask), evaluation.PerRun.LostTons(~dryMask), ...
                42, [0.24 0.30 0.38], 'filled', 'MarkerEdgeColor', [0.47 0.77 1.00], 'LineWidth', 0.8);
            hold(ax, 'on');
            scatter(ax, evaluation.PerRun.DeliveredTons(dryMask), evaluation.PerRun.LostTons(dryMask), ...
                52, [0.80 0.31 0.24], 'filled', 'MarkerEdgeColor', [0.98 0.62 0.56], 'LineWidth', 0.8);
            title(ax, 'Run Outcome Cloud', 'FontWeight', 'bold');
            xlabel(ax, 'Delivered tons');
            ylabel(ax, 'Lost tons');
            legend(ax, {'Sustained FOB', 'FOB went dry'}, 'Location', 'northwest', ...
                'Color', [0.10 0.12 0.16], 'TextColor', [0.92 0.95 0.98]);
            hold(ax, 'off');
        end

        function drawSearchHistory(app, history, evaluation)
            ax = app.SearchAxes;
            cla(ax);
            formatPlannerAxes(ax);
            if isempty(history)
                histogram(ax, evaluation.PerRun.NorthSharePct, ...
                    'FaceColor', [0.41 0.71 0.98], ...
                    'EdgeColor', [0.10 0.12 0.16], ...
                    'LineWidth', 1);
                title(ax, 'North-Share Distribution', 'FontWeight', 'bold');
                xlabel(ax, 'North share (%)');
                ylabel(ax, 'Runs');
                return
            end

            plot(ax, 1:height(history), history.MeanCost, '-o', ...
                'Color', [0.41 0.71 0.98], ...
                'MarkerFaceColor', [0.41 0.71 0.98], ...
                'MarkerSize', 4);
            title(ax, 'Optimization History', 'FontWeight', 'bold');
            xlabel(ax, 'Candidate evaluation');
            ylabel(ax, 'Mean cost');
        end

        function setBusyState(app, isBusy, message)
            app.setControlsEnabled(~isBusy);
            app.StatusLabel.Text = message;
            drawnow;
        end

        function setControlsEnabled(app, isEnabled)
            if isEnabled
                enableState = 'on';
                editableState = 'on';
            else
                enableState = 'off';
                editableState = 'off';
            end

            app.EvaluateButton.Enable = enableState;
            app.OptimizeButton.Enable = enableState;
            app.StrategyDropDown.Enable = enableState;
            app.RunsSpinner.Enable = enableState;
            app.IterationsSpinner.Enable = enableState;
            app.MutationRateField.Editable = editableState;
            app.RestartRateField.Editable = editableState;
            app.DryWeightField.Editable = editableState;
            app.LostWeightField.Editable = editableState;
            app.KillsWeightField.Editable = editableState;
            app.DeliveryRewardField.Editable = editableState;
        end
    end
end

function stylePlannerButton(button, colorValue)
button.BackgroundColor = colorValue;
button.FontColor = [1 1 1];
button.FontWeight = 'bold';
end

function formatPlannerAxes(ax)
theme = plannerPalette();
ax.Box = 'on';
ax.LineWidth = 1;
ax.Color = theme.AxesBg;
ax.XColor = theme.TextMuted;
ax.YColor = theme.TextMuted;
ax.GridColor = theme.Grid;
ax.MinorGridColor = theme.Grid;
ax.FontName = 'Aptos';
ax.Toolbar.Visible = 'off';
ax.Title.Color = theme.TextPrimary;
ax.XLabel.Color = theme.TextMuted;
ax.YLabel.Color = theme.TextMuted;
grid(ax, 'on');
ax.GridAlpha = 0.12;
end

function plannerPlaceholder(ax, message)
theme = plannerPalette();
cla(ax);
ax.Visible = 'on';
ax.Color = theme.AxesBg;
ax.XTick = [];
ax.YTick = [];
ax.XColor = 'none';
ax.YColor = 'none';
text(ax, 0.5, 0.5, message, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 13, ...
    'Color', theme.TextMuted);
end

function theme = plannerPalette()
theme = struct( ...
    'FigureBg', [0.08 0.10 0.13], ...
    'PanelBg', [0.11 0.13 0.17], ...
    'CardBg', [0.12 0.15 0.19], ...
    'ControlBg', [0.14 0.17 0.22], ...
    'AxesBg', [0.10 0.12 0.16], ...
    'TextPrimary', [0.92 0.95 0.98], ...
    'TextMuted', [0.68 0.74 0.80], ...
    'TextSubtle', [0.58 0.64 0.71], ...
    'Edge', [0.22 0.27 0.33], ...
    'Grid', [0.27 0.32 0.39], ...
    'AccentBlue', [0.24 0.49 0.78], ...
    'AccentGreen', [0.18 0.55 0.44]);
end
