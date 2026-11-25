package com.oplus.content;

/** Keeps ColorOS-specific UI and hardware extensions off on other ROMs. */
public final class OplusFeatureConfigManager {
    private static final OplusFeatureConfigManager INSTANCE = new OplusFeatureConfigManager();

    private OplusFeatureConfigManager() {}

    public static OplusFeatureConfigManager getInstance() {
        return INSTANCE;
    }

    public boolean hasFeature(String name) {
        return false;
    }
}
