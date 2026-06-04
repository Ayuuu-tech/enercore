"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PanelEntity = void 0;
class PanelEntity {
    id;
    row;
    column;
    status;
    voltage;
    current;
    temperature;
    generation;
    lastSync;
    plantId;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.PanelEntity = PanelEntity;
//# sourceMappingURL=panel.entity.js.map