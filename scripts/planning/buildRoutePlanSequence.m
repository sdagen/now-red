function routeSequence = buildRoutePlanSequence(routeSequence, options)
%BUILDROUTEPLANSEQUENCE Validate and clamp convoy route decisions.

arguments
    routeSequence (:,1) double
    options.ExpectedConvoys double = NaN
end

routeSequence = round(routeSequence(:));
routeSequence(routeSequence < 1) = 1;
routeSequence(routeSequence > 2) = 2;

if ~isnan(options.ExpectedConvoys) && numel(routeSequence) ~= options.ExpectedConvoys
    error('Route plan must contain %d convoy decisions, found %d.', ...
        options.ExpectedConvoys, numel(routeSequence));
end
end
