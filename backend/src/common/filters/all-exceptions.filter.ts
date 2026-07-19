import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

/**
 * The last line of defence for anything not caught by a more specific filter.
 *
 * Two jobs: (1) surface server errors in the logs with enough context to debug
 * them — method, path, and the full stack — so a production crash is visible in
 * the Azure log stream instead of silent; (2) never leak an internal stack or
 * message to the client on a 500. Known HttpExceptions keep their status and
 * message; everything else becomes a generic 500.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exception');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const isHttp = exception instanceof HttpException;
    const status = isHttp
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    // For handled HTTP errors, pass the framework's own response body through.
    if (isHttp) {
      const body = exception.getResponse();
      if (status >= 500) {
        this.logger.error(
          `${request.method} ${request.url} -> ${status}`,
          exception.stack,
        );
      }
      response.status(status).json(
        typeof body === 'string'
          ? { statusCode: status, message: body }
          : body,
      );
      return;
    }

    // Anything else is an unexpected server error: log it in full, hide it.
    this.logger.error(
      `Unhandled ${request.method} ${request.url}`,
      exception instanceof Error ? exception.stack : String(exception),
    );
    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      message: 'Internal server error',
    });
  }
}
