import { Body, Controller, Delete, Get, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { AdminService } from '../application/admin.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { AuditService } from '../../../common/audit/audit.service';
import { PaymentStatus, Role, SubscriptionPlan, SubscriptionStatus } from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly audit: AuditService,
  ) {}

  @Get('stats')
  async getStats() {
    return this.adminService.getSystemStats();
  }

  @Get('vendors/pending')
  async getPendingVendors() {
    return this.adminService.getUnverifiedVendors();
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  @Get('users')
  async listUsers() {
    return this.adminService.listUsers();
  }

  @Post('users')
  async createUser(
    @CurrentUser() admin: UserEntity,
    @Body() body: { email: string; password: string; name: string; role?: Role; phone?: string },
  ) {
    const res = await this.adminService.createUser(body);
    await this.audit.log(admin, 'CREATE_USER', { targetType: 'User', targetId: res.id, detail: `${res.email} (${res.role})` });
    return res;
  }

  @Put('users/:id/active')
  async setActive(@CurrentUser() admin: UserEntity, @Param('id') id: string, @Body() body: { isActive: boolean }) {
    const res = await this.adminService.setUserActive(id, body.isActive);
    await this.audit.log(admin, body.isActive ? 'ENABLE_USER' : 'DISABLE_USER', { targetType: 'User', targetId: id });
    return res;
  }

  @Put('users/:id/role')
  async setRole(@CurrentUser() admin: UserEntity, @Param('id') id: string, @Body() body: { role: Role }) {
    const res = await this.adminService.updateUserRole(id, body.role);
    await this.audit.log(admin, 'SET_ROLE', { targetType: 'User', targetId: id, detail: body.role });
    return res;
  }

  @Get('users/:id/modules')
  async getModules(@Param('id') id: string) {
    return { modules: await this.adminService.getUserModules(id) };
  }

  @Put('users/:id/modules')
  async setModules(@CurrentUser() admin: UserEntity, @Param('id') id: string, @Body() body: { modules: string[] }) {
    const res = await this.adminService.setUserModules(id, body.modules ?? []);
    await this.audit.log(admin, 'SET_MODULES', { targetType: 'User', targetId: id, detail: (body.modules ?? []).join(',') || 'all' });
    return res;
  }

  // ── Plant assignment ───────────────────────────────────────────────────────

  @Get('users/:id/plants')
  async getUserPlants(@Param('id') id: string) {
    return this.adminService.getUserPlants(id);
  }

  @Put('users/:id/plants')
  async setUserPlants(@CurrentUser() admin: UserEntity, @Param('id') id: string, @Body() body: { plantIds: string[] }) {
    const res = await this.adminService.setUserPlants(id, body.plantIds ?? []);
    await this.audit.log(admin, 'SET_PLANT_ACCESS', { targetType: 'User', targetId: id, detail: `${(body.plantIds ?? []).length} plants` });
    return res;
  }

  @Post('users/:id/plants/:plantId')
  async assignPlant(@Param('id') id: string, @Param('plantId') plantId: string) {
    return this.adminService.assignPlant(id, plantId);
  }

  @Delete('users/:id/plants/:plantId')
  async revokePlant(@Param('id') id: string, @Param('plantId') plantId: string) {
    return this.adminService.revokePlant(id, plantId);
  }

  @Get('plants/:plantId/users')
  async getPlantUsers(@Param('plantId') plantId: string) {
    return this.adminService.getPlantUsers(plantId);
  }

  @Get('plants')
  async listPlants() {
    return this.adminService.listPlantsWithAccess();
  }

  @Put('plants/:plantId/owner')
  async transferOwnership(@CurrentUser() admin: UserEntity, @Param('plantId') plantId: string, @Body() body: { ownerId: string }) {
    const res = await this.adminService.transferOwnership(plantId, body.ownerId);
    await this.audit.log(admin, 'TRANSFER_PLANT', { targetType: 'Plant', targetId: plantId, detail: `to ${body.ownerId}` });
    return res;
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  @Get('analytics')
  async getAnalytics() {
    return this.adminService.getUserAnalytics();
  }

  // ── Audit log ────────────────────────────────────────────────────────────────

  @Get('audit-logs')
  async getAuditLogs(@Query('limit') limit?: string) {
    return this.audit.list(limit ? parseInt(limit, 10) : 100);
  }

  // ── Subscriptions ────────────────────────────────────────────────────────────

  @Get('subscriptions')
  async listSubscriptions() {
    return this.adminService.listSubscriptions();
  }

  @Post('subscriptions')
  async createSubscription(
    @CurrentUser() admin: UserEntity,
    @Body() body: { userId: string; plan: SubscriptionPlan; amount: number; startDate?: string; activate?: boolean },
  ) {
    const res = await this.adminService.createSubscription(body);
    await this.audit.log(admin, 'CREATE_SUBSCRIPTION', { targetType: 'Subscription', targetId: res.id, detail: `${body.plan} ₹${body.amount}` });
    return res;
  }

  @Put('subscriptions/:id/status')
  async setSubscriptionStatus(@CurrentUser() admin: UserEntity, @Param('id') id: string, @Body() body: { status: SubscriptionStatus }) {
    const res = await this.adminService.setSubscriptionStatus(id, body.status);
    await this.audit.log(admin, 'SET_SUBSCRIPTION_STATUS', { targetType: 'Subscription', targetId: id, detail: body.status });
    return res;
  }

  @Post('subscriptions/:id/renew')
  async renewSubscription(@CurrentUser() admin: UserEntity, @Param('id') id: string) {
    const res = await this.adminService.renewSubscription(id);
    await this.audit.log(admin, 'RENEW_SUBSCRIPTION', { targetType: 'Subscription', targetId: id });
    return res;
  }

  // ── Payments ─────────────────────────────────────────────────────────────────

  @Get('payments')
  async listPayments() {
    return this.adminService.listPayments();
  }

  @Post('payments')
  async recordPayment(
    @CurrentUser() admin: UserEntity,
    @Body()
    body: {
      userId: string;
      amount: number;
      status?: PaymentStatus;
      method?: string;
      reference?: string;
      subscriptionId?: string;
    },
  ) {
    const res = await this.adminService.recordPayment(body);
    await this.audit.log(admin, 'RECORD_PAYMENT', { targetType: 'Payment', targetId: res.id, detail: `₹${body.amount} ${body.status ?? 'SUCCESS'}` });
    return res;
  }

  @Put('payments/:id/status')
  async updatePaymentStatus(@CurrentUser() admin: UserEntity, @Param('id') id: string, @Body() body: { status: PaymentStatus }) {
    const res = await this.adminService.updatePaymentStatus(id, body.status);
    await this.audit.log(admin, 'SET_PAYMENT_STATUS', { targetType: 'Payment', targetId: id, detail: body.status });
    return res;
  }
}
