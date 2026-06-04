"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlantEntity = void 0;
class PlantEntity {
    id;
    name;
    location;
    peakCapacity;
    status;
    ownerId;
    createdAt;
    updatedAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.PlantEntity = PlantEntity;
//# sourceMappingURL=plant.entity.js.map