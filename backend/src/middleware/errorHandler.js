import multer from 'multer';
import { ZodError } from 'zod';

export function notFoundHandler(request, response) {
  response.status(404).json({
    success: false,
    message: `Endpoint ${request.method} ${request.originalUrl} was not found.`,
  });
}

export function errorHandler(error, request, response, next) {
  console.error(error);

  if (error instanceof ZodError) {
    return response.status(400).json({
      success: false,
      message: 'The submitted information is invalid.',
      errors: error.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message,
      })),
    });
  }

  if (error instanceof multer.MulterError) {
    return response.status(400).json({
      success: false,
      message:
        error.code === 'LIMIT_FILE_SIZE'
          ? 'The selected image is too large.'
          : error.message,
    });
  }

  if (error.code === 'ER_DUP_ENTRY') {
    return response.status(409).json({
      success: false,
      message: 'This information already exists.',
    });
  }

  response.status(error.status ?? 500).json({
    success: false,
    message:
      error.status || process.env.NODE_ENV !== 'production'
        ? error.message
        : 'An unexpected server error occurred.',
    details: error.details ?? undefined,
  });
}