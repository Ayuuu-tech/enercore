import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private transporter: nodemailer.Transporter | null = null;

  constructor() {
    const host = process.env.SMTP_HOST;
    const port = process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10) : 587;
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      console.log('Nodemailer SMTP transporter initialized.');
    } else {
      console.log('SMTP credentials not provided. MailService will run in mock/console mode.');
    }
  }

  async sendMail(to: string, subject: string, text: string, html?: string): Promise<boolean> {
    const from = process.env.SMTP_FROM || '"Enercore Notifications" <noreply@enercore.com>';

    if (this.transporter) {
      try {
        await this.transporter.sendMail({
          from,
          to,
          subject,
          text,
          html: html || text,
        });
        console.log(`Email successfully sent to ${to}`);
        return true;
      } catch (error) {
        console.error('Failed to send email:', error);
        return false;
      }
    } else {
      console.log(`[MOCK EMAIL] To: ${to} | Subject: ${subject} | Body: ${text}`);
      return true;
    }
  }
}
