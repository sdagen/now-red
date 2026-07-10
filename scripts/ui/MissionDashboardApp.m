classdef MissionDashboardApp < handle
    %MISSIONDASHBOARDAPP Interactive UI for the Operation IRON RELAY simulator.

    properties (Access = private)
        UIFigure
        RunsSpinner
        StatusLabel
        ScenarioTextArea
        SingleRunButton
        CampaignButton
        MetricTitleLabels cell = cell(1, 6)
        MetricValueLabels cell = cell(1, 6)
        MetricDetailLabels cell = cell(1, 6)
        TheaterAxes
        StockAxes
        OutcomeAxes
        RouteAxes
    end

    methods
        function app = MissionDashboardApp()
            app.createComponents();
            app.loadScenarioSnapshot();
            app.renderEmptyState();
        end
    end

    methods (Access = private)
        function createComponents(app)
            sand = [0.97 0.96 0.93];
            ink = [0.17 0.20 0.17];

            app.UIFigure = uifigure( ...
                'Name', 'Operation IRON RELAY - Mission Dashboard', ...
                'Color', sand, ...
                'Position', [80 70 1500 900]);

            mainGrid = uigridlayout(app.UIFigure, [3 2]);
            mainGrid.RowHeight = {120, '1x', '1x'};
            mainGrid.ColumnWidth = {320, '1x'};
            mainGrid.Padding = [16 16 16 16];
            mainGrid.RowSpacing = 14;
            mainGrid.ColumnSpacing = 14;

            controlPanel = uipanel(mainGrid, ...
                'Title', 'Mission Control', ...
                'BackgroundColor', [0.94 0.92 0.86], ...
                'ForegroundColor', ink, ...
                'FontWeight', 'bold');
            controlPanel.Layout.Row = [1 3];
            controlPanel.Layout.Column = 1;

            controlGrid = uigridlayout(controlPanel, [11 1]);
            controlGrid.RowHeight = {30, 48, 24, 32, 36, 36, 36, 36, 24, '1x', 48};
            controlGrid.Padding = [12 12 12 12];
            controlGrid.RowSpacing = 8;

            titleLabel = uilabel(controlGrid, ...
                'Text', 'Operation IRON RELAY', ...
                'FontSize', 24, ...
                'FontWeight', 'bold', ...
                'FontName', 'Bahnschrift');
            titleLabel.FontColor = ink;

            uilabel(controlGrid, ...
                'Text', 'Contested logistics mission simulator dashboard', ...
                'WordWrap', 'on', ...
                'FontSize', 13, ...
                'FontColor', [0.28 0.31 0.24]);

            uilabel(controlGrid, ...
                'Text', 'Monte Carlo realizations', ...
                'FontWeight', 'bold', ...
                'FontColor', ink);

            app.RunsSpinner = uispinner(controlGrid, ...
                'Limits', [5 250], ...
                'Value', 30, ...
                'Step', 5, ...
                'RoundFractionalValues', 'on');

            app.SingleRunButton = uibutton(controlGrid, 'push', ...
                'Text', 'Run Single Mission', ...
                'ButtonPushedFcn', @(~, ~) app.runSingleMission());
            stylePrimaryButton(app.SingleRunButton, [0.24 0.39 0.26]);

            app.CampaignButton = uibutton(controlGrid, 'push', ...
                'Text', 'Run Monte Carlo', ...
                'ButtonPushedFcn', @(~, ~) app.runMonteCarlo());
            stylePrimaryButton(app.CampaignButton, [0.57 0.27 0.16]);

            openMissionButton = uibutton(controlGrid, 'push', ...
                'Text', 'Open Mission Model', ...
                'ButtonPushedFcn', @(~, ~) open_system('LogisticsMission'));
            styleSecondaryButton(openMissionButton);

            openArchitectureButton = uibutton(controlGrid, 'push', ...
                'Text', 'Open Architecture', ...
                'ButtonPushedFcn', @(~, ~) open_system('LogisticsArchitecture'));
            styleSecondaryButton(openArchitectureButton);

            uilabel(controlGrid, ...
                'Text', 'Scenario Snapshot', ...
                'FontWeight', 'bold', ...
                'FontColor', ink);

            app.ScenarioTextArea = uitextarea(controlGrid, ...
                'Editable', 'off', ...
                'BackgroundColor', [0.985 0.98 0.96], ...
                'FontName', 'Consolas', ...
                'Value', {'Loading scenario parameters...'});

            app.StatusLabel = uilabel(controlGrid, ...
                'Text', 'Ready. Run a mission or a campaign sweep.', ...
                'WordWrap', 'on', ...
                'FontColor', [0.31 0.33 0.28], ...
                'FontAngle', 'italic');

            summaryGrid = uigridlayout(mainGrid, [2 3]);
            summaryGrid.Layout.Row = 1;
            summaryGrid.Layout.Column = 2;
            summaryGrid.RowHeight = {'1x', '1x'};
            summaryGrid.ColumnWidth = {'1x', '1x', '1x'};
            summaryGrid.RowSpacing = 12;
            summaryGrid.ColumnSpacing = 12;
            summaryGrid.Padding = [0 0 0 0];

            cardTitles = {'Throughput', 'Delivered', 'Losses', ...
                'Dry Risk', 'Kills', 'Route Mix'};
            for idx = 1:numel(cardTitles)
                card = uipanel(summaryGrid, ...
                    'BackgroundColor', [0.99 0.985 0.97], ...
                    'ForegroundColor', [0.85 0.83 0.78], ...
                    'HighlightColor', [0.85 0.83 0.78], ...
                    'BorderType', 'line');
                cardGrid = uigridlayout(card, [3 1]);
                cardGrid.RowHeight = {24, '1x', 22};
                cardGrid.Padding = [12 10 12 10];
                cardGrid.RowSpacing = 2;

                app.MetricTitleLabels{idx} = uilabel(cardGrid, ...
                    'Text', upper(cardTitles{idx}), ...
                    'FontSize', 11, ...
                    'FontWeight', 'bold', ...
                    'FontColor', [0.42 0.42 0.37]);
                app.MetricValueLabels{idx} = uilabel(cardGrid, ...
                    'Text', '--', ...
                    'FontSize', 24, ...
                    'FontName', 'Bahnschrift', ...
                    'FontWeight', 'bold', ...
                    'FontColor', ink);
                app.MetricDetailLabels{idx} = uilabel(cardGrid, ...
                    'Text', '', ...
                    'FontSize', 11, ...
                    'FontColor', [0.34 0.36 0.30]);
            end

            vizGrid = uigridlayout(mainGrid, [2 2]);
            vizGrid.Layout.Row = [2 3];
            vizGrid.Layout.Column = 2;
            vizGrid.RowHeight = {'1x', '1x'};
            vizGrid.ColumnWidth = {'1x', '1x'};
            vizGrid.RowSpacing = 12;
            vizGrid.ColumnSpacing = 12;
            vizGrid.Padding = [0 0 0 0];

            app.TheaterAxes = uiaxes(vizGrid);
            app.TheaterAxes.Layout.Row = 1;
            app.TheaterAxes.Layout.Column = 1;

            app.StockAxes = uiaxes(vizGrid);
            app.StockAxes.Layout.Row = 1;
            app.StockAxes.Layout.Column = 2;

            app.OutcomeAxes = uiaxes(vizGrid);
            app.OutcomeAxes.Layout.Row = 2;
            app.OutcomeAxes.Layout.Column = 1;

            app.RouteAxes = uiaxes(vizGrid);
            app.RouteAxes.Layout.Row = 2;
            app.RouteAxes.Layout.Column = 2;

            formatAxes(app.TheaterAxes);
            formatAxes(app.StockAxes);
            formatAxes(app.OutcomeAxes);
            formatAxes(app.RouteAxes);
        end

        function loadScenarioSnapshot(app)
            evalin('base', 'scenarioParams');

            campaignDays = evalin('base', 'CAMPAIGN_HR / 24');
            dispatchPeriodHr = evalin('base', 'DISPATCH_PERIOD_HR');
            convoyTons = evalin('base', 'CONVOY_CARGO_TONS');
            transitNorthHr = evalin('base', 'TRANSIT_NORTH_HR');
            transitSouthHr = evalin('base', 'TRANSIT_SOUTH_HR');
            pAmbushNorth = evalin('base', 'P_AMBUSH_NORTH');
            pAmbushSouth = evalin('base', 'P_AMBUSH_SOUTH');
            stockInitial = evalin('base', 'FOB_STOCK_INITIAL_TONS');
            consumptionTpd = evalin('base', 'FOB_CONSUMPTION_TPD');

            app.ScenarioTextArea.Value = { ...
                sprintf('Campaign length   : %2.0f days', campaignDays), ...
                sprintf('Dispatch rhythm   : 1 convoy / %d h', dispatchPeriodHr), ...
                sprintf('Payload per convoy: %3.0f tons', convoyTons), ...
                sprintf('FOB stock / burn  : %3.0f t / %3.0f tpd', stockInitial, consumptionTpd), ...
                sprintf('North route       : %2.0f h, ambush %.0f%%', transitNorthHr, 100 * pAmbushNorth), ...
                sprintf('South route       : %2.0f h, ambush %.0f%%', transitSouthHr, 100 * pAmbushSouth)};
        end

        function renderEmptyState(app)
            app.updateMetricCards( ...
                {'--', '--', '--', '--', '--', '--'}, ...
                {'Run a simulation', '', '', '', '', ''});
            placeholder(app.TheaterAxes, 'Theater view will show route usage and threat posture.');
            placeholder(app.StockAxes, 'FOB stockpile timeline will appear here.');
            placeholder(app.OutcomeAxes, 'Outcome plots update after a run.');
            placeholder(app.RouteAxes, 'Routing behavior appears here.');
        end

        function runSingleMission(app)
            app.setBusyState(true, 'Running a single contested resupply mission...');
            cleanup = onCleanup(@() app.setControlsEnabled(true));

            try
                result = analyzeCampaign(1);
                singleRun = result.singleRun;
                routeTotal = max(singleRun.RouteNorthCount + singleRun.RouteSouthCount, 1);
                northPct = 100 * singleRun.RouteNorthCount / routeTotal;
                southPct = 100 * singleRun.RouteSouthCount / routeTotal;

                app.updateMetricCards( ...
                    {sprintf('%.1f%%', result.throughputPct(1)), ...
                    sprintf('%.0f t', result.delivered(1)), ...
                    sprintf('%.0f t', result.lost(1)), ...
                    sprintf('%d h', result.dryHours(1)), ...
                    sprintf('%.0f', result.kills(1)), ...
                    sprintf('%.0f%% / %.0f%%', northPct, southPct)}, ...
                    {'of dispatched tonnage', ...
                    sprintf('minimum stock %.0f t', result.minStock(1)), ...
                    'lost to red interdiction', ...
                    'time at or below zero stock', ...
                    'convoys catastrophically destroyed', ...
                    'north / south route share'});

                app.drawTheaterMap(northPct, southPct, routeTotal, 'Single mission route usage');
                app.drawSingleStockPlot(singleRun);
                app.drawSingleOutcomePlot(singleRun);
                app.drawSingleRoutePlot(singleRun);
                app.StatusLabel.Text = sprintf( ...
                    'Single mission complete: %.0f tons delivered, %.0f convoys lost, min FOB stock %.0f tons.', ...
                    result.delivered(1), result.kills(1), result.minStock(1));
            catch ME
                app.StatusLabel.Text = 'Single mission failed.';
                uialert(app.UIFigure, ME.message, 'Simulation Error');
            end

            clear cleanup
        end

        function runMonteCarlo(app)
            nRuns = round(app.RunsSpinner.Value);
            app.setBusyState(true, sprintf('Running %d Monte Carlo realizations...', nRuns));
            cleanup = onCleanup(@() app.setControlsEnabled(true));

            try
                results = analyzeCampaign(nRuns);
                meanNorth = mean(results.routeNorthSharePct);
                meanSouth = 100 - meanNorth;

                app.updateMetricCards( ...
                    {sprintf('%.1f%%', mean(results.throughputPct)), ...
                    sprintf('%.0f +/- %.0f t', mean(results.delivered), std(results.delivered)), ...
                    sprintf('%.0f t', mean(results.lost)), ...
                    sprintf('%.1f%%', 100 * mean(results.dryHours > 0)), ...
                    sprintf('%.2f', mean(results.kills)), ...
                    sprintf('%.0f%% / %.0f%%', meanNorth, meanSouth)}, ...
                    {sprintf('mean across %d runs', nRuns), ...
                    'campaign delivery mean +/- sd', ...
                    'mean attrition per campaign', ...
                    sprintf('mean minimum stock %.0f t', mean(results.minStock)), ...
                    'mean convoys destroyed', ...
                    'mean north / south route share'});

                app.drawTheaterMap(meanNorth, meanSouth, mean(results.routeNorthCount + results.routeSouthCount), ...
                    sprintf('%d-run mean route usage', nRuns));
                app.drawCampaignStockPlot(results);
                app.drawCampaignOutcomePlot(results);
                app.drawCampaignRoutePlot(results);
                app.StatusLabel.Text = sprintf( ...
                    '%d-run Monte Carlo complete: mean delivery %.0f tons, FOB dry in %.1f%% of runs.', ...
                    nRuns, mean(results.delivered), 100 * mean(results.dryHours > 0));
            catch ME
                app.StatusLabel.Text = 'Monte Carlo run failed.';
                uialert(app.UIFigure, ME.message, 'Simulation Error');
            end

            clear cleanup
        end

        function updateMetricCards(app, values, details)
            for idx = 1:numel(app.MetricValueLabels)
                app.MetricValueLabels{idx}.Text = values{idx};
                if idx <= numel(details)
                    app.MetricDetailLabels{idx}.Text = details{idx};
                else
                    app.MetricDetailLabels{idx}.Text = '';
                end
            end
        end

        function drawTheaterMap(app, northPct, southPct, convoyCount, subtitleText)
            ax = app.TheaterAxes;
            cla(ax);
            formatAxes(ax);
            hold(ax, 'on');
            ax.Visible = 'on';
            axis(ax, 'equal');
            axis(ax, [-0.5 10.5 -0.5 7.5]);
            ax.XTick = [];
            ax.YTick = [];
            ax.XColor = 'none';
            ax.YColor = 'none';
            title(ax, 'Operational Theater', 'FontWeight', 'bold');

            patch(ax, [0 10.5 10.5 0], [-0.5 -0.5 7.5 7.5], [0.94 0.91 0.82], ...
                'EdgeColor', 'none');
            patch(ax, [0.5 2.5 3.8 2.0], [6.8 7.2 5.9 5.6], [0.84 0.80 0.67], ...
                'EdgeColor', 'none', 'FaceAlpha', 0.8);
            patch(ax, [6.0 7.8 9.5 8.1], [1.1 2.5 1.3 0.2], [0.85 0.82 0.70], ...
                'EdgeColor', 'none', 'FaceAlpha', 0.8);

            lsa = [1.0 3.5];
            north = [3.4 5.9; 6.6 6.1];
            south = [3.4 1.1; 6.7 1.4];
            fob = [9.2 3.5];

            plot(ax, [lsa(1) north(:, 1)' fob(1)], [lsa(2) north(:, 2)' fob(2)], ...
                '-', 'Color', [0.63 0.23 0.18], 'LineWidth', 2 + northPct / 14);
            plot(ax, [lsa(1) south(:, 1)' fob(1)], [lsa(2) south(:, 2)' fob(2)], ...
                '-', 'Color', [0.26 0.44 0.28], 'LineWidth', 2 + southPct / 14);
            plot(ax, [lsa(1) fob(1)], [lsa(2) fob(2)], '--', 'Color', [0.55 0.55 0.52], ...
                'LineWidth', 0.75);

            scatter(ax, lsa(1), lsa(2), 170, [0.15 0.24 0.19], 'filled', 'Marker', 's');
            scatter(ax, fob(1), fob(2), 170, [0.12 0.32 0.52], 'filled', 'Marker', '^');

            text(ax, lsa(1) - 0.2, lsa(2) - 0.55, 'LSA', ...
                'FontWeight', 'bold', 'FontSize', 12, 'Color', [0.15 0.24 0.19]);
            text(ax, fob(1) - 0.1, fob(2) - 0.55, 'FOB', ...
                'FontWeight', 'bold', 'FontSize', 12, 'Color', [0.12 0.32 0.52]);

            text(ax, 4.7, 6.75, sprintf('ROUTE NORTH  %.0f%%', northPct), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', ...
                'Color', [0.45 0.12 0.10], ...
                'BackgroundColor', [0.98 0.94 0.92], ...
                'Margin', 4);
            text(ax, 4.8, 0.25, sprintf('ROUTE SOUTH  %.0f%%', southPct), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', ...
                'Color', [0.18 0.33 0.19], ...
                'BackgroundColor', [0.95 0.98 0.94], ...
                'Margin', 4);
            text(ax, 8.2, 6.65, 'HIGH THREAT', ...
                'FontWeight', 'bold', ...
                'Color', [0.55 0.15 0.12], ...
                'BackgroundColor', [0.99 0.94 0.92], ...
                'Margin', 4);
            text(ax, 8.1, 0.35, 'LOWER THREAT', ...
                'FontWeight', 'bold', ...
                'Color', [0.19 0.36 0.19], ...
                'BackgroundColor', [0.95 0.98 0.94], ...
                'Margin', 4);
            text(ax, 0.3, 7.0, subtitleText, ...
                'FontSize', 12, 'Color', [0.25 0.27 0.22], 'FontAngle', 'italic');
            text(ax, 0.3, 6.45, sprintf('Observed convoy decisions: %.0f', convoyCount), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.18 0.20 0.18]);
            hold(ax, 'off');
        end

        function drawSingleStockPlot(app, singleRun)
            ax = app.StockAxes;
            cla(ax);
            formatAxes(ax);
            ax.Visible = 'on';
            plot(ax, singleRun.TimeDays, singleRun.StockTons, 'Color', [0.12 0.32 0.52], 'LineWidth', 2.4);
            yline(ax, 0, '--', 'FOB dry', 'Color', [0.66 0.21 0.13], 'LineWidth', 1.1);
            grid(ax, 'on');
            ax.GridAlpha = 0.12;
            ax.Color = [0.99 0.985 0.97];
            title(ax, 'FOB Stockpile', 'FontWeight', 'bold');
            xlabel(ax, 'Campaign day');
            ylabel(ax, 'Stockpile (tons)');
        end

        function drawSingleOutcomePlot(app, singleRun)
            ax = app.OutcomeAxes;
            cla(ax);
            formatAxes(ax);
            ax.Visible = 'on';
            hold(ax, 'on');
            area(ax, singleRun.TimeDays, singleRun.DeliveredSeriesTons, ...
                'FaceColor', [0.74 0.83 0.90], 'EdgeColor', [0.12 0.32 0.52], 'LineWidth', 1.2);
            plot(ax, singleRun.TimeDays, singleRun.LostSeriesTons, ...
                'Color', [0.66 0.21 0.13], 'LineWidth', 2);
            grid(ax, 'on');
            ax.GridAlpha = 0.12;
            ax.Color = [0.99 0.985 0.97];
            xlabel(ax, 'Campaign day');
            ylabel(ax, 'Cumulative tons');
            title(ax, 'Delivered vs Lost Tonnage', 'FontWeight', 'bold');
            legend(ax, {'Delivered', 'Lost'}, 'Location', 'northwest');
            hold(ax, 'off');
        end

        function drawSingleRoutePlot(app, singleRun)
            ax = app.RouteAxes;
            cla(ax);
            formatAxes(ax);
            ax.Visible = 'on';
            stairs(ax, singleRun.RouteTimeDays, singleRun.RouteSelected, ...
                'Color', [0.31 0.36 0.19], 'LineWidth', 2);
            grid(ax, 'on');
            ax.GridAlpha = 0.12;
            ax.Color = [0.99 0.985 0.97];
            ax.YLim = [0.75 2.25];
            ax.YTick = [1 2];
            ax.YTickLabel = {'North', 'South'};
            xlabel(ax, 'Campaign day');
            ylabel(ax, 'Selected route');
            title(ax, 'Adaptive Routing Timeline', 'FontWeight', 'bold');
        end

        function drawCampaignStockPlot(app, results)
            ax = app.StockAxes;
            cla(ax);
            formatAxes(ax);
            ax.Visible = 'on';
            hold(ax, 'on');
            stockP10 = prctile(results.stockGrid, 10, 1);
            stockP90 = prctile(results.stockGrid, 90, 1);
            fill(ax, ...
                [results.tGrid; flipud(results.tGrid)] / 24, ...
                [stockP10'; flipud(stockP90')], ...
                [0.84 0.88 0.92], ...
                'EdgeColor', 'none', ...
                'FaceAlpha', 0.9);
            plot(ax, results.tGrid / 24, results.stockGrid', 'Color', [0.82 0.82 0.81], 'LineWidth', 0.6);
            plot(ax, results.tGrid / 24, median(results.stockGrid, 1), ...
                'Color', [0.12 0.32 0.52], 'LineWidth', 2.4);
            yline(ax, 0, '--', 'FOB dry', 'Color', [0.66 0.21 0.13], 'LineWidth', 1.1);
            grid(ax, 'on');
            ax.GridAlpha = 0.12;
            ax.Color = [0.99 0.985 0.97];
            xlabel(ax, 'Campaign day');
            ylabel(ax, 'Stockpile (tons)');
            title(ax, 'FOB Stockpile Envelope', 'FontWeight', 'bold');
            hold(ax, 'off');
        end

        function drawCampaignOutcomePlot(app, results)
            ax = app.OutcomeAxes;
            cla(ax);
            formatAxes(ax);
            ax.Visible = 'on';
            hold(ax, 'on');
            dryMask = results.dryHours > 0;
            scatter(ax, results.delivered(~dryMask), results.lost(~dryMask), 42, ...
                [0.89 0.85 0.73], 'filled', 'MarkerEdgeColor', [0.12 0.32 0.52], 'LineWidth', 0.8);
            scatter(ax, results.delivered(dryMask), results.lost(dryMask), 52, ...
                [0.72 0.27 0.20], 'filled', 'MarkerEdgeColor', [0.38 0.11 0.08], 'LineWidth', 0.8);
            grid(ax, 'on');
            ax.GridAlpha = 0.12;
            ax.Color = [0.99 0.985 0.97];
            xlabel(ax, 'Delivered tons');
            ylabel(ax, 'Lost tons');
            title(ax, 'Campaign Outcome Cloud', 'FontWeight', 'bold');
            legend(ax, {'Sustained FOB', 'FOB went dry'}, 'Location', 'northwest');
            hold(ax, 'off');
        end

        function drawCampaignRoutePlot(app, results)
            ax = app.RouteAxes;
            cla(ax);
            formatAxes(ax);
            ax.Visible = 'on';
            histogram(ax, results.routeNorthSharePct, ...
                'FaceColor', [0.31 0.36 0.19], 'EdgeColor', 'w', 'LineWidth', 1);
            xline(ax, mean(results.routeNorthSharePct), '--', 'Mean north share', ...
                'Color', [0.12 0.32 0.52], 'LineWidth', 1.1);
            grid(ax, 'on');
            ax.GridAlpha = 0.12;
            ax.Color = [0.99 0.985 0.97];
            xlabel(ax, 'Convoys routed north (%)');
            ylabel(ax, 'Realizations');
            title(ax, 'Adaptive Route Mix', 'FontWeight', 'bold');
        end

        function setBusyState(app, isBusy, message)
            if isBusy
                app.setControlsEnabled(false);
            else
                app.setControlsEnabled(true);
            end
            app.StatusLabel.Text = message;
            drawnow;
        end

        function setControlsEnabled(app, isEnabled)
            if isEnabled
                app.SingleRunButton.Enable = 'on';
                app.CampaignButton.Enable = 'on';
            else
                app.SingleRunButton.Enable = 'off';
                app.CampaignButton.Enable = 'off';
            end
        end
    end
end

function stylePrimaryButton(button, colorValue)
button.BackgroundColor = colorValue;
button.FontColor = [1 1 1];
button.FontWeight = 'bold';
end

function styleSecondaryButton(button)
button.BackgroundColor = [0.99 0.985 0.97];
button.FontColor = [0.21 0.23 0.20];
button.FontWeight = 'bold';
end

function formatAxes(ax)
ax.Box = 'on';
ax.LineWidth = 1;
ax.XColor = [0.28 0.30 0.28];
ax.YColor = [0.28 0.30 0.28];
ax.FontName = 'Aptos';
ax.Toolbar.Visible = 'off';
end

function placeholder(ax, message)
cla(ax);
ax.Visible = 'on';
ax.XTick = [];
ax.YTick = [];
ax.XColor = 'none';
ax.YColor = 'none';
text(ax, 0.5, 0.5, message, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 13, ...
    'Color', [0.35 0.37 0.33]);
end
