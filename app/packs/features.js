const features = () => window.flightPlanConfig.features || {};

export const isFeatureEnabled = name => !!features()[name];
export const isFeatureDisabled = name => !isFeatureEnabled(name);
