"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TelemetryEntity = void 0;
class TelemetryEntity {
    id;
    voltage;
    current;
    temperature;
    generation;
    timestamp;
    panelId;
    plantId;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.TelemetryEntity = TelemetryEntity;
//# sourceMappingURL=telemetry.entity.js.map