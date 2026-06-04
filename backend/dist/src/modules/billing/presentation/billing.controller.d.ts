import { BillingService } from '../application/billing.service';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { UserEntity } from '../../users/domain/user.entity';
export declare class BillingController {
    private readonly billingService;
    constructor(billingService: BillingService);
    findAll(user: UserEntity): Promise<import("../domain/invoice.entity").InvoiceEntity[]>;
    findOne(id: string, user: UserEntity): Promise<import("../domain/invoice.entity").InvoiceEntity>;
    create(dto: CreateInvoiceDto): Promise<import("../domain/invoice.entity").InvoiceEntity>;
    pay(id: string, user: UserEntity): Promise<import("../domain/invoice.entity").InvoiceEntity>;
}
