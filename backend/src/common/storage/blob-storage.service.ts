import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  BlobSASPermissions,
  BlobServiceClient,
  ContainerClient,
  StorageSharedKeyCredential,
  generateBlobSASQueryParameters,
} from '@azure/storage-blob';

/**
 * Private object storage for vendor KYC documents (PAN, cancelled cheque,
 * MOA/AOA…).
 *
 * These are not avatars: a cancelled cheque carries a bank account number, and
 * a PAN card is government ID. So the container has public access disabled, and
 * nothing here ever returns a durable public URL — a download is a short-lived
 * signed link, minted per request for a caller we've already authorised.
 *
 * The App Service filesystem is not an option: a redeploy wipes it, and losing
 * a vendor's statutory documents is not a recoverable mistake.
 */
@Injectable()
export class BlobStorageService {
  private readonly logger = new Logger(BlobStorageService.name);
  private container?: ContainerClient;
  private credential?: StorageSharedKeyCredential;
  private accountName = '';

  constructor(private readonly config: ConfigService) {}

  private get connectionString(): string | undefined {
    return this.config.get<string>('AZURE_STORAGE_CONNECTION_STRING');
  }

  get isConfigured(): boolean {
    return !!this.connectionString;
  }

  private client(): ContainerClient {
    if (this.container) return this.container;

    const cs = this.connectionString;
    if (!cs) {
      throw new ServiceUnavailableException(
        'Document storage is not configured (AZURE_STORAGE_CONNECTION_STRING)',
      );
    }
    const service = BlobServiceClient.fromConnectionString(cs);
    const containerName =
      this.config.get<string>('AZURE_STORAGE_CONTAINER') ?? 'vendor-docs';
    this.container = service.getContainerClient(containerName);

    // Kept for signing download links.
    const account = /AccountName=([^;]+)/.exec(cs)?.[1] ?? '';
    const key = /AccountKey=([^;]+)/.exec(cs)?.[1] ?? '';
    this.accountName = account;
    this.credential = new StorageSharedKeyCredential(account, key);

    return this.container;
  }

  async upload(
    key: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<void> {
    const blob = this.client().getBlockBlobClient(key);
    await blob.uploadData(buffer, {
      blobHTTPHeaders: { blobContentType: mimeType },
    });
    this.logger.log(`Stored ${key} (${buffer.length} bytes)`);
  }

  /**
   * A read-only link that expires. Callers must already have been authorised —
   * this only limits how long the link they were given stays usable.
   */
  async signedUrl(key: string, ttlMinutes = 10): Promise<string> {
    const container = this.client();
    const sas = generateBlobSASQueryParameters(
      {
        containerName: container.containerName,
        blobName: key,
        permissions: BlobSASPermissions.parse('r'),
        startsOn: new Date(Date.now() - 60 * 1000), // clock skew
        expiresOn: new Date(Date.now() + ttlMinutes * 60 * 1000),
      },
      this.credential!,
    ).toString();

    return `https://${this.accountName}.blob.core.windows.net/${container.containerName}/${key}?${sas}`;
  }

  async delete(key: string): Promise<void> {
    await this.client().getBlockBlobClient(key).deleteIfExists();
  }
}
